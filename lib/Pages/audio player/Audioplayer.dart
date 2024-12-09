import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Feature/Scrolltext.dart';
import 'package:provider/provider.dart';

import 'Audioplayerprovider.dart';


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
                        SizedBox(height: 0),

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
                        SizedBox(
                          height: 250, // Set the height as per your requirement
                          child: ListView.builder(
                            itemCount: audioProvider.marks.length,
                            itemBuilder: (context, index) {
                              Duration mark = audioProvider.marks[index];
                              return Center(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blueGrey,
                                    child: Text(
                                      (index + 1).toString(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Center(
                                    child: Text(
                                      mark.toString().split('.').first,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.2,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 2.0,
                                            color: Colors.black54,
                                            offset: Offset(1.0, 1.0),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  onTap: () {
                                    audioProvider.seekAudio(mark);
                                  },
                                  trailing: IconButton(
                                    icon: Icon(Icons.close, color: Colors.red),
                                    onPressed: () {
                                      audioProvider.deleteMark(widget.filePath, mark);
                                    },
                                  ),
                                ),
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





class MiniPlayer extends StatefulWidget {
  final VoidCallback onClose; // Add this callback to handle close action

  MiniPlayer({required this.onClose}); // Pass it through the constructor

  @override
  _MiniPlayerState createState() => _MiniPlayerState();
}
class _MiniPlayerState extends State<MiniPlayer> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this, // `vsync` comes from `TickerProviderStateMixin`
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black87, Colors.black54],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: Offset(0, -2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Now Playing: ${audioProvider.currentFilePath!.split('/').last}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1.1,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    audioProvider.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    size: 30,
                  ),
                  color: Colors.white,
                  onPressed: () {
                    audioProvider.playAudio(audioProvider.currentFilePath!);
                  },
                ),
                SizedBox(width: 20),
                IconButton(
                  icon: Icon(Icons.close, size: 24),
                  color: Colors.white,
                  onPressed: () {
                    widget.onClose(); // Invoke the callback to remove MiniPlayer
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
