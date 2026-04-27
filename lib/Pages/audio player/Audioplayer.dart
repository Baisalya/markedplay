import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../Feature/Scrolltext.dart';
import 'Audioplayerprovider.dart';

class AudioPlayerScreen extends StatefulWidget {
  final String filePath;
  final Duration startPosition;

  AudioPlayerScreen({required this.filePath, required this.startPosition});

  @override
  _AudioPlayerScreenState createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

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
    final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
    audioProvider.playAudio(widget.filePath, startPosition: widget.startPosition);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _changeBackgroundImage() {
    setState(() {
      _currentBackgroundIndex = (_currentBackgroundIndex + 1) % _backgroundImages.length;
    });
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
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 30),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette_outlined, color: Colors.white),
            onPressed: _changeBackgroundImage,
          ),
          PopupMenuButton<String>(
            onSelected: (String value) => audioProvider.setLoopMode(value),
            itemBuilder: (context) => ['Loop One', 'Loop All', 'No Loop'].map((choice) {
              return PopupMenuItem<String>(
                value: choice,
                child: Row(
                  children: [
                    Icon(
                      choice == 'Loop One' ? Icons.repeat_one : Icons.repeat,
                      color: choice == 'No Loop' ? Colors.black38 : Colors.black87,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(choice),
                  ],
                ),
              );
            }).toList(),
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Dynamic Background
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            child: Container(
              key: ValueKey(_currentBackgroundIndex),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(_backgroundImages[_currentBackgroundIndex]),
                  fit: BoxFit.cover,
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
                child: Container(color: Colors.black.withOpacity(0.5)),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Expanded(
                  flex: 5,
                  child: _buildCyberVinyl(audioProvider),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildInfoAndSlider(audioProvider),
                ),
                _buildMainControls(audioProvider),
                const SizedBox(height: 10),
                Expanded(
                  flex: 3,
                  child: _buildMarksList(audioProvider),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCyberVinyl(AudioPlayerProvider provider) {
    return Center(
      child: Container(
        width: 340,
        height: 340,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _buildEnergyAura(),
            Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(0.2),
              alignment: Alignment.center,
              child: RotationTransition(
                turns: provider.isPlaying ? _animationController : const AlwaysStoppedAnimation(0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 30, spreadRadius: 5)],
                        image: const DecorationImage(
                          image: AssetImage('assets/songbg/vinylmusic.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // Stable, Cached Artwork
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 3),
                      ),
                      child: ClipOval(
                        child: provider.currentArtworkBytes != null
                            ? Image.memory(
                                provider.currentArtworkBytes!,
                                key: ValueKey(provider.currentFilePath),
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                              )
                            : Image.asset(
                                'assets/songbg/Beautifulsky.jpg',
                                key: const ValueKey('default_art'),
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                              ),
                      ),
                    ),
                    Container(
                      width: 250,
                      height: 250,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.white10, Colors.transparent, Colors.black12],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: 40,
              child: AnimatedRotation(
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutBack,
                turns: provider.isPlaying ? 0.08 : -0.05,
                alignment: Alignment.topRight,
                child: Image.asset('assets/songbg/needle.png', width: 120, height: 160, 
                  errorBuilder: (c, e, s) => _buildFallbackNeedle(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackNeedle() {
    return Container(
      width: 15,
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.grey[400]!, Colors.grey[700]!]),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 5)],
      ),
    );
  }

  Widget _buildEnergyAura() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        double pulse = 1.0 + (0.15 * (1.0 - (_animationController.value % 1.0)));
        return Container(
          width: 280 * pulse,
          height: 280 * pulse,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Colors.blueAccent.withOpacity(0.2), Colors.transparent],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoAndSlider(AudioPlayerProvider provider) {
    return Column(
      children: [
        AutoScrollText(
          text: getSongName(widget.filePath),
          style: const TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        LayoutBuilder(
          builder: (context, constraints) {
            double totalSecs = provider.totalDuration.inSeconds.toDouble();
            return Stack(
              alignment: Alignment.centerLeft,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    activeTrackColor: Colors.blueAccent,
                    inactiveTrackColor: Colors.white12,
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    value: provider.currentPosition.inSeconds.toDouble(),
                    max: totalSecs > 0 ? totalSecs : 100,
                    onChanged: (value) => provider.seekAudio(Duration(seconds: value.toInt())),
                  ),
                ),
                if (totalSecs > 0)
                  ...provider.marks.map((mark) {
                    double ratio = mark.inSeconds / totalSecs;
                    double pos = 24 + (ratio * (constraints.maxWidth - 48));
                    return Positioned(
                      left: pos,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.blueAccent, blurRadius: 4)]),
                      ),
                    );
                  }).toList(),
              ],
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(provider.currentPosition), style: const TextStyle(color: Colors.white54, fontSize: 12)),
              Text(_formatDuration(provider.totalDuration), style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainControls(AudioPlayerProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(icon: const Icon(Icons.replay_10, color: Colors.white70, size: 30), onPressed: () => provider.seekAudio(provider.currentPosition - const Duration(seconds: 10))),
        GestureDetector(
          onTap: () => provider.playAudio(widget.filePath),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Colors.blueAccent, Colors.blue[800]!]),
              boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.4), blurRadius: 20, spreadRadius: 2)],
            ),
            child: Icon(provider.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 45, color: Colors.white),
          ),
        ),
        IconButton(icon: const Icon(Icons.forward_10, color: Colors.white70, size: 30), onPressed: () => provider.seekAudio(provider.currentPosition + const Duration(seconds: 10))),
      ],
    );
  }

  Widget _buildMarksList(AudioPlayerProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 10, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Bookmarks",
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.bookmark_add_outlined, color: Colors.blueAccent, size: 24),
                  onPressed: () => provider.markPosition(widget.filePath),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, indent: 20, endIndent: 20),
          Expanded(
            child: provider.marks.isEmpty
                ? const Center(child: Text("No bookmarks", style: TextStyle(color: Colors.white38)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    itemCount: provider.marks.length,
                    itemBuilder: (context, index) {
                      final mark = provider.marks[index];
                      return ListTile(
                        leading: const Icon(Icons.bookmark, color: Colors.blueAccent, size: 20),
                        title: Text(_formatDuration(mark), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          onPressed: () => provider.deleteMark(widget.filePath, mark),
                        ),
                        onTap: () => provider.seekAudio(mark),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  String getSongName(String filePath) {
    return filePath.split('/').last.split('.').first;
  }
}

class MiniPlayer extends StatelessWidget {
  final VoidCallback onClose;
  const MiniPlayer({Key? key, required this.onClose}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioPlayerProvider>(context);
    if (audioProvider.currentFilePath == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AudioPlayerScreen(
            filePath: audioProvider.currentFilePath!,
            startPosition: audioProvider.currentPosition,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        height: 75,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 15, offset: Offset(0, 5))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Row(
              children: [
                const SizedBox(width: 15),
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: audioProvider.currentArtworkBytes != null
                        ? Image.memory(
                            audioProvider.currentArtworkBytes!,
                            key: ValueKey(audioProvider.currentFilePath),
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          )
                        : Image.asset(
                            'assets/songbg/Beautifulsky.jpg',
                            key: const ValueKey('mini_default_art'),
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        audioProvider.currentFilePath!.split('/').last,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        "Now Playing",
                        style: TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    audioProvider.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    color: Colors.white,
                    size: 35,
                  ),
                  onPressed: () => audioProvider.playAudio(audioProvider.currentFilePath!),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                  onPressed: onClose,
                ),
                const SizedBox(width: 5),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
