import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class LocalVideoThumbnail extends StatefulWidget {
  final String path;

  const LocalVideoThumbnail({super.key, required this.path});

  @override
  State<LocalVideoThumbnail> createState() =>
      _LocalVideoThumbnailState();
}

class _LocalVideoThumbnailState
    extends State<LocalVideoThumbnail> {

  Uint8List? _thumbnail;

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  Future<void> _generateThumbnail() async {
    final uint8list =
    await VideoThumbnail.thumbnailData(
      video: widget.path,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 300,
      quality: 75,
    );

    if (mounted) {
      setState(() {
        _thumbnail = uint8list;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_thumbnail == null) {
      return const Center(
        child: Icon(Icons.play_circle),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.memory(
        _thumbnail!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }
}