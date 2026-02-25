import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';

import 'Videoplayer.dart';

class VideoListScreen extends StatelessWidget {
  final String folderName;
  final List<AssetEntity> videos;

  const VideoListScreen(
      {super.key, required this.folderName, required this.videos});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(folderName)),
      body: ListView.builder(
        itemCount: videos.length,
        itemBuilder: (_, index) {
          final video = videos[index];

          return FutureBuilder<File?>(
            future: video.file,
            builder: (_, snapshot) {
              if (!snapshot.hasData) return const SizedBox();

              return ListTile(
                leading: FutureBuilder<Uint8List?>(
                  future: video.thumbnailDataWithSize(
                      const ThumbnailSize(200, 200)),
                  builder: (_, snap) {
                    if (!snap.hasData) {
                      return const Icon(Icons.video_library);
                    }
                    return Image.memory(
                      snap.data!,
                      width: 60,
                      fit: BoxFit.cover,
                    );
                  },
                ),
                title: Text(video.title ?? "Video"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VideoPlayerScreen(
                          filePath: snapshot.data!.path),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}