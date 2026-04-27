






import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioPlayerProvider with ChangeNotifier {
  final AudioPlayer audioPlayer = AudioPlayer();
  final OnAudioQuery _audioQuery = OnAudioQuery();
  bool isPlaying = false;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;
  List<Duration> marks = [];
  String loopMode = 'No Loop';
  String? currentFilePath;
  int? currentSongId;
  Uint8List? currentArtworkBytes;

  AudioPlayerProvider() {
    audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      isPlaying = state == PlayerState.playing;
      notifyListeners();
    });

    audioPlayer.onPositionChanged.listen((Duration position) {
      currentPosition = position;
      notifyListeners();
    });

    audioPlayer.onDurationChanged.listen((Duration duration) {
      totalDuration = duration;
      notifyListeners();
    });

    audioPlayer.onPlayerComplete.listen((_) {
      if (loopMode == 'Loop One') {
        playAudio(currentFilePath!);
      } else if (loopMode == 'Loop All') {
        // handle loop all
      } else {
        isPlaying = false;
        notifyListeners();
      }
    });
  }

  Future<void> playAudio(String filePath, {Duration startPosition = Duration.zero}) async {
    if (isPlaying && currentFilePath == filePath) {
      await audioPlayer.pause();
      isPlaying = false;
    } else {
      currentFilePath = filePath;
      await audioPlayer.play(DeviceFileSource(filePath), position: startPosition);
      isPlaying = true;

      // Try to find the song ID and artwork for display
      try {
        List<SongModel> songs = await _audioQuery.querySongs();
        final song = songs.firstWhere((s) => s.data == filePath);
        currentSongId = song.id;
        
        // Fetch artwork bytes once to prevent flickering
        currentArtworkBytes = await _audioQuery.queryArtwork(
          song.id,
          ArtworkType.AUDIO,
          format: ArtworkFormat.JPEG,
          size: 200,
        );
      } catch (e) {
        currentSongId = null;
        currentArtworkBytes = null;
      }

      // Load the marks for this file
      await loadMarks(filePath);
    }
    notifyListeners();
  }

  Future<void> pauseAudio() async {
    await audioPlayer.pause();
    isPlaying = false;
    notifyListeners();
  }

  Future<void> seekAudio(Duration position) async {
    await audioPlayer.seek(position);
    notifyListeners();
  }

  void setLoopMode(String mode) {
    loopMode = mode;
    notifyListeners();
  }

  Future<void> markPosition(String filePath) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String marksKey = '$filePath-marks';

    // Check if the current position is already marked
    if (marks.any((mark) => mark.inSeconds == currentPosition.inSeconds)) {
      return; // Don't mark the same second twice
    }

    // Add the current position to the marks list
    marks.add(currentPosition);

    // Save the marks list to SharedPreferences
    List<String> marksList = marks.map((mark) => mark.inSeconds.toString()).toList();
    await prefs.setStringList(marksKey, marksList);

    notifyListeners();
  }

  Future<void> deleteMark(String filePath, Duration mark) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String marksKey = '$filePath-marks';

    // Remove the specified mark
    marks.remove(mark);

    // Save the updated marks list to SharedPreferences
    List<String> marksList = marks.map((mark) => mark.inSeconds.toString()).toList();
    await prefs.setStringList(marksKey, marksList);

    notifyListeners();
  }
// Load the marks when initializing the provider
  Future<void> loadMarks(String filePath) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String marksKey = '$filePath-marks';

    // Load the marks list from SharedPreferences
    List<String>? marksList = prefs.getStringList(marksKey);
    marks = marksList?.map((mark) => Duration(seconds: int.parse(mark))).toList() ?? [];

    notifyListeners();
  }

}
