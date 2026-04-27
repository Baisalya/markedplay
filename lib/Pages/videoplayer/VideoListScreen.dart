import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

import '../../core/app_settings_provider.dart';
import '../../core/media_enums.dart';
import '../../core/theme_helper.dart';
import '../../widgets/local_video_thumbnail.dart';
import 'Videoplayer.dart';

class VideoListScreen extends StatelessWidget {
  final String folderName;
  final List<AssetEntity> videos;

  const VideoListScreen({
    super.key,
    required this.folderName,
    required this.videos,
  });

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

    final sortedVideos = [...videos];

    // 🔥 Global Sorting
    if (settings.sortMode == SortMode.name) {
      sortedVideos.sort(
            (a, b) => (a.title ?? "")
            .compareTo(b.title ?? ""),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        backgroundColor: ThemeHelper.appBarColor(
          theme,
          customColor: settings.customPrimary,
        ),
        elevation: 0,
        centerTitle: true,
        title: Text(
          folderName,
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        iconTheme: IconThemeData(
          color: primaryColor,
        ),
      ),

      body: settings.viewMode == ViewMode.list
          ? _buildListView(
        context,
        sortedVideos,
        theme,
        settings,
      )
          : _buildGridView(
        context,
        sortedVideos,
        theme,
        settings,
      ),
    );
  }

  // ================= LIST VIEW =================

  Widget _buildListView(
    BuildContext context,
    List<AssetEntity> videos,
    AppTheme theme,
    AppSettingsProvider settings,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: videos.length,
      itemBuilder: (_, index) {
        final video = videos[index];
        return _VideoListItem(
          key: ValueKey(video.id),
          video: video,
          theme: theme,
          settings: settings,
          playlist: videos,
          initialIndex: index,
        );
      },
    );
  }

  // ================= GRID VIEW =================

  Widget _buildGridView(
    BuildContext context,
    List<AssetEntity> videos,
    AppTheme theme,
    AppSettingsProvider settings,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: videos.length,
      itemBuilder: (_, index) {
        final video = videos[index];
        return _VideoGridItem(
          key: ValueKey(video.id),
          video: video,
          theme: theme,
          settings: settings,
          playlist: videos,
          initialIndex: index,
        );
      },
    );
  }
}

class _VideoListItem extends StatefulWidget {
  final AssetEntity video;
  final AppTheme theme;
  final AppSettingsProvider settings;
  final List<AssetEntity> playlist;
  final int initialIndex;

  const _VideoListItem({
    super.key,
    required this.video,
    required this.theme,
    required this.settings,
    required this.playlist,
    required this.initialIndex,
  });

  @override
  State<_VideoListItem> createState() => _VideoListItemState();
}

class _VideoListItemState extends State<_VideoListItem> {
  Future<File?>? _fileFuture;

  @override
  void initState() {
    super.initState();
    _fileFuture = widget.video.file;
  }

  @override
  void didUpdateWidget(covariant _VideoListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.video.id != widget.video.id) {
      _fileFuture = widget.video.file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: _fileFuture,
      builder: (context, snapshot) {
        final file = snapshot.data;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: ThemeHelper.cardColor(
              widget.theme,
              customColor: widget.settings.customPrimary,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ThemeHelper.borderColor(
                widget.theme,
                customColor: widget.settings.customPrimary,
              ),
            ),
          ),
          child: ListTile(
            leading: file == null
                ? Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      ),
                    ),
                  )
                : LocalVideoThumbnail(
                    path: file.path,
                    width: 50,
                    height: 50,
                  ),
            title: Text(
              widget.video.title ?? "Video",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ThemeHelper.textPrimary(widget.theme),
              ),
            ),
            onTap: file == null
                ? null
                : () async {
                    final playlistFiles = await Future.wait(
                      widget.playlist.map((e) => e.file),
                    );
                    final validPlaylist = playlistFiles
                        .where((f) => f != null)
                        .map((f) => f!.path)
                        .toList();

                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VideoPlayerScreen(
                            playlist: validPlaylist,
                            initialIndex: widget.initialIndex,
                          ),
                        ),
                      );
                    }
                  },
          ),
        );
      },
    );
  }
}

class _VideoGridItem extends StatefulWidget {
  final AssetEntity video;
  final AppTheme theme;
  final AppSettingsProvider settings;
  final List<AssetEntity> playlist;
  final int initialIndex;

  const _VideoGridItem({
    super.key,
    required this.video,
    required this.theme,
    required this.settings,
    required this.playlist,
    required this.initialIndex,
  });

  @override
  State<_VideoGridItem> createState() => _VideoGridItemState();
}

class _VideoGridItemState extends State<_VideoGridItem> {
  Future<File?>? _fileFuture;

  @override
  void initState() {
    super.initState();
    _fileFuture = widget.video.file;
  }

  @override
  void didUpdateWidget(covariant _VideoGridItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.video.id != widget.video.id) {
      _fileFuture = widget.video.file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: _fileFuture,
      builder: (context, snapshot) {
        final file = snapshot.data;

        return GestureDetector(
          onTap: file == null
              ? null
              : () async {
                  final playlistFiles = await Future.wait(
                    widget.playlist.map((e) => e.file),
                  );
                  final validPlaylist = playlistFiles
                      .where((f) => f != null)
                      .map((f) => f!.path)
                      .toList();

                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VideoPlayerScreen(
                          playlist: validPlaylist,
                          initialIndex: widget.initialIndex,
                        ),
                      ),
                    );
                  }
                },
          child: Container(
            decoration: BoxDecoration(
              color: ThemeHelper.cardColor(
                widget.theme,
                customColor: widget.settings.customPrimary,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: ThemeHelper.borderColor(
                  widget.theme,
                  customColor: widget.settings.customPrimary,
                ),
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: file == null
                      ? Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      : LocalVideoThumbnail(path: file.path),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    widget.video.title ?? "Video",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ThemeHelper.textPrimary(widget.theme),
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
