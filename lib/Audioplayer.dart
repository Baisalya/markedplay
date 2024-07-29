import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Pages/Feature/Scrolltext.dart';

import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/services.dart';

class AudioPlayerScreen extends StatefulWidget {
  final String filePath;

  AudioPlayerScreen({required this.filePath});

  @override
  _AudioPlayerScreenState createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> with SingleTickerProviderStateMixin {
  late AudioPlayerController _controller;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _controller = AudioPlayerController();
    _controller.loadMarks(widget.filePath, setState);
    _controller.loadLastPlayedPosition(widget.filePath);
    _controller.initAudioPlayer(setState, widget.filePath);

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose(widget.filePath);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: Stack(
          children: [
            // Background image with blur effect
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/songbg/Beautifulsky.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                child: Container(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Column(
              children: [
                SizedBox(height: kToolbarHeight), // space for the app bar
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated Album Art in a disc-shaped container
                        RotationTransition(
                          turns: _animationController,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: File(widget.filePath).existsSync()
                                    ? FileImage(File(widget.filePath))
                                    : AssetImage('assets/images.jpg') as ImageProvider,
                                fit: BoxFit.cover,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  spreadRadius: 5,
                                  blurRadius: 10,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 30),
                        // Song title
                        AutoScrollText(
                          text: getSongName(widget.filePath),
                          style: TextStyle(
                            fontSize: 26,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.black,
                                offset: Offset(3, 3),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'The Strokes',
                          style: TextStyle(fontSize: 20, color: Colors.white70),
                        ),
                        SizedBox(height: 30),
                        // Current position and total duration
                        Text(
                          '${_controller.currentPosition.toString().split('.').first} / ${_controller.totalDuration.toString().split('.').first}',
                          style: TextStyle(fontSize: 18, color: Colors.white70),
                        ),
                        Slider(
                          value: _controller.currentPosition.inSeconds.toDouble(),
                          max: _controller.totalDuration.inSeconds.toDouble(),
                          onChanged: (value) {
                            _controller.seekAudio(Duration(seconds: value.toInt()));
                          },
                          activeColor: Colors.white,
                          inactiveColor: Colors.white30,
                          thumbColor: Colors.white,
                        ),
                        SizedBox(height: 30),
                        // Audio controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(Icons.replay_10, color: Colors.white),
                              iconSize: 30,
                              onPressed: () => _controller.seekAudio(_controller.currentPosition - Duration(seconds: 10)),
                            ),
                            IconButton(
                              icon: Icon(_controller.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                              iconSize: 30,
                              onPressed: _controller.isPlaying ? _controller.pauseAudio : () => _controller.playAudio(widget.filePath),
                            ),
                            IconButton(
                              icon: Icon(Icons.forward_10, color: Colors.white),
                              iconSize: 30,
                              onPressed: () => _controller.seekAudio(_controller.currentPosition + Duration(seconds: 10)),
                            ),
                            IconButton(
                              icon: Icon(Icons.flag, color: Colors.white),
                              iconSize: 30,
                              onPressed: () => _controller.markPosition(setState, widget.filePath),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        // List of marks
                        Expanded(
                          child: ListView.builder(
                            itemCount: _controller.marks.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(
                                  _controller.marks[index].toString().split('.').first,
                                  style: TextStyle(color: Colors.white),
                                ),
                                onTap: () => _controller.seekAudio(_controller.marks[index]),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String getSongName(String filePath) {
    return filePath.split('/').last.split('.').first;
  }
}

class AudioPlayerController {
  final AudioPlayer audioPlayer = AudioPlayer();
  bool isPlaying = false;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;
  List<Duration> marks = [];

  void initAudioPlayer(void Function(void Function()) setState, String filePath) {
    audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      setState(() {
        isPlaying = state == PlayerState.playing;
      });
    });

    audioPlayer.onPositionChanged.listen((Duration position) {
      setState(() {
        currentPosition = position;
      });
    });

    audioPlayer.onDurationChanged.listen((Duration duration) {
      setState(() {
        totalDuration = duration;
      });
    });

    playAudio(filePath);
  }

  Future<void> playAudio(String filePath) async {
    try {
      await audioPlayer.play(DeviceFileSource(filePath));
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  Future<void> pauseAudio() async {
    try {
      await audioPlayer.pause();
    } catch (e) {
      print('Error pausing audio: $e');
    }
  }

  Future<void> seekAudio(Duration position) async {
    try {
      await audioPlayer.seek(position);
    } catch (e) {
      print('Error seeking audio: $e');
    }
  }

  void markPosition(void Function(void Function()) setState, String filePath) {
    setState(() {
      marks.add(currentPosition);
    });
    saveMarks(filePath);
  }

  Future<void> saveMarks(String filePath) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> marksString = marks.map((duration) => duration.inSeconds.toString()).toList();
    await prefs.setStringList('marks_$filePath', marksString);
  }

  Future<void> loadMarks(String filePath, void Function(void Function()) setState) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? marksString = prefs.getStringList('marks_$filePath');
    if (marksString != null) {
      setState(() {
        marks = marksString.map((mark) => Duration(seconds: int.parse(mark))).toList();
      });
    }
  }

  Future<void> saveLastPlayedPosition(String filePath) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastPlayedPosition_$filePath', currentPosition.inSeconds);
  }

  Future<void> loadLastPlayedPosition(String filePath) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? lastPlayedPosition = prefs.getInt('lastPlayedPosition_$filePath');
    if (lastPlayedPosition != null) {
      await audioPlayer.seek(Duration(seconds: lastPlayedPosition));
    }
  }

  void dispose(String filePath) {
    saveLastPlayedPosition(filePath);
    audioPlayer.dispose();
  }
}
