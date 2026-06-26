import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/modern_widgets.dart';
import '../Feature/Scrolltext.dart';
import '../videoplayer/VideoBackgroundProvider.dart';
import '../../core/app_settings_provider.dart';
import 'QueueScreen.dart';
import 'Audioplayerprovider.dart';

class AudioPlayerScreen extends StatefulWidget {
  final String filePath;
  final Duration startPosition;

  const AudioPlayerScreen({super.key, required this.filePath, required this.startPosition});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> with TickerProviderStateMixin {
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
    try {
      Provider.of<VideoBackgroundProvider>(context, listen: false).stopBackgroundPlayback();
    } catch (e) {}

    final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
    final settings = Provider.of<AppSettingsProvider>(context, listen: false);
    
    final startPos = settings.resumeLastPositionAudio ? widget.startPosition : Duration.zero;
    audioProvider.playAudio(widget.filePath, startPosition: startPos);

    _vinylController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _vinylController.dispose();
    super.dispose();
  }

  void _changeBackgroundImage() {
    setState(() {
      _currentBackgroundIndex = (_currentBackgroundIndex + 1) % _backgroundImages.length;
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
              child: Text("Sleep Timer", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              title: const Text("Off", style: TextStyle(color: Colors.white)),
              onTap: () { provider.setSleepTimer(null); Navigator.pop(context); },
            ),
            ListTile(
              title: const Text("15 Minutes", style: TextStyle(color: Colors.white)),
              onTap: () { provider.setSleepTimer(const Duration(minutes: 15)); Navigator.pop(context); },
            ),
            ListTile(
              title: const Text("30 Minutes", style: TextStyle(color: Colors.white)),
              onTap: () { provider.setSleepTimer(const Duration(minutes: 30)); Navigator.pop(context); },
            ),
            ListTile(
              title: const Text("60 Minutes", style: TextStyle(color: Colors.white)),
              onTap: () { provider.setSleepTimer(const Duration(minutes: 60)); Navigator.pop(context); },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioPlayerProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 36),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.queue_music_rounded, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QueueScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.palette_rounded, color: Colors.white),
            onPressed: _changeBackgroundImage,
          ),
          IconButton(
            icon: Icon(Icons.timer_rounded, color: audioProvider.sleepTimerEndTime != null ? Colors.blueAccent : Colors.white),
            onPressed: _showSleepTimerPicker,
          ),
          PopupMenuButton<String>(
            onSelected: (String value) => audioProvider.setLoopMode(value),
            itemBuilder: (context) => ['Loop One', 'Loop All', 'No Loop'].map((choice) {
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
            child: Column(
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
          ),
        ],
      ),
    );
  }

  Widget _buildModernVinyl(AudioPlayerProvider provider) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse effect
          if (provider.isPlaying)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 1.0, end: 1.1),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeInOut,
              builder: (context, value, child) => Container(
                width: 300 * value,
                height: 300 * value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blueAccent.withOpacity(0.1),
                ),
              ),
              onEnd: () {}, 
            ),
          
          RotationTransition(
            turns: provider.isPlaying ? _vinylController : const AlwaysStoppedAnimation(0),
            child: GlassCard(
              borderRadius: 150,
              blur: 5,
              color: Colors.black.withOpacity(0.4),
              child: Container(
                width: 280,
                height: 280,
                padding: const EdgeInsets.all(12),
                child: ClipOval(
                  child: provider.currentArtworkBytes != null
                      ? Image.memory(provider.currentArtworkBytes!, fit: BoxFit.cover, gaplessPlayback: true)
                      : Image.asset('assets/songbg/Beautifulsky.jpg', fit: BoxFit.cover, gaplessPlayback: true),
                ),
              ),
            ),
          ),
          
          // Needle
          Positioned(
            top: 20,
            right: 40,
            child: AnimatedRotation(
              duration: const Duration(milliseconds: 500),
              turns: provider.isPlaying ? 0.0 : -0.1,
              alignment: Alignment.topRight,
              child: Container(
                width: 10,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.grey, Colors.white70]),
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongInfo(AudioPlayerProvider provider) {
    final songName = widget.filePath.split('/').last.split('.').first;
    return Column(
      children: [
        AutoScrollText(
          text: songName,
          style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 0.5),
        ),
        const SizedBox(height: 5),
        const Text("MarkedPlay Audio", style: TextStyle(color: Colors.white54, fontSize: 16)),
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
            value: provider.currentPosition.inSeconds.toDouble().clamp(0.0, provider.totalDuration.inSeconds.toDouble() > 0 ? provider.totalDuration.inSeconds.toDouble() : 1.0),
            max: provider.totalDuration.inSeconds.toDouble() > 0 ? provider.totalDuration.inSeconds.toDouble() : 1.0,
            onChanged: (value) => provider.seekAudio(Duration(seconds: value.toInt())),
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(provider.currentPosition), style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
              Text(_formatDuration(provider.totalDuration), style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls(AudioPlayerProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ModernIconButton(
          icon: Icons.shuffle_rounded,
          onPressed: () {}, // Future shuffle logic
          size: 48,
          color: Colors.white38,
        ),
        ModernIconButton(
          icon: Icons.skip_previous_rounded,
          onPressed: () => provider.playPrevious(),
          size: 64,
          iconSize: 32,
        ),
        GestureDetector(
          onTap: () => provider.playAudio(widget.filePath),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Colors.blueAccent, Colors.lightBlueAccent]),
              boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 20, spreadRadius: 5)],
            ),
            child: Icon(provider.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 48, color: Colors.white),
          ),
        ),
        ModernIconButton(
          icon: Icons.skip_next_rounded,
          onPressed: () => provider.playNext(),
          size: 64,
          iconSize: 32,
        ),
         ModernIconButton(
          icon: Icons.repeat_rounded,
          onPressed: () {
             final current = provider.loopMode;
             if (current == 'No Loop') provider.setLoopMode('Loop All');
             else if (current == 'Loop All') provider.setLoopMode('Loop One');
             else provider.setLoopMode('No Loop');
          },
          size: 48,
          color: provider.loopMode == 'No Loop' ? Colors.white38 : Colors.blueAccent,
        ),
      ],
    );
  }

  Widget _buildTopBar(AudioPlayerProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ModernIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onPressed: () => Navigator.pop(context),
            size: 44,
          ),
          Row(
            children: [
              ModernIconButton(
                icon: Icons.timer_rounded,
                onPressed: _showSleepTimerPicker,
                size: 44,
                color: provider.sleepTimerEndTime != null ? Colors.blueAccent : Colors.white70,
              ),
              const SizedBox(width: 10),
              ModernIconButton(
                icon: Icons.queue_music_rounded,
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QueueScreen())),
                size: 44,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarksSection(AudioPlayerProvider provider) {
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
                  const Text("Bookmarks", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ModernIconButton(
                    icon: Icons.add_rounded,
                    onPressed: () => provider.markPosition(widget.filePath),
                    size: 40,
                    color: Colors.blueAccent,
                  ),
                ],
              ),
            ),
            Expanded(
              child: provider.marks.isEmpty
                  ? const Center(child: Text("No bookmarks yet", style: TextStyle(color: Colors.white38)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount: provider.marks.length,
                      itemBuilder: (context, index) {
                        final mark = provider.marks[index];
                        return ListTile(
                          leading: const Icon(Icons.bookmark_rounded, color: Colors.blueAccent),
                          title: Text(_formatDuration(mark), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                            onPressed: () => provider.deleteMark(widget.filePath, mark),
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
