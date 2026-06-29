import 'package:shared_preferences/shared_preferences.dart';

enum PlaybackMediaType { audio, video }

class PlaybackPositionStore {
  const PlaybackPositionStore();

  String keyFor(String path, PlaybackMediaType type) => switch (type) {
        PlaybackMediaType.audio => 'audio_resume_$path',
        PlaybackMediaType.video => 'resume_$path',
      };

  Future<Duration?> load(String path, PlaybackMediaType type) async {
    final prefs = await SharedPreferences.getInstance();
    final seconds = prefs.getInt(keyFor(path, type));
    if (seconds == null || seconds <= 0) return null;
    return Duration(seconds: seconds);
  }

  Future<void> save(
    String path,
    PlaybackMediaType type,
    Duration position, {
    Duration? duration,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = keyFor(path, type);
    final isAtEnd = duration != null &&
        duration > Duration.zero &&
        position >= duration - const Duration(seconds: 5);

    if (position < const Duration(seconds: 2) || isAtEnd) {
      await prefs.remove(key);
      return;
    }
    await prefs.setInt(key, position.inSeconds);
  }

  Future<void> clear(String path, PlaybackMediaType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyFor(path, type));
  }
}
