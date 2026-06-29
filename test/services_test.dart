import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:markedplay/core/services/file_browser_service.dart';
import 'package:markedplay/core/services/playback_position_store.dart';
import 'package:markedplay/core/app_settings_provider.dart';
import 'package:markedplay/core/media_enums.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FileBrowserService', () {
    final service = FileBrowserService();

    test('recognizes supported media extensions case-insensitively', () {
      expect(service.isVideoFile(r'C:\Media\Movie.MKV'), isTrue);
      expect(service.isVideoFile('/media/clip.m4v'), isTrue);
      expect(service.isAudioFile('/media/song.OPUS'), isTrue);
      expect(service.isAudioFile('/media/notes.txt'), isFalse);
    });
  });

  group('PlaybackPositionStore', () {
    const store = PlaybackPositionStore();

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('stores audio positions under a separate compatible key', () async {
      await store.save(
        '/music/song.mp3',
        PlaybackMediaType.audio,
        const Duration(seconds: 42),
        duration: const Duration(minutes: 3),
      );

      expect(
        await store.load('/music/song.mp3', PlaybackMediaType.audio),
        const Duration(seconds: 42),
      );
      expect(
        store.keyFor('/video/movie.mp4', PlaybackMediaType.video),
        'resume_/video/movie.mp4',
      );
    });

    test('clears positions near the end instead of resuming credits', () async {
      await store.save(
        '/video/movie.mp4',
        PlaybackMediaType.video,
        const Duration(seconds: 98),
        duration: const Duration(seconds: 100),
      );

      expect(
        await store.load('/video/movie.mp4', PlaybackMediaType.video),
        isNull,
      );
    });
  });

  test('corrupted enum preferences fall back to safe defaults', () async {
    SharedPreferences.setMockInitialValues({
      'theme': 999,
      'viewMode': -4,
      'repeatMode': 999,
    });
    final settings = AppSettingsProvider();
    await Future<void>.delayed(Duration.zero);

    expect(settings.theme, AppTheme.neon);
    expect(settings.viewMode, ViewMode.grid);
    expect(settings.repeatMode, RepeatMode.off);
    settings.dispose();
  });
}
