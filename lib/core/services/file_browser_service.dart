import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path_utils;

class FileBrowserService {
  static const _videoExtensions = {
    '.mp4',
    '.mkv',
    '.avi',
    '.mov',
    '.webm',
    '.m4v',
    '.3gp',
    '.ts',
  };
  static const _audioExtensions = {
    '.mp3',
    '.aac',
    '.wav',
    '.m4a',
    '.flac',
    '.ogg',
    '.opus',
  };

  final Map<String, bool> _hasMediaCache = {};

  bool isVideoFile(String path) =>
      _videoExtensions.contains(path_utils.extension(path).toLowerCase());

  bool isAudioFile(String path) =>
      _audioExtensions.contains(path_utils.extension(path).toLowerCase());

  void clearCache() => _hasMediaCache.clear();

  Future<bool> _containsRelevantFiles(
    Directory directory,
    bool isVideoTab,
  ) async {
    final cacheKey = '${directory.path}_$isVideoTab';
    final cached = _hasMediaCache[cacheKey];
    if (cached != null) return cached;

    try {
      final hasMedia = await directory
          .list(recursive: true, followLinks: false)
          .any((entity) =>
              entity is File &&
              (isVideoTab
                  ? isVideoFile(entity.path)
                  : isAudioFile(entity.path)));
      _hasMediaCache[cacheKey] = hasMedia;
      return hasMedia;
    } on FileSystemException {
      return false;
    }
  }

  Future<List<FileSystemEntity>> loadDirectory(
    String path,
    bool isVideoTab, {
    bool showHiddenFiles = false,
  }) async {
    try {
      final directory = Directory(path);
      if (!await directory.exists()) return [];
      final items = await directory.list(followLinks: false).toList();

      Future<FileSystemEntity?> inspect(FileSystemEntity item) async {
        try {
          if (item is Directory) {
            final name = path_utils.basename(item.path);
            final normalizedPath = item.path.replaceAll('\\', '/');
            if ((!showHiddenFiles && name.startsWith('.')) ||
                normalizedPath.contains('/Android/data') ||
                normalizedPath.contains('/Android/obb')) {
              return null;
            }
            return await _containsRelevantFiles(item, isVideoTab) ? item : null;
          }
          if (item is File &&
              (isVideoTab ? isVideoFile(item.path) : isAudioFile(item.path))) {
            return item;
          }
        } on FileSystemException {
          return null;
        }
        return null;
      }

      final results = <FileSystemEntity?>[];
      const batchSize = 8;
      for (var start = 0; start < items.length; start += batchSize) {
        final end = (start + batchSize).clamp(0, items.length).toInt();
        results.addAll(
          await Future.wait(items.sublist(start, end).map(inspect)),
        );
      }
      return results.whereType<FileSystemEntity>().toList(growable: false);
    } on FileSystemException catch (error) {
      debugPrint('Directory access error: $error');
      return [];
    }
  }
}
