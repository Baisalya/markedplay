import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import 'Audioplayer.dart';
import 'Audioplayerprovider.dart';

class AudioListScreen extends StatelessWidget {
  final String albumName;
  final List<SongModel> songs;

  const AudioListScreen(
      {super.key, required this.albumName, required this.songs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(albumName)),
      body: ListView.builder(
        itemCount: songs.length,
        itemBuilder: (_, index) {
          final song = songs[index];

          return ListTile(
            leading: const Icon(Icons.music_note),
            title: Text(song.title),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AudioPlayerScreen(filePath: song.data,
                          startPosition: Provider.of<AudioPlayerProvider>(context, listen: false).currentPosition,
                          ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}