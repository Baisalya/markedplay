import 'dart:io';

import 'package:flutter/material.dart';
import 'package:markedplay/widgets/modern_widgets.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

import '../../core/app_settings_provider.dart';
import '../../core/media_enums.dart';
import '../../core/theme_helper.dart';
import '../../widgets/local_video_thumbnail.dart';
import 'Videoplayer.dart';

class _ResolvedVideoPlaylist {
  final List<String> paths;
  final int initialIndex;

  const _ResolvedVideoPlaylist(this.paths, this.initialIndex);
}

Future<_ResolvedVideoPlaylist> _resolvePlaylistWindow(
  List<AssetEntity> assets,
  int targetIndex,
) async {
  const windowRadius = 100;
  final start = assets.length <= windowRadius * 2 + 1
      ? 0
      : (targetIndex - windowRadius)
          .clamp(
            0,
            assets.length - (windowRadius * 2 + 1),
          )
          .toInt();
  final end = assets.length <= windowRadius * 2 + 1
      ? assets.length
      : start + windowRadius * 2 + 1;
  final window = assets.sublist(start, end);
  final files = await Future.wait(window.map((asset) => asset.file));
  final targetId = assets[targetIndex].id;
  final paths = <String>[];
  var resolvedTargetIndex = -1;
  for (var index = 0; index < files.length; index++) {
    final file = files[index];
    if (file == null) continue;
    if (window[index].id == targetId) resolvedTargetIndex = paths.length;
    paths.add(file.path);
  }
  return _ResolvedVideoPlaylist(paths, resolvedTargetIndex);
}

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

    final backgroundColor = ThemeHelper.background(
      theme,
      customColor: settings.customPrimary,
    );
    final textPrimary = ThemeHelper.textPrimary(theme);

    final sortedVideos = [...videos];

    // 🔥 Global Sorting
    switch (settings.sortMode) {
      case SortMode.name:
        sortedVideos.sort(
          (a, b) => (a.title ?? '')
              .toLowerCase()
              .compareTo((b.title ?? '').toLowerCase()),
        );
      case SortMode.date:
        sortedVideos.sort(
          (a, b) => b.createDateTime.compareTo(a.createDateTime),
        );
      case SortMode.duration:
        sortedVideos.sort((a, b) => b.duration.compareTo(a.duration));
      case SortMode.size:
        sortedVideos.sort(
          (a, b) => (b.width * b.height).compareTo(a.width * a.height),
        );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: GlassCard(
              borderRadius: 20,
              blur: 20,
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded,
                          color: textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        folderName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: ThemeHelper.backgroundGradient(theme,
                  customColor: settings.customPrimary),
            ),
          ),
          SafeArea(
            child: sortedVideos.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.video_library_outlined,
                    title: 'No videos in this folder',
                    subtitle: 'Pull down on the library screen to scan again.',
                  )
                : settings.viewMode == ViewMode.list
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
          ),
        ],
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
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.05,
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
            trailing: IconButton(
              tooltip: widget.settings.favorites.contains(file?.path)
                  ? 'Remove favorite'
                  : 'Add favorite',
              icon: Icon(
                widget.settings.favorites.contains(file?.path)
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
              ),
              onPressed: file == null
                  ? null
                  : () => widget.settings.toggleFavorite(file.path),
            ),
            onTap: file == null
                ? null
                : () async {
                    final resolved = await _resolvePlaylistWindow(
                      widget.playlist,
                      widget.initialIndex,
                    );

                    if (context.mounted && resolved.initialIndex >= 0) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VideoPlayerScreen(
                            playlist: resolved.paths,
                            initialIndex: resolved.initialIndex,
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
                  final resolved = await _resolvePlaylistWindow(
                    widget.playlist,
                    widget.initialIndex,
                  );

                  if (context.mounted && resolved.initialIndex >= 0) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VideoPlayerScreen(
                          playlist: resolved.paths,
                          initialIndex: resolved.initialIndex,
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
                  padding: const EdgeInsets.fromLTRB(10, 2, 2, 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.video.title ?? "Video",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ThemeHelper.textPrimary(widget.theme),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: widget.settings.favorites.contains(file?.path)
                            ? 'Remove favorite'
                            : 'Add favorite',
                        icon: Icon(
                          widget.settings.favorites.contains(file?.path)
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 20,
                        ),
                        onPressed: file == null
                            ? null
                            : () => widget.settings.toggleFavorite(file.path),
                      ),
                    ],
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
