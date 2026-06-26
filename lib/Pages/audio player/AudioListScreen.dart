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

    final sortedSongs = [...songs];
    if (settings.sortMode == SortMode.name) {
      sortedSongs.sort((a, b) => a.title.compareTo(b.title));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          albumName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: 1,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
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
                          final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
                          return SongTile(
                            song: song,
                            isPlaying: audioProvider.currentFilePath == song.data,
                            onTap: () {
                              audioProvider.updatePlaylist(sortedSongs);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AudioPlayerScreen(
                                    filePath: song.data,
                                    startPosition: audioProvider.currentPosition,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: sortedSongs.length,
                        itemBuilder: (_, index) {
                          final song = sortedSongs[index];
                          final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
                          return GestureDetector(
                            onTap: () {
                              audioProvider.updatePlaylist(sortedSongs);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AudioPlayerScreen(
                                    filePath: song.data,
                                    startPosition: audioProvider.currentPosition,
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
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          song.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          song.artist ?? "Unknown Artist",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 11,
                                          ),
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
