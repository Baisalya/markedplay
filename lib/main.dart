import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';
import 'package:file_manager/file_manager.dart';

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

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FileManagerController controller = FileManagerController();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              if (_selectedIndex == 0 && (entity.path.endsWith('.mp4') || entity.path.endsWith('.avi'))) {
                // Show only video files
                return fileListItem(entity);
              } else if (_selectedIndex == 1 && (entity.path.endsWith('.mp3') || entity.path.endsWith('.wav'))) {
                // Show only audio files
                return fileListItem(entity);
              } else if (FileManager.isDirectory(entity)) {
                // Show directories
                return fileListItem(entity);
              } else {
                return Container(); // Hide other files
              }
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: 'Videos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            label: 'Music',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
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
    );
  }

  AppBar appBar(BuildContext context) {
    return AppBar(
      actions: [
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

  Widget fileListItem(FileSystemEntity entity) {
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
            } else if (entity.path.endsWith('.mp4') || entity.path.endsWith('.avi')) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoPlayerScreen(filePath: entity.path),
                ),
              );
            }
          }
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
}

class AudioPlayerScreen extends StatefulWidget {
  final String filePath;

  AudioPlayerScreen({required this.filePath});

  @override
  _AudioPlayerScreenState createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final AudioPlayer audioPlayer = AudioPlayer();
  bool isPlaying = false;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;
  List<Duration> marks = [];

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      setState(() {
        isPlaying = state == PlayerState.playing;
      });
    });

    audioPlayer.onPositionChanged.listen((Duration position) {
      setState(() {
        currentPosition = position;
      });
    });

    audioPlayer.onDurationChanged.listen((Duration duration) {
      setState(() {
        totalDuration = duration;
      });
    });

    _playAudio();
  }

  Future<void> _playAudio() async {
    try {
      await audioPlayer.play(DeviceFileSource(widget.filePath));
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  Future<void> _pauseAudio() async {
    try {
      await audioPlayer.pause();
    } catch (e) {
      print('Error pausing audio: $e');
    }
  }

  Future<void> _seekAudio(Duration position) async {
    try {
      await audioPlayer.seek(position);
    } catch (e) {
      print('Error seeking audio: $e');
    }
  }

  void _markPosition() {
    setState(() {
      marks.add(currentPosition);
    });
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Audio Player'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${currentPosition.toString().split('.').first} / ${totalDuration.toString().split('.').first}',
              style: TextStyle(fontSize: 24),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.replay_10),
                  onPressed: () => _seekAudio(currentPosition - Duration(seconds: 10)),
                ),
                IconButton(
                  icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: isPlaying ? _pauseAudio : _playAudio,
                ),
                IconButton(
                  icon: Icon(Icons.forward_10),
                  onPressed: () => _seekAudio(currentPosition + Duration(seconds: 10)),
                ),
                IconButton(
                  icon: Icon(Icons.flag),
                  onPressed: _markPosition,
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: marks.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(marks[index].toString().split('.').first),
                    onTap: () => _seekAudio(marks[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String filePath;

  VideoPlayerScreen({required this.filePath});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.filePath))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Player'),
      ),
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        )
            : CircularProgressIndicator(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _controller.value.isPlaying ? _controller.pause() : _controller.play();
          });
        },
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}
