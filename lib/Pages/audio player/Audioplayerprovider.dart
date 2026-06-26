import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audio_service/audio_service.dart';
import 'package:path_provider/path_provider.dart';
import 'AudioHandler.dart';

class AudioPlayerProvider with ChangeNotifier {
  final MyAudioHandler _audioHandler;
  final OnAudioQuery _audioQuery = OnAudioQuery();
  
  bool isPlaying = false;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;
  List<Duration> marks = [];
  String loopMode = 'No Loop';
  String? currentFilePath;
  int? currentSongId;
  Uint8List? currentArtworkBytes;
  
  List<SongModel> _playlist = [];
  int _currentIndex = -1;
  DateTime? _sleepTimerEndTime;

  AudioProcessingState _processingState = AudioProcessingState.idle;

  DateTime? get sleepTimerEndTime => _sleepTimerEndTime;

  AudioPlayerProvider(this._audioHandler) {
    _audioHandler.playbackState.listen((state) {
      final isAudio = _audioHandler.mediaItem.value?.extras?['type'] != 'video';
      isPlaying = state.playing && isAudio;
      _processingState = state.processingState;
      if (state.processingState == AudioProcessingState.completed && isAudio) {
        _handleSongCompletion();
      }
      notifyListeners();
    });
    AudioService.position.listen((position) {
      if (_audioHandler.mediaItem.value?.extras?['type'] != 'video') {
        currentPosition = position;
        notifyListeners();
      }
    });
    _audioHandler.mediaItem.listen((item) {
      if (item != null && item.extras?['type'] != 'video') {
        totalDuration = item.duration ?? Duration.zero;
        notifyListeners();
      }
    });
  }

  void setSleepTimer(Duration? duration) {
    if (duration == null) {
      _sleepTimerEndTime = null;
    } else {
      _sleepTimerEndTime = DateTime.now().add(duration);
      Future.delayed(duration, () {
        if (_sleepTimerEndTime != null && DateTime.now().isAfter(_sleepTimerEndTime!)) {
          pauseAudio();
          _sleepTimerEndTime = null;
          notifyListeners();
        }
      });
    }
    notifyListeners();
  }

  void updatePlaylist(List<SongModel> songs) {
    _playlist = songs;
  }

  Future<void> _handleSongCompletion() async {
    if (loopMode == 'Loop One') {
      await seekAudio(Duration.zero);
      await _audioHandler.play();
    } else if (loopMode == 'Loop All') {
      await playNext();
    } else {
      await _audioHandler.pause();
    }
  }

  Future<void> playNext() async {
    if (_playlist.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % _playlist.length;
    await playAudio(_playlist[_currentIndex].data);
  }

  Future<void> playPrevious() async {
    if (_playlist.isEmpty) return;
    _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    await playAudio(_playlist[_currentIndex].data);
  }

  Future<void> playAudio(String filePath, {Duration startPosition = Duration.zero}) async {
    final bool isVideoActive = _audioHandler.mediaItem.value?.extras?['type'] == 'video';

    if (isPlaying && currentFilePath == filePath && !isVideoActive) {
      await _audioHandler.pause();
    } else if (!isPlaying && currentFilePath == filePath && !isVideoActive) {
      if (_processingState == AudioProcessingState.completed) {
        await _audioHandler.seek(Duration.zero);
      }
      await _audioHandler.play();
    } else {
      currentFilePath = filePath;
      currentPosition = startPosition;
      
      if (_playlist.isNotEmpty) {
        _currentIndex = _playlist.indexWhere((s) => s.data == filePath);
      }

      String title = filePath.split('/').last.split('.').first;
      String artist = "Unknown Artist";
      String? artUri;
      Duration? duration;

      try {
        final file = File(filePath);
        if (!await file.exists()) {
           currentSongId = null;
           currentArtworkBytes = null;
           notifyListeners();
           return; 
        }

        List<SongModel> songs = _playlist.isNotEmpty ? _playlist : await _audioQuery.querySongs();
        final song = songs.firstWhere((s) => s.data == filePath, orElse: () => songs.first);
        currentSongId = song.id;
        title = song.title;
        artist = song.artist ?? "Unknown Artist";
        duration = Duration(milliseconds: song.duration ?? 0);
        
        currentArtworkBytes = await _audioQuery.queryArtwork(
          song.id,
          ArtworkType.AUDIO,
          format: ArtworkFormat.JPEG,
          size: 800, 
        );

        if (currentArtworkBytes != null) {
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/notif_art.jpg');
          await file.writeAsBytes(currentArtworkBytes!);
          artUri = file.uri.toString();
        }
      } catch (e) {
        currentSongId = null;
        currentArtworkBytes = null;
      }

      final mediaItem = MediaItem(
        id: filePath,
        album: "MarkedPlay",
        title: title,
        artist: artist,
        duration: duration,
        artUri: artUri != null ? Uri.parse(artUri) : null,
      );

      await _audioHandler.setAudioSource(filePath, mediaItem);
      if (startPosition != Duration.zero) await _audioHandler.seek(startPosition);
      await _audioHandler.play();
      await loadMarks(filePath);
    }
    notifyListeners();
  }

  Future<void> pauseAudio() async => await _audioHandler.pause();

  Future<void> stopAudio({bool stopPlayer = true}) async {
    if (stopPlayer) {
      await _audioHandler.stop();
    }
    currentFilePath = null;
    currentArtworkBytes = null;
    notifyListeners();
  }

  Future<void> seekAudio(Duration position) async {
    Duration target = position;
    if (target < Duration.zero) target = Duration.zero;
    if (totalDuration > Duration.zero && target > totalDuration) target = totalDuration;
    await _audioHandler.seek(target);
  }

  void setLoopMode(String mode) { loopMode = mode; notifyListeners(); }

  Future<void> markPosition(String filePath) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String marksKey = '$filePath-marks';
    if (marks.any((mark) => mark.inSeconds == currentPosition.inSeconds)) return;
    marks.add(currentPosition);
    await prefs.setStringList(marksKey, marks.map((m) => m.inSeconds.toString()).toList());
    notifyListeners();
  }

  Future<void> deleteMark(String filePath, Duration mark) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    marks.remove(mark);
    await prefs.setStringList('$filePath-marks', marks.map((m) => m.inSeconds.toString()).toList());
    notifyListeners();
  }

  Future<void> loadMarks(String filePath) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? marksList = prefs.getStringList('$filePath-marks');
    marks = marksList?.map((mark) => Duration(seconds: int.parse(mark))).toList() ?? [];
    notifyListeners();
  }
}
