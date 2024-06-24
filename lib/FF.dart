import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';


import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerScreen extends StatefulWidget {
  final String filePath; // File path of the audio file to play

  AudioPlayerScreen({required this.filePath});

  @override
  _AudioPlayerScreenState createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final AudioPlayer audioPlayer = AudioPlayer();
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    _playAudio(); // Automatically start playing audio when screen initializes
  }

  Future<void> _playAudio() async {
    try {
      await audioPlayer.play(DeviceFileSource(widget.filePath));
      setState(() {
        isPlaying = true;
      });
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  Future<void> _pauseAudio() async {
    try {
      await audioPlayer.pause();
      setState(() {
        isPlaying = false;
      });
    } catch (e) {
      print('Error pausing audio: $e');
    }
  }

  @override
  void dispose() {
    audioPlayer.dispose(); // Dispose the audio player when screen is disposed
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
            Text('Now Playing: ${widget.filePath}'), // Display file path or metadata
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: isPlaying ? _pauseAudio : _playAudio,
                ),
                IconButton(
                  icon: Icon(Icons.stop),
                  onPressed: () async {
                    await audioPlayer.stop();
                    setState(() {
                      isPlaying = false;
                    });
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

