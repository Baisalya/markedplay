import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path_utils;
import 'package:provider/provider.dart';

import '../../core/app_settings_provider.dart';
import '../../core/services/file_browser_service.dart';
import '../../core/theme_helper.dart';
import '../../core/ui/widgets/mini_player_aware_padding.dart';
import '../../widgets/modern_widgets.dart';
import '../audio player/Audioplayer.dart';
import '../videoplayer/Videoplayer.dart';

enum SavedMediaView { favorites, recent }

class SavedMediaScreen extends StatelessWidget {
  final SavedMediaView view;

  const SavedMediaScreen({
    super.key,
    required this.view,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    final items = view == SavedMediaView.favorites
        ? settings.favorites
        : settings.recentlyPlayed;
    final title = view == SavedMediaView.favorites ? 'Favorites' : 'Recent';

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: ThemeHelper.background(
        settings.theme,
        customColor: settings.customPrimary,
      ),
      appBar: AppBar(title: Text(title)),
      body: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: ThemeHelper.backgroundGradient(
                settings.theme,
                customColor: settings.customPrimary,
              ),
            ),
            child: const SizedBox.expand(),
          ),
          MiniPlayerAwarePadding(
            child: SafeArea(
              child: items.isEmpty
                  ? EmptyStateWidget(
                      icon: view == SavedMediaView.favorites
                          ? Icons.favorite_border_rounded
                          : Icons.history_rounded,
                      title: view == SavedMediaView.favorites
                          ? 'No favorites yet'
                          : 'Nothing played yet',
                      subtitle: view == SavedMediaView.favorites
                          ? 'Tap the heart beside a song or video to keep it here.'
                          : 'Media you open will appear here for quick access.',
                    )
                  : Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final mediaPath = items[index];
                            final isVideo =
                                FileBrowserService().isVideoFile(mediaPath);
                            return ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              tileColor: ThemeHelper.cardColor(
                                settings.theme,
                                customColor: settings.customPrimary,
                              ),
                              leading: Icon(
                                isVideo
                                    ? Icons.movie_outlined
                                    : Icons.music_note_rounded,
                              ),
                              title: Text(
                                path_utils.basename(mediaPath),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                isVideo ? 'Video' : 'Audio',
                                maxLines: 1,
                              ),
                              trailing: IconButton(
                                tooltip: view == SavedMediaView.favorites
                                    ? 'Remove favorite'
                                    : 'Remove from recent',
                                icon: Icon(
                                  view == SavedMediaView.favorites
                                      ? Icons.favorite_rounded
                                      : Icons.close_rounded,
                                ),
                                onPressed: () {
                                  if (view == SavedMediaView.favorites) {
                                    settings.toggleFavorite(mediaPath);
                                  } else {
                                    settings.removeRecentlyPlayed(mediaPath);
                                  }
                                },
                              ),
                              onTap: () => _openMedia(
                                context,
                                mediaPath,
                                isVideo,
                                settings,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openMedia(
    BuildContext context,
    String mediaPath,
    bool isVideo,
    AppSettingsProvider settings,
  ) async {
    final uri = Uri.tryParse(mediaPath);
    final isNetwork =
        uri?.isScheme('http') == true || uri?.isScheme('https') == true;
    if (!isNetwork && !await File(mediaPath).exists()) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This file has moved or is no longer available.'),
        ),
      );
      return;
    }

    await settings.addRecentlyPlayed(mediaPath);
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => isVideo
            ? VideoPlayerScreen(playlist: [mediaPath])
            : AudioPlayerScreen(
                filePath: mediaPath,
                startPosition: Duration.zero,
              ),
      ),
    );
  }
}
