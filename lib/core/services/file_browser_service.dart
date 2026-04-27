import 'dart:io';

class FileBrowserService {

  bool isVideoFile(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith(".mp4") ||
        ext.endsWith(".mkv") ||
        ext.endsWith(".avi") ||
        ext.endsWith(".mov") ||
        ext.endsWith(".webm");
  }

  bool isAudioFile(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith(".mp3") ||
        ext.endsWith(".aac") ||
        ext.endsWith(".wav") ||
        ext.endsWith(".m4a") ||
        ext.endsWith(".flac");
  }

  final Map<String, bool> _hasMediaCache = {};

  void clearCache() {
    _hasMediaCache.clear();
  }

  Future<bool> _containsRelevantFiles(Directory dir, bool isVideoTab) async {
    final cacheKey = "${dir.path}_$isVideoTab";
    if (_hasMediaCache.containsKey(cacheKey)) {
      return _hasMediaCache[cacheKey]!;
    }

    try {
      // Use stream for better performance and early exit
      final hasMedia = await dir.list(recursive: true, followLinks: false).any((entity) {
        if (entity is File) {
          if (isVideoTab) {
            return isVideoFile(entity.path);
          } else {
            return isAudioFile(entity.path);
          }
        }
        return false;
      });

      _hasMediaCache[cacheKey] = hasMedia;
      return hasMedia;
    } catch (_) {
      return false;
    }
  }

  Future<List<FileSystemEntity>> loadDirectory(
      String path,
      bool isVideoTab,
      ) async {
    try {
      final dir = Directory(path);

      if (!await dir.exists()) return [];

      final items = dir.listSync();

      // We'll process directories in parallel to speed things up
      List<Future<FileSystemEntity?>> futures = items.map((item) async {
        try {
          if (item is Directory) {
            final name = item.path.split('/').last;
            // 🚫 Skip restricted or irrelevant folders
            if (name.startsWith('.') ||
                item.path.contains("/Android/data") ||
                item.path.contains("/Android/obb")) {
              return null;
            }

            // ✅ Only add directory if it contains relevant files
            if (await _containsRelevantFiles(item, isVideoTab)) {
              return item;
            }
          } else if (item is File) {
            if (isVideoTab && isVideoFile(item.path)) {
              return item;
            }
            if (!isVideoTab && isAudioFile(item.path)) {
              return item;
            }
          }
        } catch (_) {}
        return null;
      }).toList();

      final results = await Future.wait(futures);
      return results.whereType<FileSystemEntity>().toList();
    } catch (e) {
      print("Directory access error: $e");
      return [];
    }
  }}