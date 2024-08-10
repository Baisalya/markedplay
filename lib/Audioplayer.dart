import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Pages/Feature/Scrolltext.dart';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioPlayerScreen extends StatefulWidget {
  final String filePath;
  final Duration startPosition;

  AudioPlayerScreen({required this.filePath, required this.startPosition});

  @override
  _AudioPlayerScreenState createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  List<String> _backgroundImages = [
    'assets/songbg/Beautifulsky.jpg',
    'assets/songbg/Colorful Leaves with Water Droplets Aesthetic Nature (57) - 480x857.JPG',
    'assets/songbg/Evening Beach Aesthetic Calm and Relaxing Sea Waves (245) - 2000x3569.JPG',
    'assets/songbg/Evening Beach Aesthetic Calm and Relaxing Sea Waves (659) - 2000x3569.JPG',
  ];
  int _currentBackgroundIndex = 0;

  @override
  void initState() {
    super.initState();
    final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
    audioProvider.playAudio(widget.filePath, startPosition: widget.startPosition);

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _changeBackgroundImage() {
    setState(() {
      _currentBackgroundIndex = (_currentBackgroundIndex + 1) % _backgroundImages.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioPlayerProvider>(context);

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
          actions: [
            IconButton(
              icon: Icon(Icons.image, color: Colors.white),
              onPressed: _changeBackgroundImage,
            ),
            PopupMenuButton<String>(
              onSelected: (String value) {
                audioProvider.setLoopMode(value);
              },
              itemBuilder: (BuildContext context) {
                return {'Loop One', 'Loop All', 'No Loop'}.map((String choice) {
                  return PopupMenuItem<String>(
                    value: choice,
                    child: Text(choice),
                  );
                }).toList();
              },
              icon: Icon(Icons.loop, color: Colors.white),
            ),
          ],
        ),
        body: Stack(
          children: [
            // Background image with blur effect
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(_backgroundImages[_currentBackgroundIndex]),
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
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Large circular container with the asset image
                              Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: AssetImage('assets/songbg/vinylmusic.png'),
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
                              // Small circular container with the file image
                              if (File(widget.filePath).existsSync())
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2), // Optional border for visibility
                                    image: DecorationImage(
                                      image: FileImage(File(widget.filePath)),
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
                              // Blank circular container
                              Container(
                                width: 15,
                                height: 15,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.transparent,
                                  border: Border.all(color: Colors.white, width: 2), // Optional border for visibility
                                ),
                              ),
                            ],
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
                          '${audioProvider.currentPosition.toString().split('.').first} / ${audioProvider.totalDuration.toString().split('.').first}',
                          style: TextStyle(fontSize: 18, color: Colors.white70),
                        ),
                        Slider(
                          value: audioProvider.currentPosition.inSeconds.toDouble(),
                          max: audioProvider.totalDuration.inSeconds.toDouble(),
                          onChanged: (value) {
                            audioProvider.seekAudio(Duration(seconds: value.toInt()));
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
                              onPressed: () => audioProvider.seekAudio(audioProvider.currentPosition - Duration(seconds: 10)),
                            ),
                            IconButton(
                              icon: Icon(audioProvider.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                              iconSize: 30,
                              onPressed: () => audioProvider.playAudio(widget.filePath),
                            ),
                            IconButton(
                              icon: Icon(Icons.forward_10, color: Colors.white),
                              iconSize: 30,
                              onPressed: () => audioProvider.seekAudio(audioProvider.currentPosition + Duration(seconds: 10)),
                            ),
                            IconButton(
                              icon: Icon(Icons.flag, color: Colors.white),
                              iconSize: 30,
                              onPressed: () {
                                audioProvider.markPosition(widget.filePath);
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        // List of marks
                        Expanded(
                          child: ListView.builder(
                            itemCount: audioProvider.marks.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(
                                  audioProvider.marks[index].toString().split('.').first,
                                  style: TextStyle(color: Colors.white),
                                ),
                                onTap: () {
                                  audioProvider.seekAudio(audioProvider.marks[index]);
                                },
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




class AudioPlayerProvider with ChangeNotifier {
  final AudioPlayer audioPlayer = AudioPlayer();
  bool isPlaying = false;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;
  List<Duration> marks = [];
  String loopMode = 'No Loop';
  String? currentFilePath;

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

    // Add the current position to the marks list
    marks.add(currentPosition);

    // Save the marks list to SharedPreferences
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

class MiniPlayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioPlayerProvider>(context);

    return audioProvider.currentFilePath == null
        ? SizedBox.shrink()
        : GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AudioPlayerScreen(
              filePath: audioProvider.currentFilePath!,
              startPosition: audioProvider.currentPosition,
            ),
          ),
        );
      },
      child: Container(
        color: Colors.black54,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Now Playing: ${audioProvider.currentFilePath!.split('/').last}',
              style: TextStyle(color: Colors.white),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(audioProvider.isPlaying ? Icons.pause : Icons.play_arrow),
                  color: Colors.white,
                  onPressed: () {
                    audioProvider.playAudio(audioProvider.currentFilePath!);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  color: Colors.white,
                  onPressed: () {
                    audioProvider.pauseAudio();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
