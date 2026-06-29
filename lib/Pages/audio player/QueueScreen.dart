import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/modern_widgets.dart';
import 'Audioplayerprovider.dart';
import '../../core/theme_helper.dart';
import '../../core/app_settings_provider.dart';
import '../../core/ui/widgets/mini_player_aware_padding.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioPlayerProvider>(context);
    final settings = Provider.of<AppSettingsProvider>(context);
    final playlist = audioProvider.getPlaylist();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Playing Queue",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: ThemeHelper.backgroundGradient(settings.theme,
                  customColor: settings.customPrimary),
            ),
          ),
          MiniPlayerAwarePadding(
            child: SafeArea(
              child: playlist.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.queue_music_rounded,
                      title: "Queue is empty",
                      subtitle: "Start playing some music!")
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      itemCount: playlist.length,
                      buildDefaultDragHandles: false,
                      onReorder: audioProvider.reorderQueue,
                      itemBuilder: (context, index) {
                        final song = playlist[index];
                        final isCurrent =
                            audioProvider.currentFilePath == song.data;
                        return SongTile(
                          key: ValueKey(song.data),
                          song: song,
                          isPlaying: isCurrent,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Remove from queue',
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () =>
                                    audioProvider.removeFromQueue(index),
                              ),
                              ReorderableDragStartListener(
                                index: index,
                                child: const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Icon(Icons.drag_handle_rounded),
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            audioProvider.playAudio(song.data);
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
