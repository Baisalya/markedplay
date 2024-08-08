import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:file_manager/file_manager.dart';

import 'Audioplayer.dart';
import 'Pages/HomePage.dart';
import 'Pages/videoplayer/Videoplayer.dart';

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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AudioPlayerProvider()),
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
/*class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FileManagerController controller = FileManagerController();
  int _selectedIndex = 0;
  bool isGridView = false;
  late final List<String> filePaths;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(context),
      body: _buildFileManager(),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
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

  Widget _buildFileManager() {
    return FileManager(
      controller: controller,
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
        controller.openDirectory(entity);
      });
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
    return FloatingActionButton.extended(
      onPressed: () async {
        FileManager.requestFilesAccessPermission();
        await Permission.storage.request();
        await Permission.manageExternalStorage.request();
      },
      label: Text("Request File Access Permission"),
    );
  }

  Future<void> _selectStorage(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        child: FutureBuilder<List<Directory>>(
          future: FileManager.getStorageList(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasData) {
                final List<FileSystemEntity> storageList = snapshot.data!;
                return Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: storageList.map((e) => ListTile(
                      title: Text("${FileManager.basename(e)}"),
                      onTap: () {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          controller.openDirectory(e);
                          Navigator.pop(context);
                        });
                      },
                    )).toList(),
                  ),
                );
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
            }
            return Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }



  Future<void> _sortFiles(BuildContext context) async {
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
                  title: Text("Type"),
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
}*/




