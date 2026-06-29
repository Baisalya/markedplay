import 'dart:io';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:video_thumbnail/video_thumbnail.dart';

class ThumbnailService {
  static final ThumbnailService _instance = ThumbnailService._internal();
  factory ThumbnailService() => _instance;
  ThumbnailService._internal();

  Database? _db;
  String? _cacheDir;
  bool _initialized = false;

  final List<String> _queue = [];
  final Map<String, Completer<String?>> _completers = {};
  bool _isProcessing = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    if (kIsWeb || Platform.isWindows || Platform.isLinux) return;
    final directory = await getTemporaryDirectory();
    _cacheDir = p.join(directory.path, 'video_thumbnails');
    await Directory(_cacheDir!).create(recursive: true);

    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dbPath, 'thumbnails.db'),
      version: 1,
      onCreate: (db, version) => db.execute(
        'CREATE TABLE thumbnails(video_path TEXT PRIMARY KEY, thumb_path TEXT)',
      ),
    );
  }

  /// Clears all stored thumbnails from DB and Disk
  Future<void> clearAll() async {
    await init();
    if (_db == null) return;
    try {
      // Clear DB
      await _db!.delete('thumbnails');

      // Clear Disk
      if (_cacheDir != null) {
        final dir = Directory(_cacheDir!);
        if (await dir.exists()) {
          final files = dir.listSync();
          for (var file in files) {
            if (file is File) await file.delete();
          }
        }
      }
      debugPrint("Thumbnail cache cleared successfully");
    } catch (e) {
      debugPrint("Error clearing thumbnail cache: $e");
    }
  }

  Future<String?> getThumbnail(String videoPath) async {
    await init();
    if (_db == null) return null;

    final List<Map<String, dynamic>> maps = await _db!.query(
      'thumbnails',
      where: 'video_path = ?',
      whereArgs: [videoPath],
    );

    if (maps.isNotEmpty) {
      final path = maps.first['thumb_path'] as String;
      if (await File(path).exists()) return path;
    }

    if (_completers.containsKey(videoPath)) {
      return _completers[videoPath]!.future;
    }

    final completer = Completer<String?>();
    _completers[videoPath] = completer;
    _queue.add(videoPath);

    _processQueue();
    return completer.future;
  }

  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;
    _isProcessing = true;

    while (_queue.isNotEmpty) {
      final videoPath = _queue.removeAt(0);
      final path = await _generateDeepScanThumbnail(videoPath);
      _completers[videoPath]?.complete(path);
      _completers.remove(videoPath);
    }
    _isProcessing = false;
  }

  Future<String?> _generateDeepScanThumbnail(String videoPath) async {
    // Professional Jumps: Deep points first, then shallower, then start.
    // Sequential try-catch ensures short videos don't fail the whole process.
    final List<int> timestamps = [2000, 10000, 30000, 60000, 1000, 0];

    Uint8List? bestBytes;
    double highestScore = -1.0;

    for (int time in timestamps) {
      try {
        final bytes = await VideoThumbnail.thumbnailData(
          video: videoPath,
          imageFormat: ImageFormat.JPEG,
          maxWidth: 250,
          quality: 45,
          timeMs: time,
        );

        if (bytes != null && bytes.isNotEmpty) {
          double score = await _calculateFrameScore(bytes);

          // FAST PASS: If score is high (bright + detailed), take it and stop.
          if (score > 40.0) {
            bestBytes = bytes;
            highestScore = score;
            break;
          }

          if (score > highestScore) {
            highestScore = score;
            bestBytes = bytes;
          }
        }
      } catch (e) {
        // Skip if timestamp is invalid for this specific video
        continue;
      }
    }

    // Save the best discovered frame
    if (bestBytes != null && highestScore >= 0) {
      try {
        final fileName = "thumb_${DateTime.now().microsecondsSinceEpoch}.jpg";
        final thumbFile = File(p.join(_cacheDir!, fileName));
        await thumbFile.writeAsBytes(bestBytes);

        await _db!.insert(
          'thumbnails',
          {'video_path': videoPath, 'thumb_path': thumbFile.path},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        return thumbFile.path;
      } catch (e) {
        debugPrint("Save failed: $e");
      }
    }
    return null;
  }

  Future<double> _calculateFrameScore(Uint8List data) async {
    try {
      final ui.Codec codec = await ui.instantiateImageCodec(data,
          targetWidth: 32, targetHeight: 32);
      final ui.FrameInfo fi = await codec.getNextFrame();
      final ui.Image image = fi.image;
      final ByteData? bytes =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      if (bytes == null) return 0.0;

      final Uint8List buffer = bytes.buffer.asUint8List();
      double sum = 0;
      List<double> lums = [];

      for (int i = 0; i < buffer.length; i += 16) {
        double lum =
            (0.299 * buffer[i] + 0.587 * buffer[i + 1] + 0.114 * buffer[i + 2]);
        lums.add(lum);
        sum += lum;
      }

      double avg = sum / lums.length;
      double variance = 0;
      for (double l in lums) {
        variance += (l - avg).abs();
      }

      // Professional Score: Variance (Detail) + slight weighting for brightness
      return (variance / lums.length) * 1.5 + (avg * 0.1);
    } catch (_) {
      return 0.0;
    }
  }
}
