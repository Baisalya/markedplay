import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';

class CustomVideoPlayerController {
  late VideoPlayerController _controller;
  late String filePath;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  VideoPlayerController get videoController => _controller;

  CustomVideoPlayerController(this.filePath);

  Future<void> initialize() async {
    _controller = VideoPlayerController.file(File(filePath))
      ..initialize().then((_) async {
        _isInitialized = true;
        await _loadLastPlayedPosition();
        _controller.play();
      });
  }

  Future<void> _saveLastPlayedPosition() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastPlayedPosition_$filePath', _controller.value.position.inSeconds);
  }

  Future<void> _loadLastPlayedPosition() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? lastPlayedPosition = prefs.getInt('lastPlayedPosition_$filePath');
    if (lastPlayedPosition != null) {
      _controller.seekTo(Duration(seconds: lastPlayedPosition));
    }
  }

  Future<void> dispose() async {
    await _saveLastPlayedPosition();
    _controller.dispose();
  }
}
