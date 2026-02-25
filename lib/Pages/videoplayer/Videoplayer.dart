import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LoopMode { none, one }

class VideoPlayerScreen extends StatefulWidget {
  final String filePath;

  const VideoPlayerScreen({super.key, required this.filePath});

  @override
  State<VideoPlayerScreen> createState() =>
      _VideoPlayerScreenState();
}

class _VideoPlayerScreenState
    extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;

  bool _isFullScreen = false;
  bool _showControls = true;
  LoopMode _loopMode = LoopMode.none;
  double _playbackSpeed = 1.0;

  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _controller =
        VideoPlayerController.file(File(widget.filePath));

    await _controller.initialize();
    await _loadLastPosition();

    _controller.play();

    _controller.addListener(_videoListener);

    setState(() {});
    _startHideTimer();
  }

  void _videoListener() {
    final value = _controller.value;

    if (value.position >= value.duration &&
        value.duration != Duration.zero) {
      if (_loopMode == LoopMode.one) {
        _controller.seekTo(Duration.zero);
        _controller.play();
      } else {
        _controller.pause();
      }
    }
  }

  // ================= Resume System =================

  Future<void> _saveLastPosition() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'resume_${widget.filePath}',
      _controller.value.position.inSeconds,
    );
  }

  Future<void> _loadLastPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final seconds =
    prefs.getInt('resume_${widget.filePath}');
    if (seconds != null) {
      _controller.seekTo(Duration(seconds: seconds));
    }
  }

  // ================= Controls =================

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _startHideTimer();
  }

  void _toggleFullScreen() {
    setState(() => _isFullScreen = !_isFullScreen);

    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  void _seekRelative(int seconds) {
    final newPosition =
        _controller.value.position +
            Duration(seconds: seconds);

    _controller.seekTo(newPosition);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _saveLastPosition();
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        onDoubleTapDown: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.localPosition.dx < width / 2) {
            _seekRelative(-10);
          } else {
            _seekRelative(10);
          }
        },
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio:
                _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            ),

            // Buffering indicator
            if (_controller.value.isBuffering)
              const Center(
                child: CircularProgressIndicator(),
              ),

            if (_showControls)
              _buildControlsOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Column(
      mainAxisAlignment:
      MainAxisAlignment.spaceBetween,
      children: [
        _topBar(),
        _bottomBar(),
      ],
    );
  }

  Widget _topBar() {
    return Container(
      color: Colors.black54,
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back,
                color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              widget.filePath.split('/').last,
              style: const TextStyle(
                  color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(
              _loopMode == LoopMode.one
                  ? Icons.repeat_one
                  : Icons.repeat,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _loopMode =
                _loopMode == LoopMode.none
                    ? LoopMode.one
                    : LoopMode.none;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      color: Colors.black54,
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VideoProgressIndicator(
            _controller,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: Colors.cyan,
              bufferedColor: Colors.grey,
              backgroundColor: Colors.white24,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _controller.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  });
                },
              ),
              const Spacer(),
              PopupMenuButton<double>(
                onSelected: (speed) {
                  _controller
                      .setPlaybackSpeed(speed);
                  setState(() =>
                  _playbackSpeed = speed);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                      value: 0.5,
                      child: Text("0.5x")),
                  const PopupMenuItem(
                      value: 1.0,
                      child: Text("1x")),
                  const PopupMenuItem(
                      value: 1.5,
                      child: Text("1.5x")),
                  const PopupMenuItem(
                      value: 2.0,
                      child: Text("2x")),
                ],
                child: Text(
                  "${_playbackSpeed}x",
                  style: const TextStyle(
                      color: Colors.white),
                ),
              ),
              IconButton(
                icon: Icon(
                  _isFullScreen
                      ? Icons.fullscreen_exit
                      : Icons.fullscreen,
                  color: Colors.white,
                ),
                onPressed: _toggleFullScreen,
              ),
            ],
          ),
        ],
      ),
    );
  }
}





