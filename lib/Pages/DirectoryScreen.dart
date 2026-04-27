import 'dart:io';
import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:markedplay/Pages/videoplayer/Videoplayer.dart';
import 'package:provider/provider.dart';
import '../../core/services/file_browser_service.dart';
import '../../core/theme_helper.dart';
import '../../core/app_settings_provider.dart';
import '../../core/media_enums.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../widgets/local_video_thumbnail.dart';
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

  Future<void> _load({bool refresh = false}) async {
    if (refresh) {
      _fileBrowserService.clearCache();
    }

    if (items.isEmpty) {
      setState(() => isLoading = true);
    }

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
      backgroundColor: Colors.transparent,
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
                      IconButton(
                        icon: Icon(Icons.refresh,
                            color: ThemeHelper.primary(
                              theme,
                              customColor: settings.customPrimary,
                            )),
                        onPressed: () => _load(refresh: true),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: isLoading
                      ? const Center(
                      child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: () => _load(refresh: true),
                          child: settings.viewMode == ViewMode.list
                            ? _buildList(sorted, settings, theme)
                            : _buildGrid(sorted, settings, theme),
                      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: sorted.length,
      itemBuilder: (_, index) {

        final item = sorted[index];
        final name = item.path.split('/').last;
        final isFolder = item is Directory;
        final isVideo = !isFolder && _fileBrowserService.isVideoFile(item.path);
        final isAudio = !isFolder && _fileBrowserService.isAudioFile(item.path);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: ThemeHelper.cardColor(theme, customColor: settings.customPrimary).withOpacity(0.5),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: ThemeHelper.borderColor(theme, customColor: settings.customPrimary).withOpacity(0.1),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: SizedBox(
              width: 50,
              height: 50,
              child: isFolder
                  ? Icon(Icons.folder, size: 40, color: ThemeHelper.primary(theme, customColor: settings.customPrimary))
                  : isVideo
                      ? LocalVideoThumbnail(path: item.path)
                      : Container(
                          decoration: BoxDecoration(
                            color: ThemeHelper.primary(theme, customColor: settings.customPrimary).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.music_note, color: ThemeHelper.primary(theme, customColor: settings.customPrimary)),
                        ),
            ),
            title: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ThemeHelper.textPrimary(theme),
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: isFolder 
                ? null 
                : Text(
                    _getFileSize(item as File),
                    style: TextStyle(color: ThemeHelper.textSecondary(theme), fontSize: 12),
                  ),
            onTap: () => _handleTap(item),
          ),
        );
      },
    );
  }

  String _getFileSize(File file) {
    try {
      int bytes = file.lengthSync();
      if (bytes <= 0) return "0 B";
      const suffixes = ["B", "KB", "MB", "GB", "TB"];
      var i = (Math.log(bytes) / Math.log(1024)).floor();
      return ((bytes / Math.pow(1024, i)).toStringAsFixed(1)) + ' ' + suffixes[i];
    } catch (_) {
      return "";
    }
  }

  void _handleTap(FileSystemEntity item) {
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
      if (widget.isVideo && _fileBrowserService.isVideoFile(item.path)) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoPlayerScreen(filePath: item.path),
          ),
        );
      } else if (!widget.isVideo && _fileBrowserService.isAudioFile(item.path)) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AudioPlayerScreen(
              filePath: item.path,
              startPosition: Provider.of<AudioPlayerProvider>(context, listen: false).currentPosition,
            ),
          ),
        );
      }
    }
  }

  // ================= GRID VIEW =================

  Widget _buildGrid(
      List<FileSystemEntity> sorted,
      AppSettingsProvider settings,
      AppTheme theme) {

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (_, index) {

        final item = sorted[index];
        final name = item.path.split('/').last;
        final isFolder = item is Directory;
        final isVideo = !isFolder && _fileBrowserService.isVideoFile(item.path);

        return GestureDetector(
          onTap: () => _handleTap(item),
          child: Container(
            decoration: BoxDecoration(
              color: ThemeHelper.cardColor(theme, customColor: settings.customPrimary),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      color: ThemeHelper.primary(theme, customColor: settings.customPrimary).withOpacity(0.1),
                      child: isFolder
                          ? Icon(Icons.folder, size: 60, color: ThemeHelper.primary(theme, customColor: settings.customPrimary))
                          : isVideo
                              ? LocalVideoThumbnail(path: item.path)
                              : Icon(Icons.music_note, size: 60, color: ThemeHelper.primary(theme, customColor: settings.customPrimary)),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: ThemeHelper.textPrimary(theme),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!isFolder)
                             Text(
                              _getFileSize(item as File),
                              style: TextStyle(
                                color: ThemeHelper.textSecondary(theme),
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}