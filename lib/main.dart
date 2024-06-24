import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';

import 'dart:io';

import 'package:file_manager/file_manager.dart';
import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_manager/file_manager.dart';

import 'FF.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData(useMaterial3: true),
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  final FileManagerController controller = FileManagerController();
  final AudioPlayer audioPlayer = AudioPlayer(); // Initialize AudioPlayer

  @override
  Widget build(BuildContext context) {
    return ControlBackButton(
      controller: controller,
      child: Scaffold(
        appBar: appBar(context),
        body: FileManager(
          controller: controller,
          builder: (context, snapshot) {
            final List<FileSystemEntity> entities = snapshot;
            return ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 2, vertical: 0),
              itemCount: entities.length,
              itemBuilder: (context, index) {
                FileSystemEntity entity = entities[index];
                return Card(
                  child: ListTile(
                    leading: FileManager.isFile(entity)
                        ? Icon(Icons.feed_outlined)
                        : Icon(Icons.folder),
                    title: Text(FileManager.basename(
                      entity,
                      showFileExtension: true,
                    )),
                    subtitle: subtitle(entity),
                    onTap: () {
                      if (FileManager.isDirectory(entity)) {
                        controller.openDirectory(entity);
                      } else {
                        if (entity.path.endsWith('.mp3') || entity.path.endsWith('.wav')) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AudioPlayerScreen(filePath: entity.path),
                            ),
                          );
                        }
                      }
                    },

                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            FileManager.requestFilesAccessPermission();
            await Permission.storage.request();
            await Permission.manageExternalStorage.request();
          },
          label: Text("Request File Access Permission"),
        ),
      ),
    );
  }

  AppBar appBar(BuildContext context) {
    return AppBar(
      actions: [
        /*IconButton(
          onPressed: () => createFolder(context),
          icon: Icon(Icons.create_new_folder_outlined),
        ),*/
        IconButton(
          onPressed: () => sort(context),
          icon: Icon(Icons.sort_rounded),
        ),
        IconButton(
          onPressed: () => selectStorage(context),
          icon: Icon(Icons.sd_storage_rounded),
        )
      ],
      title: ValueListenableBuilder<String>(
        valueListenable: controller.titleNotifier,
        builder: (context, title, _) => Text(title),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () async {
          await controller.goToParentDirectory();
        },
      ),
    );
  }

  Widget subtitle(FileSystemEntity entity) {
    return FutureBuilder<FileStat>(
      future: entity.stat(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (entity is File) {
            int size = snapshot.data!.size;

            return Text(
              "${FileManager.formatBytes(size)}",
            );
          }
          return Text(
            "${snapshot.data!.modified}".substring(0, 10),
          );
        } else {
          return Text("");
        }
      },
    );
  }

  Future<void> selectStorage(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        child: FutureBuilder<List<Directory>>(
          future: FileManager.getStorageList(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final List<FileSystemEntity> storageList = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: storageList
                        .map((e) => ListTile(
                      title: Text(
                        "${FileManager.basename(e)}",
                      ),
                      onTap: () {
                        controller.openDirectory(e);
                        Navigator.pop(context);
                      },
                    ))
                        .toList()),
              );
            }
            return Dialog(
              child: CircularProgressIndicator(),
            );
          },
        ),
      ),
    );
  }

  sort(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                  title: Text("Name"),
                  onTap: () {
                    controller.sortBy(SortBy.name);
                    Navigator.pop(context);
                  }),
              ListTile(
                  title: Text("Size"),
                  onTap: () {
                    controller.sortBy(SortBy.size);
                    Navigator.pop(context);
                  }),
              ListTile(
                  title: Text("Date"),
                  onTap: () {
                    controller.sortBy(SortBy.date);
                    Navigator.pop(context);
                  }),
              ListTile(
                  title: Text("type"),
                  onTap: () {
                    controller.sortBy(SortBy.type);
                    Navigator.pop(context);
                  }),
            ],
          ),
        ),
      ),
    );
  }

 /* createFolder(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController folderName = TextEditingController();
        return Dialog(
          child: Container(
            padding: EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: TextField(
                    controller: folderName,
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      // Create Folder
                      await FileManager.createFolder(
                          controller.getCurrentPath, folderName.text);
                      // Open Created Folder
                      controller.setCurrentPath =
                          controller.getCurrentPath + "/" + folderName.text;
                    } catch (e) {}

                    Navigator.pop(context);
                  },
                  child: Text('Create Folder'),
                )
              ],
            ),
          ),
        );
      },
    );
  }*/
}






/*
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MusicPlayer(),
    );
  }
}

class MusicPlayer extends StatefulWidget {
  @override
  _MusicPlayerState createState() => _MusicPlayerState();
}

class _MusicPlayerState extends State<MusicPlayer> {
  final AudioPlayer _player = AudioPlayer();
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<SongModel> songs = [];
  List<Duration> marks = [];
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    PermissionStatus status = await Permission.storage.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      await _showPermissionDialog(status);
    } else {
      _loadSongs();
    }
  }

  Future<void> _showPermissionDialog(PermissionStatus status) async {
    if (status.isDenied) {
      // Show a dialog explaining why the app needs the permission and prompt to grant it
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Storage Permission Required'),
          content: Text('This app needs storage access to play music files. Please grant storage access.'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Grant Permission'),
              onPressed: () async {
                Navigator.of(context).pop();
                PermissionStatus newStatus = await Permission.storage.request();
                if (newStatus.isGranted) {
                  _loadSongs();
                } else {
                  _showPermissionDialog(newStatus);
                }
              },
            ),
          ],
        ),
      );
    } else if (status.isPermanentlyDenied) {
      // Show a dialog explaining that the user needs to go to settings to grant the permission
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Storage Permission Required'),
          content: Text('This app needs storage access to play music files. Please enable storage access in the app settings.'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            ),
          ],
        ),
      );
    }
  }

  Future<void> _loadSongs() async {
    List<SongModel> songs = await _audioQuery.querySongs();
    setState(() {
      this.songs = songs;
    });
  }

  void _playPause() {
    if (_player.playing) {
      _player.pause();
    } else {
      _player.play();
    }
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  void _seekForward() {
    _player.seek(_player.position + Duration(seconds: 3));
  }

  void _seekBackward() {
    _player.seek(_player.position - Duration(seconds: 3));
  }

  void _markPosition() {
    setState(() {
      marks.add(_player.position);
    });
  }

  void _playSong(SongModel song) async {
    await _player.setUrl(song.uri!);
    _player.play();
    setState(() {
      isPlaying = true;
      marks.clear();
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Music Player'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(songs[index].title),
                  onTap: () => _playSong(songs[index]),
                );
              },
            ),
          ),
          StreamBuilder<Duration>(
            stream: _player.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final duration = position.inSeconds;
              final minutes = (duration ~/ 60).toString().padLeft(2, '0');
              final seconds = (duration % 60).toString().padLeft(2, '0');
              return Text('$minutes:$seconds', style: TextStyle(fontSize: 40));
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButton(icon: Icon(Icons.replay_10), onPressed: _seekBackward),
              IconButton(
                icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: _playPause,
              ),
              IconButton(icon: Icon(Icons.forward_10), onPressed: _seekForward),
              IconButton(icon: Icon(Icons.flag), onPressed: _markPosition),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: marks.length,
              itemBuilder: (context, index) {
                final duration = marks[index];
                final minutes = (duration.inSeconds ~/ 60).toString().padLeft(2, '0');
                final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
                return ListTile(
                  title: Text('$minutes:$seconds'),
                  onTap: () {
                    _player.seek(marks[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
*/
