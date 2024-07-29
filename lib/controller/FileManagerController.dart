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

  static Future<void> requestFilesAccessPermission() async {
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();
  }
}
