import 'dart:io';

import 'package:file_manager/file_manager.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../Audioplayer.dart';
import 'videoplayer/Videoplayer.dart';
import '../controller/FileManagerController.dart';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_manager/file_manager.dart';
import 'package:permission_handler/permission_handler.dart';
class FilemanagerController {
  final ValueNotifier<String> titleNotifier = ValueNotifier<String>("Home");
  final FileManagerController _fileManagerController = FileManagerController();

  ValueNotifier<String> get title => titleNotifier;

  FileManagerController get controller => _fileManagerController;

  void openDirectory(FileSystemEntity entity) {
    _fileManagerController.openDirectory(entity);
  }

  Future<void> goToParentDirectory() async {
    await _fileManagerController.goToParentDirectory();
  }

  void sortBy(SortBy sortBy) {
    _fileManagerController.sortBy(sortBy);
  }

  static Future<List<Directory>> getStorageList() async {
    return FileManager.getStorageList();
  }

  static Future<bool> requestFilesAccessPermission() async {
    var storageStatus = await Permission.storage.request();
    var manageStorageStatus = await Permission.manageExternalStorage.request();
    return storageStatus.isGranted && manageStorageStatus.isGranted;
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FilemanagerController fileManagerController = FilemanagerController();
  int _selectedIndex = 0;
  bool isGridView = false;
  bool hasFileAccessPermission = false;
  String? lastPlayedVideoPath;
  String? lastPlayedMusicPath;

  @override
  void initState() {
    super.initState();
    _checkFileAccessPermission();
  }

  Future<void> _checkFileAccessPermission() async {
    bool granted = await FilemanagerController.requestFilesAccessPermission();
    setState(() {
      hasFileAccessPermission = granted;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(context),
      body: Stack(
        children: [
          _buildFileManager(),
          Align(
            alignment: Alignment.bottomCenter,
            child: MiniPlayer(), // Add the MiniPlayer here
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(), // This is placed above MiniPlayer
    );
  }


  AppBar _appBar(BuildContext context) {
    return AppBar(
      actions: [
        IconButton(
          onPressed: () => _sortFiles(context),
          icon: Icon(Icons.sort_rounded),
        ),
        IconButton(
          onPressed: () => _selectStorage(context),
          icon: Icon(Icons.sd_storage_rounded),
        ),
        if (hasFileAccessPermission) // Add this line
          IconButton(
            onPressed: () {
              // Handle permission-related action
            },
            icon: Icon(Icons.check_circle), // Use an appropriate icon
          ),
        PopupMenuButton<String>(
          onSelected: (value) {
            setState(() {
              isGridView = value == 'Grid View';
            });
          },
          itemBuilder: (BuildContext context) {
            return {'List View', 'Grid View'}.map((String choice) {
              return PopupMenuItem<String>(
                value: choice,
                child: Text(choice),
              );
            }).toList();
          },
        ),
      ],
      title: ValueListenableBuilder<String>(
        valueListenable: fileManagerController.title,
        builder: (context, title, _) => Text(title),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () async {
          await fileManagerController.goToParentDirectory();
        },
      ),
    );
  }

  Widget _buildFileManager() {
    return FileManager(
      controller: fileManagerController.controller,
      builder: (context, snapshot) {
        final List<FileSystemEntity> entities = snapshot;
        final List<FileSystemEntity> filteredEntities = _filterEntities(entities);

        return isGridView ? _buildGridView(filteredEntities) : _buildListView(filteredEntities);
      },
    );
  }

  List<FileSystemEntity> _filterEntities(List<FileSystemEntity> entities) {
    return entities.where((entity) {
      if (FileManager.isDirectory(entity)) {
        final directory = Directory(entity.path);
        final List<FileSystemEntity> files = directory.listSync();
        return files.any((file) {
          if (_selectedIndex == 0) {
            return file.path.endsWith('.mp4') || file.path.endsWith('.avi');
          } else {
            return file.path.endsWith('.mp3') || file.path.endsWith('.wav');
          }
        });
      } else {
        if (_selectedIndex == 0) {
          return entity.path.endsWith('.mp4') || entity.path.endsWith('.avi');
        } else {
          return entity.path.endsWith('.mp3') || entity.path.endsWith('.wav');
        }
      }
    }).toList();
  }

  Widget _buildListView(List<FileSystemEntity> entities) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 2, vertical: 0),
      itemCount: entities.length,
      itemBuilder: (context, index) {
        return _fileListItem(entities[index]);
      },
    );
  }

  Widget _buildGridView(List<FileSystemEntity> entities) {
    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 2, vertical: 0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
      itemCount: entities.length,
      itemBuilder: (context, index) {
        return _fileGridItem(entities[index]);
      },
    );
  }

  Widget _fileListItem(FileSystemEntity entity) {
    return Card(
      child: ListTile(
        leading: _buildThumbnail(entity),
        title: Text(FileManager.basename(entity, showFileExtension: true)),
        subtitle: _buildSubtitle(entity),
        onTap: () => _onFileTap(entity),
      ),
    );
  }

  Widget _fileGridItem(FileSystemEntity entity) {
    return Card(
      child: InkWell(
        onTap: () => _onFileTap(entity),
        child: GridTile(
          child: _buildThumbnail(entity),
          footer: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              FileManager.basename(entity, showFileExtension: true),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(FileSystemEntity entity) {
    if (FileManager.isDirectory(entity)) {
      return Icon(Icons.folder);
    } else {
      return Icon(entity.path.endsWith('.mp3') || entity.path.endsWith('.wav')
          ? Icons.music_note
          : Icons.video_library);
    }
  }

  Widget _buildSubtitle(FileSystemEntity entity) {
    return FutureBuilder<FileStat>(
      future: entity.stat(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (entity is File) {
            int size = snapshot.data!.size;
            return Text("${FileManager.formatBytes(size)}");
          }
          return Text("${snapshot.data!.modified}".substring(0, 10));
        } else {
          return Text("");
        }
      },
    );
  }

  void _onFileTap(FileSystemEntity entity) {
    if (FileManager.isDirectory(entity)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        fileManagerController.openDirectory(entity);
      });
    } else {
      if (entity.path.endsWith('.mp3') || entity.path.endsWith('.wav')) {
        lastPlayedMusicPath = entity.path;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AudioPlayerScreen(filePath: entity.path),
          ),
        );
      } else if (entity.path.endsWith('.mp4') || entity.path.endsWith('.avi')) {
        lastPlayedVideoPath = entity.path;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerScreen(filePath: entity.path),
          ),
        );
      }
    }
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
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
    );
  }

  FloatingActionButton _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        if (_selectedIndex == 0 && lastPlayedVideoPath != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPlayerScreen(filePath: lastPlayedVideoPath!),
            ),
          );
        } else if (_selectedIndex == 1 && lastPlayedMusicPath != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AudioPlayerScreen(filePath: lastPlayedMusicPath!),
            ),
          );
        }
      },
      child: Icon(Icons.play_arrow),
    );
  }

  Future<void> _selectStorage(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Container(
            width: double.maxFinite,
            height: 200,
            child: FutureBuilder<List<Directory>>(
              future: FilemanagerController.getStorageList(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: snapshot.data?.length ?? 0,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(snapshot.data![index].path),
                        onTap: () {
                          fileManagerController.openDirectory(snapshot.data![index]);
                          Navigator.pop(context);
                        },
                      );
                    },
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _sortFiles(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text("By Name"),
                  onTap: () {
                    fileManagerController.sortBy(SortBy.name);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: Text("By Date"),
                  onTap: () {
                    fileManagerController.sortBy(SortBy.date);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: Text("By Size"),
                  onTap: () {
                    fileManagerController.sortBy(SortBy.size);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
