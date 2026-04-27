import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:file_manager/file_manager.dart';

import 'Pages/audio player/Audioplayer.dart';
import 'Pages/HomePage.dart';
import 'Pages/audio player/Audioplayerprovider.dart';
import 'Pages/videoplayer/Videoplayer.dart';
import 'core/app_settings_provider.dart';

import 'core/services/thumbnail_service.dart';

import 'package:audio_service/audio_service.dart';
import 'package:media_kit/media_kit.dart';
import 'Pages/audio player/AudioHandler.dart';

late MyAudioHandler _audioHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  
  _audioHandler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.passontaetech.markedplay.audio',
      androidNotificationChannelName: 'MarkedPlay Audio',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,
    ),
  );

  await ThumbnailService().init();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AudioPlayerProvider(_audioHandler)),
        ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: ThemeData(useMaterial3: true),
        darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
        home: HomePage(),
      ),
    );
  }
}




