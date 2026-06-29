import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../audio player/AudioHandler.dart';

class VideoBackgroundProvider with ChangeNotifier {
  final MyAudioHandler _audioHandler;

  bool isPlaying = false;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;
  String? currentFilePath;
  List<String>? currentPlaylist;
  int currentIndex = 0;

  VideoBackgroundProvider(this._audioHandler) {
    _audioHandler.configureVideoControls(
      onSkipToNext: playNext,
      onSkipToPrevious: playPrevious,
    );
    _audioHandler.playbackState.listen((state) {
      final isVideo = _audioHandler.mediaItem.value?.extras?['type'] == 'video';
      isPlaying = state.playing && isVideo;

      if (state.processingState == AudioProcessingState.idle &&
          !state.playing &&
          isVideo) {
        if (currentFilePath != null) {
          _saveCurrentPosition();
        }
        currentFilePath = null;
      }
      notifyListeners();
    });
    _audioHandler.player.positionStream.listen((position) {
      if (_audioHandler.mediaItem.value?.extras?['type'] == 'video') {
        currentPosition = position;
        notifyListeners();
      }
    });
    _audioHandler.mediaItem.listen((item) {
      if (item != null && item.extras?['type'] == 'video') {
        totalDuration = item.duration ?? Duration.zero;
        currentFilePath = item.id;
        notifyListeners();
      }
    });
  }

  Future<void> playNext() async {
    final playlist = currentPlaylist;
    if (playlist == null || currentIndex >= playlist.length - 1) return;
    currentIndex++;
    await playVideoAsAudio(
      playlist[currentIndex],
      playlist,
      currentIndex,
    );
  }

  Future<void> playPrevious() async {
    final playlist = currentPlaylist;
    if (playlist == null || currentIndex <= 0) return;
    currentIndex--;
    await playVideoAsAudio(
      playlist[currentIndex],
      playlist,
      currentIndex,
    );
  }

  Future<void> playVideoAsAudio(
      String filePath, List<String> playlist, int index,
      {Duration startPosition = Duration.zero}) async {
    currentFilePath = filePath;
    currentPlaylist = playlist;
    currentIndex = index;
    currentPosition = startPosition;
    String title = filePath.split('/').last;

    final mediaItem = MediaItem(
      id: filePath,
      album: "Video Playback",
      title: title,
      artist: "MarkedPlay Video",
      duration: null,
      extras: {'type': 'video'},
    );

    await _audioHandler.setAudioSource(filePath, mediaItem);
    if (startPosition != Duration.zero) await _audioHandler.seek(startPosition);
    await _audioHandler.play();
    notifyListeners();
  }

  Future<void> _saveCurrentPosition() async {
    if (currentFilePath != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(
            'resume_$currentFilePath', currentPosition.inSeconds);
      } catch (e) {
        debugPrint("Error saving background position: $e");
      }
    }
  }

  Future<void> stopBackgroundPlayback({bool stopPlayer = true}) async {
    if (currentFilePath != null) {
      await _saveCurrentPosition();
      if (stopPlayer) {
        await _audioHandler.stop();
      }
      currentFilePath = null;
      currentPlaylist = null;
      notifyListeners();
    }
  }

  Future<void> pauseAudio() async => await _audioHandler.pause();
  Future<void> resumeAudio() async {
    final bool isVideoActive =
        _audioHandler.mediaItem.value?.extras?['type'] == 'video';
    final bool isCorrectFile =
        _audioHandler.mediaItem.value?.id == currentFilePath;

    if (isVideoActive && isCorrectFile) {
      await _audioHandler.play();
    } else if (currentFilePath != null) {
      // Re-assert video source if it was swapped out by music
      await playVideoAsAudio(
        currentFilePath!,
        currentPlaylist ?? [currentFilePath!],
        currentIndex,
        startPosition: currentPosition,
      );
    }
  }
}
