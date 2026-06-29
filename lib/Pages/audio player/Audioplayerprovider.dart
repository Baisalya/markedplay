import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path/path.dart' as path_utils;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/playback_position_store.dart';
import 'AudioHandler.dart';

class AudioPlayerProvider with ChangeNotifier {
  final MyAudioHandler _audioHandler;
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final PlaybackPositionStore _positionStore = const PlaybackPositionStore();
  final Random _random = Random();

  late final StreamSubscription<PlaybackState> _playbackStateSubscription;
  late final StreamSubscription<Duration> _positionSubscription;
  late final StreamSubscription<MediaItem?> _mediaItemSubscription;

  bool isPlaying = false;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;
  List<Duration> marks = [];
  String loopMode = 'No Loop';
  String? currentFilePath;
  int? currentSongId;
  Uint8List? currentArtworkBytes;
  String? playbackError;
  bool shuffleEnabled = false;
  bool autoPlayNext = true;
  double playbackSpeed = 1.0;

  List<SongModel> _playlist = [];
  int _currentIndex = -1;
  DateTime? _sleepTimerEndTime;
  Timer? _sleepTimer;
  AudioProcessingState _processingState = AudioProcessingState.idle;
  bool _handlingCompletion = false;
  int _lastPersistedSecond = -1;

  DateTime? get sleepTimerEndTime => _sleepTimerEndTime;
  List<SongModel> getPlaylist() => List.unmodifiable(_playlist);
  MediaItem? get currentMediaItem => _audioHandler.mediaItem.value;
  String get currentTitle =>
      currentMediaItem?.title ??
      (currentFilePath == null
          ? 'Nothing playing'
          : path_utils.basenameWithoutExtension(currentFilePath!));
  String get currentArtist => currentMediaItem?.artist ?? 'Unknown artist';

  AudioPlayerProvider(this._audioHandler) {
    _audioHandler.configureControls(
      onSkipToNext: playNext,
      onSkipToPrevious: playPrevious,
    );

    _playbackStateSubscription = _audioHandler.playbackState.listen((state) {
      final isAudio = _isAudioSource;
      isPlaying = state.playing && isAudio;
      _processingState = state.processingState;

      if (state.processingState == AudioProcessingState.completed &&
          isAudio &&
          !_handlingCompletion) {
        _handlingCompletion = true;
        unawaited(
          _handleSongCompletion().whenComplete(() {
            _handlingCompletion = false;
          }),
        );
      }
      notifyListeners();
    });

    _positionSubscription =
        _audioHandler.player.positionStream.listen((position) {
      if (!_isAudioSource) return;
      currentPosition = position;
      final seconds = position.inSeconds;
      if (currentFilePath != null &&
          seconds > 0 &&
          seconds % 5 == 0 &&
          seconds != _lastPersistedSecond) {
        _lastPersistedSecond = seconds;
        unawaited(_saveCurrentPosition());
      }
      notifyListeners();
    });

    _mediaItemSubscription = _audioHandler.mediaItem.listen((item) {
      if (item != null && item.extras?['type'] != 'video') {
        totalDuration =
            item.duration ?? _audioHandler.player.duration ?? Duration.zero;
        notifyListeners();
      }
    });
  }

  bool get _isAudioSource =>
      _audioHandler.mediaItem.value?.extras?['type'] != 'video';

  void clearPlaybackError() {
    if (playbackError == null) return;
    playbackError = null;
    notifyListeners();
  }

  void setSleepTimer(Duration? duration) {
    _sleepTimer?.cancel();
    if (duration == null) {
      _sleepTimerEndTime = null;
    } else {
      _sleepTimerEndTime = DateTime.now().add(duration);
      _sleepTimer = Timer(duration, () {
        unawaited(pauseAudio());
        _sleepTimerEndTime = null;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  void updatePlaylist(List<SongModel> songs) {
    _playlist = List.of(songs);
    _currentIndex = currentFilePath == null
        ? -1
        : _playlist.indexWhere((song) => song.data == currentFilePath);
    notifyListeners();
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _playlist.length) return;
    if (newIndex > oldIndex) newIndex--;
    if (newIndex < 0 || newIndex >= _playlist.length) return;
    final song = _playlist.removeAt(oldIndex);
    _playlist.insert(newIndex, song);
    _currentIndex = currentFilePath == null
        ? -1
        : _playlist.indexWhere((item) => item.data == currentFilePath);
    notifyListeners();
  }

  void removeFromQueue(int index) {
    if (index < 0 || index >= _playlist.length) return;
    _playlist.removeAt(index);
    _currentIndex = currentFilePath == null
        ? -1
        : _playlist.indexWhere((item) => item.data == currentFilePath);
    notifyListeners();
  }

  Future<void> configurePlayback({
    required String repeatMode,
    required bool shuffle,
    required bool shouldAutoPlayNext,
    required double speed,
    required int seekStepSeconds,
  }) async {
    loopMode = repeatMode;
    shuffleEnabled = shuffle;
    autoPlayNext = shouldAutoPlayNext;
    playbackSpeed = speed;
    _audioHandler.configureControls(
      onSkipToNext: playNext,
      onSkipToPrevious: playPrevious,
      seekStep: Duration(seconds: seekStepSeconds),
    );
    if (_isAudioSource) {
      await _audioHandler.setSpeed(speed);
    }
    notifyListeners();
  }

  Future<void> _handleSongCompletion() async {
    if (currentFilePath != null) {
      await _positionStore.clear(
        currentFilePath!,
        PlaybackMediaType.audio,
      );
    }

    if (loopMode == 'Loop One') {
      await seekAudio(Duration.zero);
      await _audioHandler.play();
      return;
    }
    if (loopMode == 'Loop All') {
      await playNext(wrap: true);
      return;
    }
    if (autoPlayNext && _currentIndex < _playlist.length - 1) {
      await playNext(wrap: false);
      return;
    }
    await _audioHandler.pause();
  }

  Future<void> playNext({bool wrap = true}) async {
    if (_playlist.isEmpty || !_isAudioSource) return;
    if (shuffleEnabled && _playlist.length > 1) {
      var nextIndex = _currentIndex;
      while (nextIndex == _currentIndex) {
        nextIndex = _random.nextInt(_playlist.length);
      }
      _currentIndex = nextIndex;
    } else if (_currentIndex < _playlist.length - 1) {
      _currentIndex++;
    } else if (wrap) {
      _currentIndex = 0;
    } else {
      return;
    }
    await playAudio(_playlist[_currentIndex].data);
  }

  Future<void> playPrevious() async {
    if (_playlist.isEmpty || !_isAudioSource) return;
    if (_currentIndex > 0) {
      _currentIndex--;
    } else {
      _currentIndex = _playlist.length - 1;
    }
    await playAudio(_playlist[_currentIndex].data);
  }

  Future<bool> playAudio(
    String filePath, {
    Duration startPosition = Duration.zero,
    bool resumeFromSavedPosition = false,
  }) async {
    playbackError = null;
    final isCurrentAudio = _isAudioSource && currentFilePath == filePath;
    if (isCurrentAudio) {
      if (!isPlaying) {
        if (_processingState == AudioProcessingState.completed) {
          await _audioHandler.seek(Duration.zero);
        }
        await _audioHandler.play();
      }
      notifyListeners();
      return true;
    }

    if (!await File(filePath).exists()) {
      playbackError = 'This audio file has moved or is no longer available.';
      notifyListeners();
      return false;
    }

    await _saveCurrentPosition();

    var title = path_utils.basenameWithoutExtension(filePath);
    var artist = 'Unknown artist';
    Duration? duration;
    int? songId;
    Uint8List? artworkBytes;
    String? artworkUri;

    try {
      final songs =
          _playlist.isNotEmpty ? _playlist : await _audioQuery.querySongs();
      SongModel? song;
      for (final candidate in songs) {
        if (candidate.data == filePath) {
          song = candidate;
          break;
        }
      }
      if (song != null) {
        songId = song.id;
        title = song.title;
        artist = song.artist ?? 'Unknown artist';
        duration = Duration(milliseconds: song.duration ?? 0);
        artworkBytes = await _audioQuery.queryArtwork(
          song.id,
          ArtworkType.AUDIO,
          format: ArtworkFormat.JPEG,
          size: 800,
        );
        if (artworkBytes != null) {
          final tempDirectory = await getTemporaryDirectory();
          final artworkFile =
              File('${tempDirectory.path}/markedplay_art_${song.id}.jpg');
          await artworkFile.writeAsBytes(artworkBytes);
          artworkUri = artworkFile.uri.toString();
        }
      }
    } catch (_) {
      // Playback remains available when metadata or artwork cannot be read.
    }

    final item = MediaItem(
      id: filePath,
      album: 'MarkedPlay',
      title: title,
      artist: artist,
      duration: duration,
      artUri: artworkUri == null ? null : Uri.parse(artworkUri),
      extras: const {'type': 'audio'},
    );

    try {
      await _audioHandler.setAudioSource(filePath, item);
      await _audioHandler.setSpeed(playbackSpeed);

      var requestedPosition = startPosition;
      if (resumeFromSavedPosition && requestedPosition == Duration.zero) {
        requestedPosition = await _positionStore.load(
              filePath,
              PlaybackMediaType.audio,
            ) ??
            Duration.zero;
      }
      final sourceDuration = _audioHandler.player.duration ?? duration;
      if (sourceDuration != null && requestedPosition >= sourceDuration) {
        requestedPosition = Duration.zero;
      }
      if (requestedPosition > Duration.zero) {
        await _audioHandler.seek(requestedPosition);
      }

      currentFilePath = filePath;
      currentPosition = requestedPosition;
      totalDuration = sourceDuration ?? Duration.zero;
      currentSongId = songId;
      currentArtworkBytes = artworkBytes;
      _currentIndex = _playlist.indexWhere((song) => song.data == filePath);
      _lastPersistedSecond = -1;
      await loadMarks(filePath);
      await _audioHandler.play();
      notifyListeners();
      return true;
    } catch (_) {
      playbackError =
          'MarkedPlay could not play this file. It may be damaged or use an unsupported format.';
      notifyListeners();
      return false;
    }
  }

  Future<void> togglePlayPause() async {
    if (currentFilePath == null || !_isAudioSource) return;
    if (isPlaying) {
      await _audioHandler.pause();
    } else {
      if (_processingState == AudioProcessingState.completed) {
        await _audioHandler.seek(Duration.zero);
      }
      await _audioHandler.play();
    }
  }

  Future<void> setPlaybackSpeed(double speed) async {
    playbackSpeed = speed.clamp(0.5, 2.0);
    if (_isAudioSource) await _audioHandler.setSpeed(playbackSpeed);
    notifyListeners();
  }

  void setShuffle(bool enabled) {
    shuffleEnabled = enabled;
    notifyListeners();
  }

  Future<void> pauseAudio() => _audioHandler.pause();

  Future<void> stopAudio({bool stopPlayer = true}) async {
    await _saveCurrentPosition();
    if (stopPlayer) await _audioHandler.stop();
    currentFilePath = null;
    currentArtworkBytes = null;
    currentSongId = null;
    currentPosition = Duration.zero;
    totalDuration = Duration.zero;
    notifyListeners();
  }

  Future<void> seekAudio(Duration position) async {
    var target = position;
    if (target < Duration.zero) target = Duration.zero;
    if (totalDuration > Duration.zero && target > totalDuration) {
      target = totalDuration;
    }
    await _audioHandler.seek(target);
  }

  void setLoopMode(String mode) {
    if (!const ['No Loop', 'Loop One', 'Loop All'].contains(mode)) return;
    loopMode = mode;
    notifyListeners();
  }

  Future<void> _saveCurrentPosition() async {
    final filePath = currentFilePath;
    if (filePath == null || !_isAudioSource) return;
    await _positionStore.save(
      filePath,
      PlaybackMediaType.audio,
      currentPosition,
      duration: totalDuration,
    );
  }

  Future<void> markPosition(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    final marksKey = '$filePath-marks';
    if (marks.any((mark) => mark.inSeconds == currentPosition.inSeconds)) {
      return;
    }
    marks.add(currentPosition);
    marks.sort();
    await prefs.setStringList(
      marksKey,
      marks.map((mark) => mark.inSeconds.toString()).toList(),
    );
    notifyListeners();
  }

  Future<void> deleteMark(String filePath, Duration mark) async {
    final prefs = await SharedPreferences.getInstance();
    marks.remove(mark);
    await prefs.setStringList(
      '$filePath-marks',
      marks.map((item) => item.inSeconds.toString()).toList(),
    );
    notifyListeners();
  }

  Future<void> loadMarks(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    final marksList = prefs.getStringList('$filePath-marks') ?? const [];
    marks = marksList
        .map(int.tryParse)
        .whereType<int>()
        .map((seconds) => Duration(seconds: seconds))
        .toList()
      ..sort();
    notifyListeners();
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _playbackStateSubscription.cancel();
    _positionSubscription.cancel();
    _mediaItemSubscription.cancel();
    super.dispose();
  }
}
