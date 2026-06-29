import 'dart:io';
import 'package:flutter/material.dart';
import 'package:markedplay/Pages/videoplayer/Videoplayer.dart';
import 'package:provider/provider.dart';
import '../../core/services/file_browser_service.dart';
import '../../core/theme_helper.dart';
import '../../core/app_settings_provider.dart';
import '../../core/media_enums.dart';
import 'audio player/Audioplayer.dart';
import '../core/ui/responsive/responsive_builder.dart';
import '../core/ui/widgets/mini_player_aware_padding.dart';
import '../widgets/modern_widgets.dart';

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
    final showHiddenFiles =
        Provider.of<AppSettingsProvider>(context, listen: false)
            .showHiddenFiles;
    if (refresh) {
      _fileBrowserService.clearCache();
    }
    if (items.isEmpty) {
      setState(() => isLoading = true);
    }
    final data = await _fileBrowserService.loadDirectory(
      widget.path,
      widget.isVideo,
      showHiddenFiles: showHiddenFiles,
    );
    if (!mounted) return;
    setState(() {
      items = data;
      isLoading = false;
    });
  }

  void _openFile(String path) {
    if (widget.isVideo) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => VideoPlayerScreen(playlist: [path])));
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => AudioPlayerScreen(
                  filePath: path, startPosition: Duration.zero)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    final theme = settings.theme;
    List<FileSystemEntity> sorted = List.from(items);
    if (settings.sortMode == SortMode.name) {
      sorted.sort((a, b) => a.path
          .split('/')
          .last
          .toLowerCase()
          .compareTo(b.path.split('/').last.toLowerCase()));
    }

    final appBarColor =
        ThemeHelper.appBarColor(theme, customColor: settings.customPrimary);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.path.split('/').last,
          style: TextStyle(
              color: ThemeHelper.textPrimary(theme),
              fontSize: 20,
              fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(
            color: ThemeHelper.primary(theme,
                customColor: settings.customPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _load(refresh: true),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: ThemeHelper.backgroundGradient(theme,
                  customColor: settings.customPrimary),
            ),
          ),
          MiniPlayerAwarePadding(
            child: SafeArea(
              child: isLoading
                  ? const LoadingStateWidget(label: 'Opening folder…')
                  : sorted.isEmpty
                      ? EmptyStateWidget(
                          icon: Icons.folder_open_rounded,
                          title: 'No playable media here',
                          subtitle:
                              'This folder does not contain a supported ${widget.isVideo ? 'video' : 'audio'} file.',
                          buttonText: 'Check again',
                          onButtonPressed: () => _load(refresh: true),
                        )
                      : RefreshIndicator(
                          onRefresh: () => _load(refresh: true),
                          child: settings.viewMode == ViewMode.list
                              ? _buildList(sorted, settings, theme)
                              : _buildResponsiveGrid(sorted, settings, theme),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<FileSystemEntity> sorted, AppSettingsProvider settings,
      AppTheme theme) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: sorted.length,
          itemBuilder: (_, index) {
            final item = sorted[index];
            final name = item.path.split('/').last;
            return ListTile(
              leading: Icon(
                  item is Directory
                      ? Icons.folder_rounded
                      : (widget.isVideo
                          ? Icons.movie_creation_rounded
                          : Icons.audiotrack_rounded),
                  color: ThemeHelper.primary(theme,
                      customColor: settings.customPrimary)),
              title: Text(name,
                  style: TextStyle(
                      color: ThemeHelper.textPrimary(theme),
                      fontWeight: FontWeight.w600)),
              onTap: () {
                if (item is Directory) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => DirectoryScreen(
                              path: item.path, isVideo: widget.isVideo)));
                } else {
                  _openFile(item.path);
                }
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildResponsiveGrid(List<FileSystemEntity> sorted,
      AppSettingsProvider settings, AppTheme theme) {
    return ResponsiveBuilder(
      compact: (context, constraints) => _buildGrid(sorted, settings, theme, 2),
      medium: (context, constraints) => _buildGrid(sorted, settings, theme, 3),
      expanded: (context, constraints) =>
          _buildGrid(sorted, settings, theme, 5),
    );
  }

  Widget _buildGrid(List<FileSystemEntity> sorted, AppSettingsProvider settings,
      AppTheme theme, int crossAxisCount) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: sorted.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20),
      itemBuilder: (context, index) {
        final item = sorted[index];
        final name = item.path.split('/').last;
        return GestureDetector(
          onTap: () {
            if (item is Directory) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => DirectoryScreen(
                          path: item.path, isVideo: widget.isVideo)));
            } else {
              _openFile(item.path);
            }
          },
          child: GlassCard(
            borderRadius: 25,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                    item is Directory
                        ? Icons.folder_rounded
                        : (widget.isVideo
                            ? Icons.movie_creation_rounded
                            : Icons.audiotrack_rounded),
                    size: 48,
                    color: ThemeHelper.primary(theme,
                        customColor: settings.customPrimary)),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ThemeHelper.textPrimary(theme),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
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
