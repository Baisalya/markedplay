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

import '../../controller/CustomVideoPlayerController .dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:volume_control/volume_control.dart'; // Add volume_control package in pubspec.yaml

class CustomVideoPlayerController {
  late VideoPlayerController _controller;
  late String filePath;
  bool _isInitialized = false;
  LoopMode _loopMode = LoopMode.none;

  bool get isInitialized => _isInitialized;
  VideoPlayerController get videoController => _controller;
  LoopMode get loopMode => _loopMode;

  CustomVideoPlayerController(this.filePath);

  Future<void> initialize() async {
    _controller = VideoPlayerController.file(File(filePath))
      ..initialize().then((_) async {
        _isInitialized = true;
        await _loadLastPlayedPosition();
        _controller.play();
      });

    _controller.addListener(() {
      if (_controller.value.position == _controller.value.duration) {
        switch (_loopMode) {
          case LoopMode.none:
            _controller.pause();
            break;
          case LoopMode.one:
            _controller.seekTo(Duration.zero);
            _controller.play();
            break;
          case LoopMode.all:
          // Implement logic to play the next video in the list
            break;
        }
      }
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

  void setLoopMode(LoopMode mode) {
    _loopMode = mode;
  }

  Future<void> dispose() async {
    await _saveLastPlayedPosition();
    _controller.dispose();
  }
}

enum LoopMode { none, one, all }

class VideoPlayerScreen extends StatefulWidget {
  final String filePath;

  VideoPlayerScreen({required this.filePath});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late CustomVideoPlayerController _customController;
  bool _isFullScreen = false;
  double _playbackSpeed = 1.0;
  bool _showControls = true;
  double _volume = 0.5; // Default volume

  @override
  void initState() {
    super.initState();
    _customController = CustomVideoPlayerController(widget.filePath);
    _customController.initialize().then((_) {
      setState(() {});
    });
    _getVolume();
  }

  @override
  void dispose() {
    _customController.dispose();
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

  void _changePlaybackSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
      _customController.videoController.setPlaybackSpeed(speed);
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _changeLoopMode() {
    setState(() {
      if (_customController.loopMode == LoopMode.none) {
        _customController.setLoopMode(LoopMode.one);
      } else if (_customController.loopMode == LoopMode.one) {
        _customController.setLoopMode(LoopMode.all);
      } else {
        _customController.setLoopMode(LoopMode.none);
      }
    });
  }

  Future<void> _getVolume() async {
    double? volume = await VolumeControl.volume;
    setState(() {
      _volume = volume ?? 0.5;
    });
  }

  Future<void> _setVolume(double volume) async {
    await VolumeControl.setVolume(volume);
    setState(() {
      _volume = volume;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: _customController.isInitialized
                ? GestureDetector(
              onTap: _toggleControls,
              child: AspectRatio(
                aspectRatio: _customController.videoController.value.aspectRatio,
                child: VideoPlayer(_customController.videoController),
              ),
            )
                : CircularProgressIndicator(),
          ),
          if (_showControls) _buildControlsOverlay(),
        ],
      ),
      floatingActionButton: !_isFullScreen
          ? FloatingActionButton(
        onPressed: _toggleFullScreen,
        child: Icon(_isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen),
      )
          : null,
    );
  }

  Widget _buildControlsOverlay() {
    return AnimatedOpacity(
      opacity: _showControls ? 1.0 : 0.0,
      duration: Duration(milliseconds: 300),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTopBar(),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              widget.filePath.split('/').last, // Displaying file name
              style: TextStyle(color: Colors.white, fontSize: 18),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VideoProgressIndicator(
            _customController.videoController,
            allowScrubbing: true,
            padding: EdgeInsets.all(10.0),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _customController.videoController.value.isPlaying
                        ? _customController.videoController.pause()
                        : _customController.videoController.play();
                  });
                },
                icon: Icon(
                  _customController.videoController.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: _toggleFullScreen,
                icon: Icon(
                  _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  color: Colors.white,
                ),
              ),
              PopupMenuButton<double>(
                initialValue: _playbackSpeed,
                onSelected: _changePlaybackSpeed,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 0.5,
                    child: Text("0.5x"),
                  ),
                  PopupMenuItem(
                    value: 1.0,
                    child: Text("1.0x"),
                  ),
                  PopupMenuItem(
                    value: 1.5,
                    child: Text("1.5x"),
                  ),
                  PopupMenuItem(
                    value: 2.0,
                    child: Text("2.0x"),
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    "${_playbackSpeed}x",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              IconButton(
                onPressed: _changeLoopMode,
                icon: Icon(
                  _customController.loopMode == LoopMode.none
                      ? Icons.loop
                      : (_customController.loopMode == LoopMode.one ? Icons.repeat_one : Icons.repeat),
                  color: Colors.white,
                ),
              ),
              Container(
                width: 150,
                child: Slider(
                  value: _volume,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  onChanged: (value) {
                    _setVolume(value);
                  },
                  activeColor: Colors.white,
                  inactiveColor: Colors.white24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}







