import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:provider/provider.dart';
import '../../widgets/modern_widgets.dart';
import '../Feature/Scrolltext.dart';
import '../videoplayer/VideoBackgroundProvider.dart';
import '../../core/app_settings_provider.dart';
import '../../core/media_enums.dart';
import '../../core/ui/responsive/responsive_builder.dart';
import 'QueueScreen.dart';
import 'Audioplayerprovider.dart';

class AudioPlayerScreen extends StatefulWidget {
  final String filePath;
  final Duration startPosition;

  const AudioPlayerScreen(
      {super.key, required this.filePath, required this.startPosition});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen>
    with TickerProviderStateMixin {
  late AnimationController _vinylController;

  final List<String> _backgroundImages = [
    'assets/songbg/Beautifulsky.jpg',
    'assets/songbg/Colorful Leaves with Water Droplets Aesthetic Nature (57) - 480x857.JPG',
    'assets/songbg/Evening Beach Aesthetic Calm and Relaxing Sea Waves (245) - 2000x3569.JPG',
    'assets/songbg/Evening Beach Aesthetic Calm and Relaxing Sea Waves (659) - 2000x3569.JPG',
  ];
  int _currentBackgroundIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializePlayback();

    _vinylController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  Future<void> _initializePlayback() async {
    final audioProvider =
        Provider.of<AudioPlayerProvider>(context, listen: false);
    final settings = Provider.of<AppSettingsProvider>(context, listen: false);
    final videoProvider =
        Provider.of<VideoBackgroundProvider>(context, listen: false);
    await videoProvider.stopBackgroundPlayback();
    await settings.addRecentlyPlayed(widget.filePath);
    await audioProvider.configurePlayback(
      repeatMode: _repeatLabel(settings.repeatMode),
      shuffle: settings.shuffle,
      shouldAutoPlayNext: settings.autoPlayNext,
      speed: settings.defaultPlaybackSpeed,
      seekStepSeconds: settings.seekStep,
    );
    final started = await audioProvider.playAudio(
      widget.filePath,
      startPosition: widget.startPosition,
      resumeFromSavedPosition: settings.resumeLastPositionAudio,
    );
    if (!started && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(audioProvider.playbackError ?? 'Unable to play audio.')),
      );
    }
  }

  String _repeatLabel(RepeatMode mode) => switch (mode) {
        RepeatMode.off => 'No Loop',
        RepeatMode.one => 'Loop One',
        RepeatMode.all => 'Loop All',
      };

  RepeatMode _repeatMode(String label) => switch (label) {
        'Loop One' => RepeatMode.one,
        'Loop All' => RepeatMode.all,
        _ => RepeatMode.off,
      };

  @override
  void dispose() {
    _vinylController.dispose();
    super.dispose();
  }

  void _changeBackgroundImage() {
    setState(() {
      _currentBackgroundIndex =
          (_currentBackgroundIndex + 1) % _backgroundImages.length;
    });
  }

  void _showSleepTimerPicker() {
    final provider = Provider.of<AudioPlayerProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassCard(
        borderRadius: 30,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("Sleep Timer",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
            ListTile(
              title: const Text("Off", style: TextStyle(color: Colors.white)),
              onTap: () {
                provider.setSleepTimer(null);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text("15 Minutes",
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                provider.setSleepTimer(const Duration(minutes: 15));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text("30 Minutes",
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                provider.setSleepTimer(const Duration(minutes: 30));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text("60 Minutes",
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                provider.setSleepTimer(const Duration(minutes: 60));
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showPlaybackSpeedPicker() {
    final provider = Provider.of<AudioPlayerProvider>(context, listen: false);
    final settings = Provider.of<AppSettingsProvider>(context, listen: false);
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Playback speed',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: speeds.map((speed) {
                  final selected =
                      (provider.playbackSpeed - speed).abs() < 0.01;
                  return ChoiceChip(
                    label: Text('${speed}x'),
                    selected: selected,
                    onSelected: (_) async {
                      await provider.setPlaybackSpeed(speed);
                      await settings.setDefaultPlaybackSpeed(speed);
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioPlayerProvider>(context);
    final settings = context.watch<AppSettingsProvider>();
    final currentPath = audioProvider.currentFilePath ?? widget.filePath;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.white, size: 36),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: settings.favorites.contains(currentPath)
                ? 'Remove favorite'
                : 'Add favorite',
            icon: Icon(
              settings.favorites.contains(currentPath)
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: Colors.white,
            ),
            onPressed: () => settings.toggleFavorite(currentPath),
          ),
          IconButton(
            tooltip: 'Playing queue',
            icon: const Icon(Icons.queue_music_rounded, color: Colors.white),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const QueueScreen())),
          ),
          IconButton(
            tooltip: 'Sleep timer',
            icon: Icon(Icons.timer_rounded,
                color: audioProvider.sleepTimerEndTime != null
                    ? Colors.blueAccent
                    : Colors.white),
            onPressed: _showSleepTimerPicker,
          ),
          PopupMenuButton<String>(
            tooltip: 'More playback options',
            onSelected: (String value) {
              if (value == 'Speed') {
                _showPlaybackSpeedPicker();
                return;
              }
              if (value == 'Background') {
                _changeBackgroundImage();
                return;
              }
              audioProvider.setLoopMode(value);
              settings.setRepeatMode(_repeatMode(value));
            },
            itemBuilder: (context) => [
              'Speed',
              'Background',
              'Loop One',
              'Loop All',
              'No Loop',
            ].map((choice) {
              return PopupMenuItem<String>(
                value: choice,
                child: Text(choice),
              );
            }).toList(),
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
          ),
        ],
      ),
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 1000),
            child: Container(
              key: ValueKey(_currentBackgroundIndex),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(_backgroundImages[_currentBackgroundIndex]),
                  fit: BoxFit.cover,
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40.0, sigmaY: 40.0),
                child: Container(color: Colors.black.withOpacity(0.6)),
              ),
            ),
          ),
          SafeArea(
            child: ResponsiveBuilder(
              compact: (context, constraints) => Column(
                children: [
                  const SizedBox(height: 20),
                  Expanded(
                    flex: 5,
                    child: _buildModernVinyl(audioProvider),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: _buildSongInfo(audioProvider),
                  ),
                  const SizedBox(height: 30),
                  _buildControls(audioProvider),
                  const SizedBox(height: 40),
                  Expanded(
                    flex: 3,
                    child: _buildBookmarksSection(audioProvider),
                  ),
                ],
              ),
              medium: (context, constraints) =>
                  _buildSplitLayout(audioProvider),
              expanded: (context, constraints) =>
                  _buildSplitLayout(audioProvider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitLayout(AudioPlayerProvider provider) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildModernVinyl(provider),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: _buildSongInfo(provider),
              ),
              const SizedBox(height: 20),
              _buildControls(provider),
            ],
          ),
        ),
        const VerticalDivider(color: Colors.white10, thickness: 1, width: 1),
        Expanded(
          flex: 3,
          child: _buildBookmarksSection(provider),
        ),
      ],
    );
  }

  Widget _buildModernVinyl(AudioPlayerProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final height =
            constraints.maxHeight.isFinite ? constraints.maxHeight : width;
        final size = math.min(width * 0.78, height * 0.88).clamp(150.0, 280.0);
        return Center(
          child: SizedBox(
            width: size * 1.08,
            height: size * 1.08,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (provider.isPlaying)
                  Container(
                    width: size * 1.05,
                    height: size * 1.05,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blueAccent.withValues(alpha: 0.1),
                    ),
                  ),
                RotationTransition(
                  turns: provider.isPlaying
                      ? _vinylController
                      : const AlwaysStoppedAnimation(0),
                  child: GlassCard(
                    borderRadius: size / 2,
                    blur: 5,
                    color: Colors.black.withValues(alpha: 0.4),
                    child: SizedBox.square(
                      dimension: size,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: ClipOval(
                          child: provider.currentArtworkBytes != null
                              ? Image.memory(
                                  provider.currentArtworkBytes!,
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                )
                              : Image.asset(
                                  'assets/songbg/Beautifulsky.jpg',
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: size * 0.06,
                  right: size * 0.12,
                  child: AnimatedRotation(
                    duration: const Duration(milliseconds: 500),
                    turns: provider.isPlaying ? 0.0 : -0.1,
                    alignment: Alignment.topRight,
                    child: Container(
                      width: math.max(7, size * 0.035),
                      height: size * 0.42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.grey, Colors.white70],
                        ),
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: const [
                          BoxShadow(color: Colors.black45, blurRadius: 10),
                        ],
                      ),
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

  Widget _buildSongInfo(AudioPlayerProvider provider) {
    return Column(
      children: [
        AutoScrollText(
          text: provider.currentTitle,
          style: const TextStyle(
              fontSize: 28,
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5),
        ),
        const SizedBox(height: 5),
        Text(provider.currentArtist,
            style: const TextStyle(color: Colors.white54, fontSize: 16)),
        const SizedBox(height: 20),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            activeTrackColor: Colors.blueAccent,
            inactiveTrackColor: Colors.white12,
            thumbColor: Colors.white,
            overlayColor: Colors.blueAccent.withOpacity(0.2),
          ),
          child: Slider(
            value: provider.currentPosition.inMilliseconds.toDouble().clamp(
                  0.0,
                  provider.totalDuration.inMilliseconds > 0
                      ? provider.totalDuration.inMilliseconds.toDouble()
                      : 1.0,
                ),
            max: provider.totalDuration.inMilliseconds > 0
                ? provider.totalDuration.inMilliseconds.toDouble()
                : 1.0,
            onChanged: (value) => provider.seekAudio(
              Duration(milliseconds: value.toInt()),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(provider.currentPosition),
                  style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
              Text(_formatDuration(provider.totalDuration),
                  style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls(AudioPlayerProvider provider) {
    final settings = Provider.of<AppSettingsProvider>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 360,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ModernIconButton(
                icon: Icons.shuffle_rounded,
                onPressed: () {
                  final enabled = !provider.shuffleEnabled;
                  provider.setShuffle(enabled);
                  settings.setShuffle(enabled);
                },
                size: 48,
                color: provider.shuffleEnabled
                    ? Colors.blueAccent
                    : Colors.white38,
              ),
              ModernIconButton(
                icon: Icons.skip_previous_rounded,
                onPressed: provider.playPrevious,
                size: 64,
                iconSize: 32,
              ),
              GestureDetector(
                onTap: provider.togglePlayPause,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                        colors: [Colors.blueAccent, Colors.lightBlueAccent]),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5)
                    ],
                  ),
                  child: Icon(
                      provider.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 48,
                      color: Colors.white),
                ),
              ),
              ModernIconButton(
                icon: Icons.skip_next_rounded,
                onPressed: provider.playNext,
                size: 64,
                iconSize: 32,
              ),
              ModernIconButton(
                icon: provider.loopMode == 'Loop One'
                    ? Icons.repeat_one_rounded
                    : Icons.repeat_rounded,
                onPressed: () {
                  final next = switch (provider.loopMode) {
                    'No Loop' => 'Loop All',
                    'Loop All' => 'Loop One',
                    _ => 'No Loop',
                  };
                  provider.setLoopMode(next);
                  settings.setRepeatMode(_repeatMode(next));
                },
                size: 48,
                color: provider.loopMode == 'No Loop'
                    ? Colors.white38
                    : Colors.blueAccent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookmarksSection(AudioPlayerProvider provider) {
    final currentPath = provider.currentFilePath ?? widget.filePath;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        borderRadius: 30,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Bookmarks",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  ModernIconButton(
                    icon: Icons.add_rounded,
                    onPressed: () => provider.markPosition(currentPath),
                    size: 40,
                    color: Colors.blueAccent,
                  ),
                ],
              ),
            ),
            Expanded(
              child: provider.marks.isEmpty
                  ? const Center(
                      child: Text("No bookmarks yet",
                          style: TextStyle(color: Colors.white38)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount: provider.marks.length,
                      itemBuilder: (context, index) {
                        final mark = provider.marks[index];
                        return ListTile(
                          leading: const Icon(Icons.bookmark_rounded,
                              color: Colors.blueAccent),
                          title: Text(_formatDuration(mark),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: Colors.redAccent),
                            onPressed: () =>
                                provider.deleteMark(currentPath, mark),
                          ),
                          onTap: () => provider.seekAudio(mark),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }
}
