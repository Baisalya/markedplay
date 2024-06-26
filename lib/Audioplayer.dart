import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

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
      appBar: AppBar(
        title: Text('Audio Player'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${currentPosition.toString().split('.').first} / ${totalDuration.toString().split('.').first}',
              style: TextStyle(fontSize: 24),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.replay_10),
                  onPressed: () => _seekAudio(currentPosition - Duration(seconds: 10)),
                ),
                IconButton(
                  icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: isPlaying ? _pauseAudio : _playAudio,
                ),
                IconButton(
                  icon: Icon(Icons.forward_10),
                  onPressed: () => _seekAudio(currentPosition + Duration(seconds: 10)),
                ),
                IconButton(
                  icon: Icon(Icons.flag),
                  onPressed: _markPosition,
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: marks.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(marks[index].toString().split('.').first),
                    onTap: () => _seekAudio(marks[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

