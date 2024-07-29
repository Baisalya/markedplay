import 'dart:io';

import 'package:file_manager/file_manager.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../Audioplayer.dart';
import 'videoplayer/Videoplayer.dart';
import '../controller/FileManagerController.dart';


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FilemanagerController fileManagerController = FilemanagerController();
  int _selectedIndex = 0;
  bool isGridView = false;

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
        FilemanagerController.requestFilesAccessPermission();
      },
      label: Text("Request File Access Permission"),
    );
  }

  Future<void> _selectStorage(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        child: FutureBuilder<List<Directory>>(
          future: FilemanagerController.getStorageList(),
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
                          fileManagerController.openDirectory(e);
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
                    fileManagerController.sortBy(SortBy.name);
                    Navigator.pop(context);
                  }),
              ListTile(
                  title: Text("Size"),
                  onTap: () {
                    fileManagerController.sortBy(SortBy.size);
                    Navigator.pop(context);
                  }),
              ListTile(
                  title: Text("Date"),
                  onTap: () {
                    fileManagerController.sortBy(SortBy.date);
                    Navigator.pop(context);
                  }),
              ListTile(
                  title: Text("Type"),
                  onTap: () {
                    fileManagerController.sortBy(SortBy.type);
                    Navigator.pop(context);
                  }),
            ],
          ),
        ),
      ),
    );
  }
}
