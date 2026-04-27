import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VideoPlayerScreen extends StatefulWidget {
  final List<String> playlist;
  final int initialIndex;

  const VideoPlayerScreen({
    super.key,
    required this.playlist,
    this.initialIndex = 0,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> with TickerProviderStateMixin {
  late final Player player = Player();
  late final VideoController controller = VideoController(player);

  late int _currentIndex;
  String get _currentFilePath => widget.playlist[_currentIndex];

  bool _showControls = true;
  Timer? _hideTimer;
  bool _isLocked = false;
  late AnimationController _fadeController;
  late AnimationController _menuAnimationController;
  late Animation<double> _menuAnimation;
  bool _isFullScreen = true;
  bool _isExtraMenuOpen = false;
  bool _backgroundPlay = false;
  BoxFit _videoFit = BoxFit.contain;
  Timer? _indicatorTimer;

  // Gesture indicators
  double _brightness = 1.0;
  double _volume = 0.5;
  bool _showBrightnessIndicator = false;
  bool _showVolumeIndicator = false;
  bool _showSeekIndicator = false;
  Duration _tempSeekPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );
    _menuAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _menuAnimation = CurvedAnimation(
      parent: _menuAnimationController,
      curve: Curves.easeOutBack,
    );
    _initialize();
  }

  Future<void> _initialize() async {
    await _initBrightnessAndVolume();
    player.open(Media(_currentFilePath));
    
    // Resume position logic
    final prefs = await SharedPreferences.getInstance();
    final seconds = prefs.getInt('resume_$_currentFilePath');
    if (seconds != null) {
      player.stream.duration.listen((duration) {
        if (duration != Duration.zero) {
           player.seek(Duration(seconds: seconds));
        }
      });
    }

    _startHideTimer();
  }

  void _playNext() {
    if (_currentIndex < widget.playlist.length - 1) {
      setState(() {
        _currentIndex++;
        player.open(Media(_currentFilePath));
      });
    }
  }

  void _playPrevious() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        player.open(Media(_currentFilePath));
      });
    }
  }

  Future<void> _initBrightnessAndVolume() async {
    try {
      _brightness = await ScreenBrightness().current;
      _volume = await VolumeController.instance.getVolume();
      VolumeController.instance.showSystemUI = false;
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && !_isLocked && !_isExtraMenuOpen) {
        setState(() {
          _showControls = false;
          _showBrightnessIndicator = false;
          _showVolumeIndicator = false;
          _showSeekIndicator = false;
        });
        _fadeController.reverse();
      }
    });
  }

  void _hideIndicators() {
    _indicatorTimer?.cancel();
    _indicatorTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showBrightnessIndicator = false;
          _showVolumeIndicator = false;
        });
      }
    });
  }

  void _toggleControls() {
    if (_isLocked) {
      setState(() => _showControls = !_showControls);
      if (_showControls) _startHideTimer();
      return;
    }

    setState(() {
      _showControls = !_showControls;
      if (!_showControls) _isExtraMenuOpen = false;
    });

    if (_showControls) {
      _fadeController.forward();
      _startHideTimer();
    } else {
      _fadeController.reverse();
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _saveLastPosition();
    _hideTimer?.cancel();
    _fadeController.dispose();
    _menuAnimationController.dispose();
    VolumeController.instance.showSystemUI = true;
    player.dispose();
    super.dispose();
  }

  Future<void> _saveLastPosition() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('resume_$_currentFilePath', player.state.position.inSeconds);
  }

  // Gesture Handlers
  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_isLocked) return;
    double delta = details.primaryDelta! / MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    if (details.localPosition.dx < width / 2) {
      setState(() {
        _showBrightnessIndicator = true;
        _showVolumeIndicator = false;
        _brightness = (_brightness - delta).clamp(0.0, 1.0);
      });
      ScreenBrightness().setScreenBrightness(_brightness);
    } else {
      setState(() {
        _showVolumeIndicator = true;
        _showBrightnessIndicator = false;
        _volume = (_volume - delta).clamp(0.0, 1.0);
      });
      VolumeController.instance.setVolume(_volume);
    }
    _indicatorTimer?.cancel();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isLocked) return;
    double delta = details.primaryDelta! / MediaQuery.of(context).size.width;
    Duration duration = player.state.duration;
    if (duration == Duration.zero) return;
    
    int seekMillis = (delta * duration.inMilliseconds * 0.2).toInt();

    setState(() {
      _showSeekIndicator = true;
      if (_tempSeekPosition == Duration.zero) {
        _tempSeekPosition = player.state.position;
      }
      _tempSeekPosition += Duration(milliseconds: seekMillis);
      _tempSeekPosition = _tempSeekPosition.clamp(Duration.zero, duration);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_showSeekIndicator) {
      player.seek(_tempSeekPosition);
      setState(() {
        _showSeekIndicator = false;
        _tempSeekPosition = Duration.zero;
      });
    }
    _startHideTimer();
  }

  void _onHorizontalDragCancel() {
    setState(() {
      _showSeekIndicator = false;
      _tempSeekPosition = Duration.zero;
    });
    _startHideTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: (_) => _hideIndicators(),
        onVerticalDragCancel: () => _hideIndicators(),
        onHorizontalDragUpdate: _onHorizontalDragUpdate,
        onHorizontalDragEnd: _onHorizontalDragEnd,
        onHorizontalDragCancel: _onHorizontalDragCancel,
        onDoubleTapDown: (details) {
          if (_isLocked) return;
          final width = MediaQuery.of(context).size.width;
          if (details.localPosition.dx < width / 2) {
            player.seek(player.state.position - const Duration(seconds: 10));
          } else {
            player.seek(player.state.position + const Duration(seconds: 10));
          }
        },
        child: Stack(
          children: [
            Center(
              child: Video(
                controller: controller,
                controls: NoVideoControls,
                fit: _videoFit,
              ),
            ),
            
            // Gesture Overlays
            if (_showBrightnessIndicator) _buildCircularIndicator(Icons.brightness_6_rounded, _brightness, Colors.orange),
            if (_showVolumeIndicator) _buildCircularIndicator(Icons.volume_up_rounded, _volume, Colors.cyan),
            if (_showSeekIndicator) _buildSeekOverlay(),

            // Controls
            FadeTransition(
              opacity: _fadeController,
              child: IgnorePointer(
                ignoring: !_showControls,
                child: _isLocked ? _buildLockedUI() : _buildControlsUI(),
              ),
            ),

            // Floating Feature Buttons
            if (_showControls && !_isLocked) ...[
              _buildRotationButton(),
              _buildExpandableFeatureButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLockedUI() {
    return Stack(
      children: [
        Positioned(
          left: 30,
          top: 0,
          bottom: 0,
          child: Center(
            child: _buildGlassButton(
              icon: Icons.lock_outline_rounded,
              onPressed: () => setState(() => _isLocked = false),
              size: 56,
              color: Colors.redAccent.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlsUI() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
      child: Column(
        children: [
          _buildTopBar(),
          const Spacer(),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            _buildGlassButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _currentFilePath.split('/').last,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _buildGlassButton(
              icon: Icons.audiotrack_rounded,
              onPressed: _showAudioTracks,
            ),
            const SizedBox(width: 8),
            _buildGlassButton(
              icon: Icons.subtitles_rounded,
              onPressed: _showSubtitleTracks,
            ),
            const SizedBox(width: 8),
            _buildGlassButton(
              icon: Icons.more_vert_rounded,
              onPressed: _showMoreSettings,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildProgressBar(),
            const SizedBox(height: 8),
            Row(
              children: [
                StreamBuilder<Duration>(
                  stream: player.stream.position,
                  builder: (context, snapshot) {
                    return Text(
                      _formatDuration(snapshot.data ?? Duration.zero),
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                    );
                  },
                ),
                const Spacer(),
                Text(
                  _formatDuration(player.state.duration),
                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildGlassButton(
                  icon: Icons.lock_open_rounded,
                  onPressed: () => setState(() {
                    _isLocked = true;
                    _showControls = true;
                    _startHideTimer();
                  }),
                  size: 44,
                ),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildGlassButton(
                      icon: Icons.skip_previous_rounded,
                      onPressed: _currentIndex > 0 ? _playPrevious : null,
                      size: 48,
                      color: _currentIndex > 0 
                          ? Colors.cyanAccent.withOpacity(0.1) 
                          : Colors.white.withOpacity(0.05),
                    ),
                    const SizedBox(width: 25),
                    StreamBuilder<bool>(
                      stream: player.stream.playing,
                      builder: (context, snapshot) {
                        final isPlaying = snapshot.data ?? false;
                        return Container(
                          height: 64,
                          width: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.cyanAccent.withOpacity(0.3),
                                Colors.cyanAccent.withOpacity(0.1),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.cyanAccent.withOpacity(0.5),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyanAccent.withOpacity(0.2),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: IconButton(
                            iconSize: 38,
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () => player.playOrPause(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 25),
                    _buildGlassButton(
                      icon: Icons.skip_next_rounded,
                      onPressed: _currentIndex < widget.playlist.length - 1 ? _playNext : null,
                      size: 48,
                      color: _currentIndex < widget.playlist.length - 1 
                          ? Colors.cyanAccent.withOpacity(0.1) 
                          : Colors.white.withOpacity(0.05),
                    ),
                  ],
                ),
                const Spacer(),
                _buildGlassButton(
                  icon: _getFitIcon(),
                  onPressed: _toggleVideoFit,
                  size: 44,
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return StreamBuilder<Duration>(
      stream: player.stream.position,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = player.state.duration;
        return SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: Colors.cyanAccent,
            inactiveTrackColor: Colors.white24,
            thumbColor: Colors.white,
          ),
          child: Slider(
            value: position.inMilliseconds.toDouble().clamp(0, duration.inMilliseconds.toDouble()),
            max: duration.inMilliseconds.toDouble() == 0 ? 1 : duration.inMilliseconds.toDouble(),
            onChanged: (v) => player.seek(Duration(milliseconds: v.toInt())),
          ),
        );
      },
    );
  }

  // UI Components
  Widget _buildGlassButton({required IconData icon, VoidCallback? onPressed, double size = 44, Color? color}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color ?? Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(icon, color: Colors.white, size: size * 0.55),
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }

  Widget _buildCircularIndicator(IconData icon, double value, Color color) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.5), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(height: 8),
            Text(
              "${(value * 100).toInt()}%",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeekOverlay() {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            color: Colors.black45,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.fast_forward_rounded, color: Colors.cyanAccent, size: 40),
                const SizedBox(height: 12),
                Text(
                  _formatDuration(_tempSeekPosition),
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  "of ${_formatDuration(player.state.duration)}",
                  style: const TextStyle(color: Colors.white60, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Interaction Sheets
  void _showAudioTracks() {
    final tracks = player.state.tracks.audio;
    _showModernBottomSheet(
      title: "Audio Tracks",
      icon: Icons.audiotrack_rounded,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: tracks.length,
        itemBuilder: (context, i) => ListTile(
          leading: Icon(Icons.music_note_rounded, color: player.state.track.audio == tracks[i] ? Colors.cyanAccent : Colors.white60),
          title: Text(tracks[i].title ?? "Track ${i + 1}", style: TextStyle(color: player.state.track.audio == tracks[i] ? Colors.cyanAccent : Colors.white)),
          subtitle: Text(tracks[i].language ?? "Unknown Language", style: const TextStyle(color: Colors.white38)),
          onTap: () {
            player.setAudioTrack(tracks[i]);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showSubtitleTracks() {
    final tracks = player.state.tracks.subtitle;
    _showModernBottomSheet(
      title: "Subtitles",
      icon: Icons.subtitles_rounded,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: tracks.length,
        itemBuilder: (context, i) => ListTile(
          leading: Icon(Icons.closed_caption_rounded, color: player.state.track.subtitle == tracks[i] ? Colors.cyanAccent : Colors.white60),
          title: Text(tracks[i].title ?? "Subtitle ${i + 1}", style: TextStyle(color: player.state.track.subtitle == tracks[i] ? Colors.cyanAccent : Colors.white)),
          subtitle: Text(tracks[i].language ?? "Unknown Language", style: const TextStyle(color: Colors.white38)),
          onTap: () {
            player.setSubtitleTrack(tracks[i]);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showMoreSettings() {
    _showModernBottomSheet(
      title: "Settings",
      icon: Icons.settings_rounded,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.speed_rounded, color: Colors.white),
            title: const Text("Playback Speed", style: TextStyle(color: Colors.white)),
            trailing: Text("${player.state.rate}x", style: const TextStyle(color: Colors.cyanAccent)),
            onTap: _showPlaybackSpeedMenu,
          ),
          ListTile(
            leading: const Icon(Icons.aspect_ratio_rounded, color: Colors.white),
            title: const Text("Fit Screen", style: TextStyle(color: Colors.white)),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  void _showPlaybackSpeedMenu() {
    final speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    
    _showModernBottomSheet(
      title: "Motion Control",
      icon: Icons.shutter_speed_rounded,
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          // Use a tolerance-based check for the visual state to handle floating point issues
          final currentRate = player.state.rate;
          
          return Container(
            height: 160,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Dynamic Background Glow
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.15),
                        blurRadius: 40,
                        spreadRadius: 10,
                      )
                    ],
                  ),
                ),
                
                // Central HUD
                IgnorePointer(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                        child: Text(
                          "${currentRate.toStringAsFixed(2)}x",
                          key: ValueKey(currentRate),
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                            shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 10)],
                          ),
                        ),
                      ),
                      const Text(
                        "SPEED",
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 8,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Radial Orbiting Nodes
                ...List.generate(speeds.length, (index) {
                  final double angle = (index * (math.pi * 1.1) / (speeds.length - 1)) - (math.pi * 1.05);
                  const double radius = 70.0;
                  final double x = math.cos(angle) * radius;
                  final double y = math.sin(angle) * radius;
                  
                  final isSelected = (currentRate - speeds[index]).abs() < 0.01;
                  
                  return Transform.translate(
                    offset: Offset(x, y),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        // Always set rate and update UI to ensure it works
                        player.setRate(speeds[index]);
                        setSheetState(() {});
                        // Sync the main player state
                        Future.delayed(const Duration(milliseconds: 50), () {
                          if (mounted) setState(() {});
                        });
                      },
                      child: AnimatedScale(
                        scale: isSelected ? 1.25 : 1.0,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutBack,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubic,
                          width: 36, // Slightly larger hit target
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? Colors.cyanAccent : Colors.white.withOpacity(0.1),
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.white24,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: Colors.cyanAccent.withOpacity(0.4),
                                blurRadius: 12,
                                spreadRadius: 2,
                              )
                            ] : [],
                          ),
                          child: Center(
                            child: Text(
                              speeds[index].toString().replaceAll('.0', ''),
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  void _toggleRotation() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      if (_isFullScreen) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
      }
    });
  }

  void _toggleVideoFit() {
    setState(() {
      if (_videoFit == BoxFit.contain) {
        _videoFit = BoxFit.fill;
      } else if (_videoFit == BoxFit.fill) {
        _videoFit = BoxFit.cover;
      } else {
        _videoFit = BoxFit.contain;
      }
    });
    _startHideTimer();
  }

  IconData _getFitIcon() {
    if (_videoFit == BoxFit.contain) return Icons.fullscreen_rounded;
    if (_videoFit == BoxFit.fill) return Icons.unfold_more_rounded;
    return Icons.aspect_ratio_rounded;
  }

  Widget _buildRotationButton() {
    return Positioned(
      left: 20,
      top: 0,
      bottom: 0,
      child: Center(
        child: _buildGlassButton(
          icon: _isFullScreen ? Icons.screen_rotation_rounded : Icons.screen_lock_portrait_rounded,
          onPressed: _toggleRotation,
          size: 56,
          color: Colors.white.withOpacity(0.2),
        ),
      ),
    );
  }

  Widget _buildExpandableFeatureButton() {
    return Positioned(
      right: 20,
      top: 0,
      bottom: 0,
      child: Center(
        child: SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Circularly positioned buttons
              ..._buildCircularButtons(),
              
              // Main Toggle Button
              _buildGlassButton(
                icon: _isExtraMenuOpen ? Icons.close_rounded : Icons.grid_view_rounded,
                onPressed: () {
                  setState(() {
                    _isExtraMenuOpen = !_isExtraMenuOpen;
                    if (_isExtraMenuOpen) {
                      _menuAnimationController.forward();
                    } else {
                      _menuAnimationController.reverse();
                    }
                  });
                  if (_isExtraMenuOpen) _startHideTimer();
                },
                size: 60,
                color: _isExtraMenuOpen ? Colors.redAccent.withOpacity(0.3) : Colors.cyanAccent.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCircularButtons() {
    final features = [
      {'icon': Icons.speed_rounded, 'label': "${player.state.rate}x", 'onTap': _showPlaybackSpeedMenu},
      {'icon': _backgroundPlay ? Icons.headphones_rounded : Icons.headphones_outlined, 'label': "BG", 'onTap': () => setState(() => _backgroundPlay = !_backgroundPlay)},
      {'icon': Icons.picture_in_picture_alt_rounded, 'label': "Pop", 'onTap': () {}},
    ];

    final int count = features.length;
    // Spread in a half-circle on the left side:
    // 180 is direct left, so we spread from 120 to 240 degrees.
    const double startAngle = 120.0;
    const double endAngle = 240.0;

    return List.generate(count, (index) {
      final double angleDeg = count <= 1 
          ? 180.0 
          : startAngle + (index * ((endAngle - startAngle) / (count - 1)));
      final double angleRad = angleDeg * (math.pi / 180.0);
      const double radius = 100.0; // Spacing from the center button

      return AnimatedBuilder(
        animation: _menuAnimation,
        builder: (context, child) {
          final double currentRadius = radius * _menuAnimation.value;
          // Standard polar to cartesian conversion
          final double x = math.cos(angleRad) * currentRadius;
          final double y = math.sin(angleRad) * currentRadius;

          return Transform.translate(
            offset: Offset(x, y),
            child: Opacity(
              opacity: _menuAnimation.value.clamp(0.0, 1.0),
              child: _buildFeatureSubButton(
                icon: features[index]['icon'] as IconData,
                label: features[index]['label'] as String,
                onTap: features[index]['onTap'] as VoidCallback,
                size: 46,
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildFeatureSubButton({required IconData icon, required String label, required VoidCallback onTap, double size = 48, Color? color}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildGlassButton(icon: icon, onPressed: onTap, size: size, color: color?.withOpacity(0.3)),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black, blurRadius: 4)],
          ),
        ),
      ],
    );
  }

  void _showModernBottomSheet({required String title, required IconData icon, required Widget child}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      // The barrier color handles the "outside" area of the Center widget
      barrierColor: Colors.black45,
      builder: (context) => Stack(
        children: [
          // This layer catches any tap outside the menu but inside the sheet area
          GestureDetector(
            onTap: () => Navigator.pop(context),
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
          Center(
            child: GestureDetector(
              // IMPORTANT: This empty onTap prevents the menu from closing when you touch it
              onTap: () {}, 
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: MediaQuery.of(context).size.width > 600 ? 400 : double.infinity,
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF121212).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 50,
                      spreadRadius: 10,
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(35),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 15),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(25, 20, 25, 15),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.cyanAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(icon, color: Colors.cyanAccent, size: 22),
                              ),
                              const SizedBox(width: 15),
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close_rounded, color: Colors.white38),
                              ),
                            ],
                          ),
                        ),
                        const Divider(color: Colors.white10, height: 1),
                        // Wrap child in a way that it doesn't trigger dismissal
                        Flexible(child: child),
                        const SizedBox(height: 15),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0 
      ? "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds" 
      : "$twoDigitMinutes:$twoDigitSeconds";
  }
}

extension DurationClamp on Duration {
  Duration clamp(Duration min, Duration max) {
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }
}
