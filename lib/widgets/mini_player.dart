import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Pages/audio player/Audioplayerprovider.dart';
import '../Pages/videoplayer/VideoBackgroundProvider.dart';
import '../Pages/audio player/Audioplayer.dart';
import '../Pages/videoplayer/Videoplayer.dart';

class MultiMiniPlayer extends StatefulWidget {
  const MultiMiniPlayer({Key? key}) : super(key: key);

  @override
  State<MultiMiniPlayer> createState() => _MultiMiniPlayerState();
}

class _MultiMiniPlayerState extends State<MultiMiniPlayer> {
  bool _audioOnTop = true;
  bool _lastAudioPlaying = false;
  bool _lastVideoPlaying = false;

  void _rotate() {
    final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
    final videoProvider = Provider.of<VideoBackgroundProvider>(context, listen: false);

    setState(() {
      _audioOnTop = !_audioOnTop;
      
      // Swapping playback logic
      if (_audioOnTop) {
        // Audio moved to top
        if (videoProvider.isPlaying) {
          videoProvider.pauseAudio();
          if (audioProvider.currentFilePath != null) {
            audioProvider.playAudio(audioProvider.currentFilePath!);
          }
        }
      } else {
        // Video moved to top
        if (audioProvider.isPlaying) {
          audioProvider.pauseAudio();
          if (videoProvider.currentFilePath != null) {
            videoProvider.resumeAudio();
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioPlayerProvider>(context);
    final videoProvider = Provider.of<VideoBackgroundProvider>(context);

    final bool hasAudio = audioProvider.currentFilePath != null;
    final bool hasVideo = videoProvider.currentFilePath != null;

    if (!hasAudio && !hasVideo) return const SizedBox.shrink();

    // Auto-priority logic
    if (hasAudio && audioProvider.isPlaying && !_lastAudioPlaying) {
      _audioOnTop = true;
    } else if (hasVideo && videoProvider.isPlaying && !_lastVideoPlaying) {
      _audioOnTop = false;
    }
    
    // Maintain priority: if one is playing and the other isn't, 
    // keep the playing one on top UNLESS the user just manually swapped
    if (hasAudio && hasVideo) {
      if (audioProvider.isPlaying && !videoProvider.isPlaying && _lastVideoPlaying) {
        _audioOnTop = true;
      } else if (videoProvider.isPlaying && !audioProvider.isPlaying && _lastAudioPlaying) {
        _audioOnTop = false;
      }
    } else if (hasAudio && !hasVideo) {
      _audioOnTop = true;
    } else if (hasVideo && !hasAudio) {
      _audioOnTop = false;
    }
    
    _lastAudioPlaying = hasAudio && audioProvider.isPlaying;
    _lastVideoPlaying = hasVideo && videoProvider.isPlaying;

    dynamic topProvider;
    dynamic bottomProvider;
    bool topIsVideo = false;
    bool bottomIsVideo = false;

    if (hasAudio && hasVideo) {
      if (_audioOnTop) {
        topProvider = audioProvider;
        topIsVideo = false;
        bottomProvider = videoProvider;
        bottomIsVideo = true;
      } else {
        topProvider = videoProvider;
        topIsVideo = true;
        bottomProvider = audioProvider;
        bottomIsVideo = false;
      }
    } else if (hasAudio) {
      topProvider = audioProvider;
      topIsVideo = false;
    } else if (hasVideo) {
      topProvider = videoProvider;
      topIsVideo = true;
    }

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (hasAudio && hasVideo && details.primaryVelocity!.abs() > 100) {
          _rotate();
        }
      },
      onHorizontalDragEnd: (details) {
        if (hasAudio && hasVideo && details.primaryVelocity!.abs() > 100) {
          _rotate();
        }
      },
      child: Container(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasAudio && hasVideo)
               const Text(
                "Swipe or Double Tap to rotate",
                style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w500),
              ),
            const SizedBox(height: 5),
            SizedBox(
              height: 110,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Background Card
                  if (hasAudio && hasVideo)
                    _buildAnimatedCard(
                      context, 
                      isVideo: bottomIsVideo,
                      provider: bottomProvider,
                      isTop: false,
                    ),
                  // Foreground Card
                  if (topProvider != null)
                    _buildAnimatedCard(
                      context, 
                      isVideo: topIsVideo,
                      provider: topProvider,
                      isTop: true,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedCard(
    BuildContext context, {
    required bool isVideo,
    required dynamic provider,
    required bool isTop,
  }) {
    if (provider == null || provider.currentFilePath == null) return const SizedBox.shrink();

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      bottom: isTop ? 0 : 35,
      left: isTop ? 10 : 35,
      right: isTop ? 10 : 35,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 500),
        curve: Curves.elasticOut,
        scale: isTop ? 1.0 : 0.85,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 400),
          opacity: isTop ? 1.0 : 0.4,
          child: _buildMiniCard(context, provider, isVideo: isVideo, isTop: isTop),
        ),
      ),
    );
  }

  Widget _buildMiniCard(BuildContext context, dynamic provider, {required bool isVideo, required bool isTop}) {
    final String? currentPath = provider.currentFilePath;
    if (currentPath == null) return const SizedBox.shrink();
    
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isVideo 
            ? Colors.cyanAccent.withOpacity(isTop ? 0.5 : 0.1) 
            : Colors.blueAccent.withOpacity(isTop ? 0.5 : 0.1),
          width: isTop ? 2 : 1
        ),
        boxShadow: [
          BoxShadow(
            color: (isVideo ? Colors.cyanAccent : Colors.blueAccent).withOpacity(isTop ? 0.25 : 0.05),
            blurRadius: isTop ? 20 : 5,
            spreadRadius: isTop ? 2 : 0
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: InkWell(
            onTap: isTop ? () {
               if (isVideo) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoPlayerScreen(
                      playlist: provider.currentPlaylist ?? [provider.currentFilePath!],
                      initialIndex: provider.currentIndex,
                      initialPosition: provider.currentPosition,
                    ),
                  ),
                );
                // Don't call pauseAudio here, let VideoPlayerScreen handle the transition
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AudioPlayerScreen(
                      filePath: provider.currentFilePath!,
                      startPosition: provider.currentPosition,
                    ),
                  ),
                );
              }
            } : _rotate,
            onDoubleTap: isTop ? _rotate : null,
            child: Row(
              children: [
                const SizedBox(width: 15),
                _buildArtwork(provider, isVideo),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentPath.split('/').last,
                        style: TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold, 
                          fontSize: isTop ? 13 : 11
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        isVideo ? "Video Background" : "Music Playing",
                        style: TextStyle(
                          color: isVideo ? Colors.cyanAccent : Colors.blueAccent, 
                          fontSize: isTop ? 10 : 9, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ],
                  ),
                ),
                if (isTop) ...[
                  // Rotation Button
                  IconButton(
                    icon: const Icon(Icons.rotate_right_rounded, color: Colors.white70, size: 22),
                    onPressed: _rotate,
                    tooltip: "Swap Player",
                  ),
                  IconButton(
                    icon: Icon(
                      provider.isPlaying 
                          ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      color: isVideo ? Colors.cyanAccent : Colors.white,
                      size: 32,
                    ),
                    onPressed: () {
                      if (isVideo) {
                        provider.isPlaying ? provider.pauseAudio() : provider.resumeAudio();
                      } else {
                        provider.playAudio(provider.currentFilePath!);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                    onPressed: () {
                      if (isVideo) {
                        provider.stopBackgroundPlayback(stopPlayer: provider.isPlaying);
                      } else {
                        provider.stopAudio(stopPlayer: provider.isPlaying);
                      }
                    },
                  ),
                  const SizedBox(width: 5),
                ] else 
                  const Padding(
                    padding: EdgeInsets.only(right: 15),
                    child: Icon(Icons.swap_vert_rounded, color: Colors.white38, size: 24),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArtwork(dynamic provider, bool isVideo) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: !isVideo && provider is AudioPlayerProvider && provider.currentArtworkBytes != null
            ? Image.memory(
                provider.currentArtworkBytes!,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              )
            : Container(
                color: isVideo ? Colors.cyanAccent.withOpacity(0.1) : Colors.blueAccent.withOpacity(0.1),
                child: Icon(
                  isVideo ? Icons.video_library_rounded : Icons.music_note_rounded,
                  color: isVideo ? Colors.cyanAccent : Colors.blueAccent,
                  size: 20,
                ),
              ),
      ),
    );
  }
}
