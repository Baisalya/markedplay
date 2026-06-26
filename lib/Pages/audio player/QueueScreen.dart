import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../widgets/modern_widgets.dart';
import 'Audioplayerprovider.dart';
import '../../core/theme_helper.dart';
import '../../core/app_settings_provider.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioPlayerProvider>(context);
    final settings = Provider.of<AppSettingsProvider>(context);
    final playlist = audioProvider.getPlaylist(); // Need to add this getter or make _playlist public

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Playing Queue", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: ThemeHelper.backgroundGradient(settings.theme, customColor: settings.customPrimary),
            ),
          ),
          SafeArea(
            child: playlist.isEmpty
                ? const EmptyStateWidget(icon: Icons.queue_music_rounded, title: "Queue is empty", subtitle: "Start playing some music!")
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: playlist.length,
                    itemBuilder: (context, index) {
                      final song = playlist[index];
                      final isCurrent = audioProvider.currentFilePath == song.data;
                      return SongTile(
                        song: song,
                        isPlaying: isCurrent,
                        onTap: () {
                          audioProvider.playAudio(song.data);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
