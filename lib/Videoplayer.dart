import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class VideoPlayerScreen extends StatefulWidget {
  final String filePath;

  VideoPlayerScreen({required this.filePath});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.filePath))
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
        _loadLastPlayedPosition();
        _controller.play();
      });
  }

  Future<void> _saveLastPlayedPosition() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastPlayedPosition_${widget.filePath}', _controller.value.position.inSeconds);
  }

  Future<void> _loadLastPlayedPosition() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? lastPlayedPosition = prefs.getInt('lastPlayedPosition_${widget.filePath}');
    if (lastPlayedPosition != null) {
      _controller.seekTo(Duration(seconds: lastPlayedPosition));
    }
  }

  @override
  void dispose() {
    _saveLastPlayedPosition();
    _controller.dispose();
    super.dispose();
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isFullScreen ? null : AppBar(
        title: Text('Video Player'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: _isInitialized
                ? Column(
              children: [
                GestureDetector(
                  onTap: _toggleFullScreen,
                  child: Container(
                    width: constraints.maxWidth,
                    height: _isFullScreen ? constraints.maxHeight : constraints.maxWidth * (9 / 16),
                    child: VideoPlayer(_controller),
                  ),
                ),
                if (!_isFullScreen)
                  VideoProgressIndicator(
                    _controller,
                    allowScrubbing: true,
                    padding: EdgeInsets.all(10.0),
                  ),
              ],
            )
                : CircularProgressIndicator(),
          );
        },
      ),
      floatingActionButton: !_isFullScreen
          ? Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _controller.value.isPlaying ? _controller.pause() : _controller.play();
              });
            },
            child: Icon(
              _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
            ),
          ),
          SizedBox(width: 10),
          FloatingActionButton(
            onPressed: _toggleFullScreen,
            child: Icon(_isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen),
          ),
        ],
      )
          : null,
    );
  }
}


