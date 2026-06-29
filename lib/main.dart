import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'Pages/HomePage.dart';
import 'Pages/audio player/Audioplayerprovider.dart';
import 'Pages/videoplayer/VideoBackgroundProvider.dart';
import 'core/app_settings_provider.dart';
import 'core/media_enums.dart';
import 'core/theme_helper.dart';

import 'core/services/thumbnail_service.dart';

import 'package:audio_service/audio_service.dart';
import 'package:media_kit/media_kit.dart';
import 'Pages/audio player/AudioHandler.dart';

late MyAudioHandler _audioHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  final supportsAudioService =
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);
  _audioHandler = supportsAudioService
      ? await AudioService.init(
          builder: MyAudioHandler.new,
          config: const AudioServiceConfig(
            androidNotificationChannelId: 'com.passontaetech.markedplay.audio',
            androidNotificationChannelName: 'MarkedPlay Audio',
            androidNotificationOngoing: true,
            androidShowNotificationBadge: true,
          ),
        )
      : MyAudioHandler();

  final supportsThumbnailCache =
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);
  if (supportsThumbnailCache) {
    await ThumbnailService().init();
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => AudioPlayerProvider(_audioHandler)),
        ChangeNotifierProvider(
            create: (_) => VideoBackgroundProvider(_audioHandler)),
        ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
      ],
      child: Consumer<AppSettingsProvider>(
        builder: (context, settings, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'MarkedPlay',
          themeMode: settings.theme == AppTheme.minimal
              ? ThemeMode.light
              : ThemeMode.dark,
          theme: ThemeHelper.materialTheme(
            Brightness.light,
            settings.theme,
            customColor: settings.customPrimary,
          ),
          darkTheme: ThemeHelper.materialTheme(
            Brightness.dark,
            settings.theme,
            customColor: settings.customPrimary,
          ),
          home: const HomePage(),
        ),
      ),
    );
  }
}
