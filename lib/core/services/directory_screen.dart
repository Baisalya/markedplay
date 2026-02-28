import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/services/file_browser_service.dart';
import '../../core/theme_helper.dart';
import '../../core/app_settings_provider.dart';
import '../../widgets/local_video_thumbnail.dart';
import '../media_enums.dart';


class FolderPage extends StatefulWidget {
  final String path;
  final bool isVideoTab;
  final AppTheme theme;
  final AppSettingsProvider settings;

  const FolderPage({
    super.key,
    required this.path,
    required this.isVideoTab,
    required this.theme,
    required this.settings,
  });

  @override
  State<FolderPage> createState() => _FolderPageState();
}

class _FolderPageState extends State<FolderPage> {

  final _fileBrowserService = FileBrowserService();
  List<FileSystemEntity> items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result =
    await _fileBrowserService.loadDirectory(
      widget.path,
      widget.isVideoTab,
    );

    setState(() {
      items = result;
    });
  }

  @override
  @override
  Widget build(BuildContext context) {

    List<FileSystemEntity> sorted = List.from(items);

    if (widget.settings.sortMode == SortMode.name) {
      sorted.sort((a, b) =>
          a.path.split('/').last
              .compareTo(
              b.path.split('/').last));
    }

    return Scaffold(
      backgroundColor: ThemeHelper.background(
        widget.theme,
        customColor: widget.settings.customPrimary,
      ),
      appBar: AppBar(
        title: Text(
          widget.path.split('/').last,
        ),
        backgroundColor: ThemeHelper.primary(
          widget.theme,
          customColor: widget.settings.customPrimary,
        ),
      ),
      body: widget.settings.viewMode == ViewMode.list
          ? ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sorted.length,
        itemBuilder: (_, index) {

          final item = sorted[index];
          final name =
              item.path.split('/').last;

          return ListTile(
            leading: item is Directory
                ? const Icon(Icons.folder)
                : const Icon(Icons.insert_drive_file),
            title: Text(
              name,
              style: TextStyle(
                color: ThemeHelper.textPrimary(
                    widget.theme),
              ),
            ),
            onTap: () {
              if (item is Directory) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FolderPage(
                      path: item.path,
                      isVideoTab:
                      widget.isVideoTab,
                      theme: widget.theme,
                      settings:
                      widget.settings,
                    ),
                  ),
                );
              }
            },
          );
        },
      )
          : GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sorted.length,
        gridDelegate:
        const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemBuilder: (_, index) {

          final item = sorted[index];

          if (item is Directory) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FolderPage(
                      path: item.path,
                      isVideoTab:
                      widget.isVideoTab,
                      theme: widget.theme,
                      settings:
                      widget.settings,
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: ThemeHelper.cardColor(
                    widget.theme,
                    customColor:
                    widget.settings
                        .customPrimary,
                  ),
                  borderRadius:
                  BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    item.path
                        .split('/')
                        .last,
                    textAlign:
                    TextAlign.center,
                  ),
                ),
              ),
            );
          }

          if (_fileBrowserService
              .isVideoFile(item.path)) {
            return LocalVideoThumbnail(
              path: item.path,
            );
          }

          return const SizedBox();
        },
      ),
    );
  }}