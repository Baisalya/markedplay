import 'dart:io';
import 'package:flutter/material.dart';
import '../core/services/thumbnail_service.dart';

class LocalVideoThumbnail extends StatefulWidget {
  final String path;
  final double? width;
  final double? height;

  const LocalVideoThumbnail({
    super.key,
    required this.path,
    this.width,
    this.height,
  });

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
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 15,
          height: 15,
          child: CircularProgressIndicator(strokeWidth: 1.5),
        ),
      );
    }

    if (_thumbPath == null) {
      return const Center(
        child: Icon(Icons.videocam_off, color: Colors.white24, size: 24),
      );
    }

    return Image.file(
      File(_thumbPath!),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      cacheWidth: 300, // Optimize memory
      errorBuilder: (context, error, stackTrace) => const SizedBox(),
    );
  }
}
