import 'dart:io';
import 'package:flutter/material.dart';
import 'package:markedplay/Pages/videoplayer/Videoplayer.dart';
import '../../core/services/file_browser_service.dart';
import '../../core/theme_helper.dart';
import '../../core/app_settings_provider.dart';
import '../../core/media_enums.dart';
import 'package:provider/provider.dart';

import 'audio player/Audioplayer.dart';
import 'audio player/Audioplayerprovider.dart';

class DirectoryScreen extends StatefulWidget {
  final String path;
  final bool isVideo;

  const DirectoryScreen({
    super.key,
    required this.path,
    required this.isVideo,
  });

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {

  final _fileBrowserService = FileBrowserService();

  List<FileSystemEntity> items = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _fileBrowserService.loadDirectory(
      widget.path,
      widget.isVideo,
    );

    if (!mounted) return;

    setState(() {
      items = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    final settings = context.watch<AppSettingsProvider>();
    final theme = settings.theme;

    final primaryColor = ThemeHelper.primary(
      theme,
      customColor: settings.customPrimary,
    );

    final backgroundColor = ThemeHelper.background(
      theme,
      customColor: settings.customPrimary,
    );

    // ✅ Apply Sorting
    List<FileSystemEntity> sorted = List.from(items);

    if (settings.sortMode == SortMode.name) {
      sorted.sort((a, b) =>
          a.path.split('/').last
              .toLowerCase()
              .compareTo(
              b.path.split('/').last.toLowerCase()));
    }

     return Scaffold(
      backgroundColor: backgroundColor,
      extendBody: true,
      body: Stack(
        children: [

          // ✅ Same Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: ThemeHelper.backgroundGradient(
                theme,
                customColor: settings.customPrimary,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [

                // ✅ Custom Top Bar (same style as HomePage)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back,
                            color: ThemeHelper.primary(
                              theme,
                              customColor: settings.customPrimary,
                            )),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          widget.path.split('/').last,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: ThemeHelper.textPrimary(theme),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // balance back button
                    ],
                  ),
                ),

                Expanded(
                  child: isLoading
                      ? const Center(
                      child: CircularProgressIndicator())
                      : settings.viewMode == ViewMode.list
                      ? _buildList(sorted, settings, theme)
                      : _buildGrid(sorted, settings, theme),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= LIST VIEW =================

  Widget _buildList(
      List<FileSystemEntity> sorted,
      AppSettingsProvider settings,
      AppTheme theme) {

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (_, index) {

        final item = sorted[index];
        final name = item.path.split('/').last;

        return ListTile(
          leading: Icon(
            item is Directory
                ? Icons.folder
                : Icons.insert_drive_file,
            color: ThemeHelper.primary(
              theme,
              customColor: settings.customPrimary,
            ),
          ),
          title: Text(
            name,
            style: TextStyle(
              color: ThemeHelper.textPrimary(theme),
            ),
          ),
            onTap: () {
              if (item is Directory) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DirectoryScreen(
                      path: item.path,
                      isVideo: widget.isVideo,
                    ),
                  ),
                );
              } else {
                if (widget.isVideo &&
                    _fileBrowserService.isVideoFile(item.path)) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VideoPlayerScreen(
                        filePath: item.path,
                      ),
                    ),
                  );
                }

                if (!widget.isVideo &&
                    _fileBrowserService.isAudioFile(item.path)) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AudioPlayerScreen(
                        filePath: item.path,
                        startPosition:
                        Provider.of<AudioPlayerProvider>(
                          context,
                          listen: false,
                        ).currentPosition,
                      ),
                    ),
                  );
                }
              }
            },        );
      },
    );
  }

  // ================= GRID VIEW =================

  Widget _buildGrid(
      List<FileSystemEntity> sorted,
      AppSettingsProvider settings,
      AppTheme theme) {

    return GridView.builder(
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
        final name = item.path.split('/').last;

        return GestureDetector(
          onTap: () {
            if (item is Directory) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DirectoryScreen(
                    path: item.path,
                    isVideo: widget.isVideo,
                  ),
                ),
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: ThemeHelper.cardColor(
                theme,
                customColor: settings.customPrimary,
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item is Directory
                      ? Icons.folder
                      : Icons.insert_drive_file,
                  size: 40,
                  color: ThemeHelper.primary(
                    theme,
                    customColor: settings.customPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:
                      ThemeHelper.textPrimary(theme),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}