import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioPlayerScreen extends StatefulWidget {
  final String filePath;

  AudioPlayerScreen({required this.filePath});

  @override
  _AudioPlayerScreenState createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final AudioPlayer audioPlayer = AudioPlayer();
  bool isPlaying = false;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;
  List<Duration> marks = [];

  @override
  void initState() {
    super.initState();
    _loadMarks();
    _loadLastPlayedPosition();
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
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

    _playAudio();
  }

  Future<void> _playAudio() async {
    try {
      await audioPlayer.play(DeviceFileSource(widget.filePath));
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  Future<void> _pauseAudio() async {
    try {
      await audioPlayer.pause();
    } catch (e) {
      print('Error pausing audio: $e');
    }
  }

  Future<void> _seekAudio(Duration position) async {
    try {
      await audioPlayer.seek(position);
    } catch (e) {
      print('Error seeking audio: $e');
    }
  }

  void _markPosition() {
    setState(() {
      marks.add(currentPosition);
    });
    _saveMarks();
  }

  Future<void> _saveMarks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> marksString = marks.map((duration) => duration.inSeconds.toString()).toList();
    await prefs.setStringList('marks_${widget.filePath}', marksString);
  }

  Future<void> _loadMarks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? marksString = prefs.getStringList('marks_${widget.filePath}');
    if (marksString != null) {
      setState(() {
        marks = marksString.map((mark) => Duration(seconds: int.parse(mark))).toList();
      });
    }
  }

  Future<void> _saveLastPlayedPosition() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastPlayedPosition_${widget.filePath}', currentPosition.inSeconds);
  }

  Future<void> _loadLastPlayedPosition() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? lastPlayedPosition = prefs.getInt('lastPlayedPosition_${widget.filePath}');
    if (lastPlayedPosition != null) {
      await audioPlayer.seek(Duration(seconds: lastPlayedPosition));
    }
  }

  @override
  void dispose() {
    _saveLastPlayedPosition();
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                image: File(widget.filePath).existsSync()
                    ? FileImage(File(widget.filePath))
                    : AssetImage('assets/music1.jpg') as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Album Art
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: File(widget.filePath).existsSync()
                          ? FileImage(File(widget.filePath))
                          : AssetImage('assets/default_album_art.jpg') as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                SizedBox(height: 20),
                // Song title
                Text(
                  getSongName(widget.filePath),
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
                Text(
                  'The Strokes',
                  style: TextStyle(fontSize: 18, color: Colors.white70),
                ),
                SizedBox(height: 20),
                // Current position and total duration
                Text(
                  '${currentPosition.toString().split('.').first} / ${totalDuration.toString().split('.').first}',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                SizedBox(height: 20),
                // Audio controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.replay_10, color: Colors.white),
                      onPressed: () => _seekAudio(currentPosition - Duration(seconds: 10)),
                    ),
                    IconButton(
                      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                      onPressed: isPlaying ? _pauseAudio : _playAudio,
                    ),
                    IconButton(
                      icon: Icon(Icons.forward_10, color: Colors.white),
                      onPressed: () => _seekAudio(currentPosition + Duration(seconds: 10)),
                    ),
                    IconButton(
                      icon: Icon(Icons.flag, color: Colors.white),
                      onPressed: _markPosition,
                    ),
                  ],
                ),
                // List of marks
                Expanded(
                  child: ListView.builder(
                    itemCount: marks.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(
                          marks[index].toString().split('.').first,
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () => _seekAudio(marks[index]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String getSongName(String filePath) {
    return filePath.split('/').last.split('.').first;
  }

}
