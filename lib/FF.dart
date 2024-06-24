import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';


class AudioPlayerScreen extends StatefulWidget {
  final String filePath; // File path of the audio file to play

  AudioPlayerScreen({required this.filePath});

  @override
  _AudioPlayerScreenState createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final AudioPlayer audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _playAudio(); // Automatically start playing audio when screen initializes
  }

  Future<void> _playAudio() async {
    try {
      await audioPlayer.play(DeviceFileSource(widget.filePath));
    } catch (e) {
      print('Error playing audio: $e');
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
            // Add playback controls here (play, pause, stop, etc.)
          ],
        ),
      ),
    );
  }
}
