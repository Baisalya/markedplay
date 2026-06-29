import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import '../core/app_settings_provider.dart';
import '../core/theme_helper.dart';
import 'modern_widgets.dart';

class MediaSearchDelegate extends SearchDelegate {
  final List<SongModel> songs;
  final Function(String) onFileTap;

  MediaSearchDelegate({required this.songs, required this.onFileTap});

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildList();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildList();
  }

  Widget _buildList() {
    final results = songs
        .where((s) =>
            s.title.toLowerCase().contains(query.toLowerCase()) ||
            (s.artist?.toLowerCase().contains(query.toLowerCase()) ?? false))
        .toList();

    if (results.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.search_off_rounded,
        title: "No songs found",
        subtitle: "Try a different search term.",
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        return SongTile(
          song: results[index],
          onTap: () {
            final path = results[index].data;
            close(context, null);
            Future<void>.delayed(Duration.zero, () => onFileTap(path));
          },
        );
      },
    );
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    final settings = Provider.of<AppSettingsProvider>(context, listen: false);
    final theme = settings.theme;
    final appBarColor =
        ThemeHelper.appBarColor(theme, customColor: settings.customPrimary);
    final textPrimary = ThemeHelper.textPrimary(theme);
    final backgroundColor =
        ThemeHelper.background(theme, customColor: settings.customPrimary);

    return Theme.of(context).copyWith(
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: appBarColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: textPrimary.withOpacity(0.5)),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(color: textPrimary),
      ),
    );
  }
}

class VideoSearchDelegate extends SearchDelegate<void> {
  final List<AssetEntity> videos;
  final Future<void> Function(AssetEntity video) onVideoTap;

  VideoSearchDelegate({
    required this.videos,
    required this.onVideoTap,
  });

  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(
          tooltip: 'Clear search',
          icon: const Icon(Icons.clear_rounded),
          onPressed: () => query = '',
        ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        tooltip: 'Back',
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final normalizedQuery = query.trim().toLowerCase();
    final results = videos
        .where(
          (video) =>
              (video.title ?? 'Video').toLowerCase().contains(normalizedQuery),
        )
        .toList(growable: false);

    if (results.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.search_off_rounded,
        title: 'No videos found',
        subtitle: 'Try a different title.',
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final video = results[index];
        return ListTile(
          leading: const Icon(Icons.play_circle_outline_rounded),
          title: Text(
            video.title ?? 'Video',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(_formatDuration(video.duration)),
          onTap: () async {
            close(context, null);
            await Future<void>.delayed(Duration.zero);
            await onVideoTap(video);
          },
        );
      },
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      return '${duration.inHours}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}';
    }
    return '${duration.inMinutes}:${twoDigits(duration.inSeconds.remainder(60))}';
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    final settings = Provider.of<AppSettingsProvider>(context, listen: false);
    return Theme.of(context).copyWith(
      scaffoldBackgroundColor: ThemeHelper.background(
        settings.theme,
        customColor: settings.customPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: ThemeHelper.appBarColor(
          settings.theme,
          customColor: settings.customPrimary,
        ),
        elevation: 0,
        foregroundColor: ThemeHelper.textPrimary(settings.theme),
      ),
    );
  }
}
