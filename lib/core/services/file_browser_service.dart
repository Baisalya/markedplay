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

  Future<List<FileSystemEntity>> loadDirectory(
      String path,
      bool isVideoTab,
      ) async {
    try {
      final dir = Directory(path);

      if (!await dir.exists()) return [];

      final items = dir.listSync();

      List<FileSystemEntity> filtered = [];

      for (var item in items) {
        try {
          if (item is Directory) {
            // 🚫 Skip restricted Android folders
            if (item.path.contains("/Android/data") ||
                item.path.contains("/Android/obb")) {
              continue;
            }
            filtered.add(item);
          } else if (item is File) {
            if (isVideoTab && isVideoFile(item.path)) {
              filtered.add(item);
            }
            if (!isVideoTab && isAudioFile(item.path)) {
              filtered.add(item);
            }
          }
        } catch (_) {
          // Ignore individual item errors
        }
      }

      return filtered;
    } catch (e) {
      print("Directory access error: $e");
      return [];
    }
  }}