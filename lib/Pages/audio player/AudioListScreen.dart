import 'package:flutter/material.dart';
import 'package:markedplay/widgets/modern_widgets.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../../core/app_settings_provider.dart';
import '../../core/media_enums.dart';
import '../../core/theme_helper.dart';
import 'Audioplayer.dart';
import 'Audioplayerprovider.dart';

class AudioListScreen extends StatelessWidget {
  final String albumName;
  final List<SongModel> songs;

  const AudioListScreen({
    super.key,
    required this.albumName,
    required this.songs,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    final theme = settings.theme;
    final textPrimary = ThemeHelper.textPrimary(theme);
    final textSecondary = ThemeHelper.textSecondary(theme);
    final audioProvider = context.watch<AudioPlayerProvider>();

    final sortedSongs = [...songs];
    switch (settings.sortMode) {
      case SortMode.name:
        sortedSongs.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      case SortMode.date:
        sortedSongs.sort(
          (a, b) => (b.dateAdded ?? 0).compareTo(a.dateAdded ?? 0),
        );
      case SortMode.size:
        sortedSongs.sort((a, b) => b.size.compareTo(a.size));
      case SortMode.duration:
        sortedSongs.sort(
          (a, b) => (b.duration ?? 0).compareTo(a.duration ?? 0),
        );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor:
          ThemeHelper.background(theme, customColor: settings.customPrimary),
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
                        albumName,
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
              gradient: ThemeHelper.backgroundGradient(
                theme,
                customColor: settings.customPrimary,
              ),
            ),
          ),
          SafeArea(
            child: sortedSongs.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.music_note_rounded,
                    title: "No songs in this album",
                    subtitle: "This folder seems to be empty.",
                  )
                : settings.viewMode == ViewMode.list
                    ? ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        itemCount: sortedSongs.length,
                        itemBuilder: (_, index) {
                          final song = sortedSongs[index];
                          return SongTile(
                            song: song,
                            isPlaying:
                                audioProvider.currentFilePath == song.data,
                            trailing: IconButton(
                              tooltip: settings.favorites.contains(song.data)
                                  ? 'Remove favorite'
                                  : 'Add favorite',
                              icon: Icon(
                                settings.favorites.contains(song.data)
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                              ),
                              onPressed: () =>
                                  settings.toggleFavorite(song.data),
                            ),
                            onTap: () {
                              audioProvider.updatePlaylist(sortedSongs);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AudioPlayerScreen(
                                    filePath: song.data,
                                    startPosition: Duration.zero,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: sortedSongs.length,
                        itemBuilder: (_, index) {
                          final song = sortedSongs[index];
                          return GestureDetector(
                            onTap: () {
                              audioProvider.updatePlaylist(sortedSongs);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AudioPlayerScreen(
                                    filePath: song.data,
                                    startPosition: Duration.zero,
                                  ),
                                ),
                              );
                            },
                            child: GlassCard(
                              borderRadius: 20,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: AlbumArt(
                                      id: song.id,
                                      type: ArtworkType.AUDIO,
                                      borderRadius: 20,
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(12, 8, 4, 8),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                song.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: textPrimary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                song.artist ?? "Unknown Artist",
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: textSecondary,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: settings.favorites
                                                  .contains(song.data)
                                              ? 'Remove favorite'
                                              : 'Add favorite',
                                          icon: Icon(
                                            settings.favorites
                                                    .contains(song.data)
                                                ? Icons.favorite_rounded
                                                : Icons.favorite_border_rounded,
                                            size: 20,
                                          ),
                                          onPressed: () => settings
                                              .toggleFavorite(song.data),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
