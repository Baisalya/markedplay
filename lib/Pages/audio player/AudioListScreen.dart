import 'package:flutter/material.dart';
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

    final primaryColor = ThemeHelper.primary(
      theme,
      customColor: settings.customPrimary,
    );

    final backgroundColor = ThemeHelper.background(
      theme,
      customColor: settings.customPrimary,
    );

    final sortedSongs = [...songs];

    // 🔥 Global Sorting
    if (settings.sortMode == SortMode.name) {
      sortedSongs.sort(
              (a, b) => a.title.compareTo(b.title));
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
          albumName,
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        iconTheme: IconThemeData(color: primaryColor),
      ),

      // ================= LIST VIEW =================

      body: settings.viewMode == ViewMode.list
          ? ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedSongs.length,
        itemBuilder: (_, index) {

          final song = sortedSongs[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: ThemeHelper.cardColor(
                theme,
                customColor: settings.customPrimary,
              ),
              borderRadius:
              BorderRadius.circular(16),
              border: Border.all(
                color: ThemeHelper.borderColor(
                  theme,
                  customColor: settings.customPrimary,
                ),
              ),
            ),
            child: ListTile(
              leading: Icon(
                Icons.music_note,
                color: primaryColor,
              ),
              title: Text(
                song.title,
                style: TextStyle(
                  color: ThemeHelper.textPrimary(
                    theme,
                  ),
                ),
              ),
              subtitle: Text(
                song.artist ?? "Unknown Artist",
                style: TextStyle(
                  color: ThemeHelper.textSecondary(
                    theme,
                  ),
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AudioPlayerScreen(
                          filePath: song.data,
                          startPosition:
                          Provider.of<
                              AudioPlayerProvider>(
                              context,
                              listen: false)
                              .currentPosition,
                        ),
                  ),
                );
              },
            ),
          );
        },
      )

      // ================= GRID VIEW =================

          : GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate:
        const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: sortedSongs.length,
        itemBuilder: (_, index) {

          final song = sortedSongs[index];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AudioPlayerScreen(
                        filePath: song.data,
                        startPosition:
                        Provider.of<
                            AudioPlayerProvider>(
                            context,
                            listen: false)
                            .currentPosition,
                      ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: ThemeHelper.cardColor(
                  theme,
                  customColor: settings.customPrimary,
                ),
                borderRadius:
                BorderRadius.circular(20),
                border: Border.all(
                  color: ThemeHelper.borderColor(
                    theme,
                    customColor:
                    settings.customPrimary,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.stretch,
                children: [

                  // 🎵 Artwork
                  Expanded(
                    child: ClipRRect(
                      borderRadius:
                      const BorderRadius.vertical(
                          top: Radius.circular(20)),
                      child:
                      QueryArtworkWidget(
                        id: song.id,
                        type: ArtworkType.AUDIO,
                        nullArtworkWidget: Icon(
                          Icons.music_note,
                          size: 50,
                          color: primaryColor,
                        ),
                        artworkFit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // 🎼 Title Section
                  Padding(
                    padding:
                    const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          maxLines: 2,
                          overflow:
                          TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ThemeHelper
                                .textPrimary(theme),
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          song.artist ??
                              "Unknown Artist",
                          maxLines: 1,
                          overflow:
                          TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ThemeHelper
                                .textSecondary(theme),
                            fontSize: 12,
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
    );
  }
}