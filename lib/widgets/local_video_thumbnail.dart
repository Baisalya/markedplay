import 'dart:io';
import 'package:flutter/material.dart';
import '../core/services/thumbnail_service.dart';

class LocalVideoThumbnail extends StatefulWidget {
  final String path;

  const LocalVideoThumbnail({super.key, required this.path});

  @override
  State<LocalVideoThumbnail> createState() =>
      _LocalVideoThumbnailState();
}

class _LocalVideoThumbnailState
    extends State<LocalVideoThumbnail> {
  
  String? _thumbPath;
  bool _loading = true;
  final _service = ThumbnailService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant LocalVideoThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _load();
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    
    final path = await _service.getThumbnail(widget.path);
    
    if (mounted) {
      setState(() {
        _thumbPath = path;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: SizedBox(
            width: 15, 
            height: 15, 
            child: CircularProgressIndicator(strokeWidth: 1.5)
          ),
        ),
      );
    }

    if (_thumbPath == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.videocam_off, color: Colors.white24, size: 24)
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        File(_thumbPath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        cacheWidth: 300, // Optimize memory
        errorBuilder: (context, error, stackTrace) => Container(color: Colors.black12),
      ),
    );
  }
}
