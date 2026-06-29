import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/app_settings_provider.dart';
import '../../core/media_enums.dart';
import '../../core/services/playback_position_store.dart';
import '../audio player/Audioplayerprovider.dart';
import 'VideoBackgroundProvider.dart';
import '../../widgets/modern_widgets.dart';
import '../../core/ui/responsive/responsive_builder.dart';

enum _DragDirection { none, vertical, horizontal }

class VideoPlayerScreen extends StatefulWidget {
  final List<String> playlist;
  final int initialIndex;
  final Duration? initialPosition;

  const VideoPlayerScreen({
    super.key,
    required this.playlist,
    this.initialIndex = 0,
    this.initialPosition,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final Player player = Player();
  late final VideoController controller = VideoController(player);
  final PlaybackPositionStore _positionStore = const PlaybackPositionStore();

  late final List<String> _playlist;
  late int _currentIndex;
  String get _currentFilePath =>
      _playlist.isEmpty ? '' : _playlist[_currentIndex];

  bool _showControls = true;
  Timer? _hideTimer;
  bool _isLocked = false;
  late AnimationController _fadeController;
  late AnimationController _menuAnimationController;
  late Animation<double> _menuAnimation;
  bool _isFullScreen = true;
  bool _isExtraMenuOpen = false;
  bool _inBackgroundMode = false;
  BoxFit _videoFit = BoxFit.contain;
  double? _videoAspectRatio;
  double _scale = 1.0;
  double _baseScale = 1.0;

  Duration? _abStart;
  Duration? _abEnd;
  Timer? _indicatorTimer;
  _DragDirection _dragDirection = _DragDirection.none;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<bool>? _completedSubscription;
  StreamSubscription<String>? _errorSubscription;
  bool _handlingCompletion = false;
  bool _isOpening = true;
  String? _playbackError;
  int _lastPersistedSecond = -1;
  bool _resumeOnForeground = false;

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
    WidgetsBinding.instance.addObserver(this);
    _playlist = widget.playlist
        .where((item) => item.trim().isNotEmpty)
        .toSet()
        .toList(growable: false);
    _currentIndex = _playlist.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, _playlist.length - 1);
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
    _positionSubscription = player.stream.position.listen((position) {
      if (_abStart != null && _abEnd != null && position >= _abEnd!) {
        player.seek(_abStart!);
      }
      final seconds = position.inSeconds;
      if (_currentFilePath.isNotEmpty &&
          seconds > 0 &&
          seconds % 5 == 0 &&
          seconds != _lastPersistedSecond) {
        _lastPersistedSecond = seconds;
        unawaited(_saveLastPosition());
      }
    });
    _completedSubscription = player.stream.completed.listen((completed) {
      if (completed && !_handlingCompletion) {
        _handlingCompletion = true;
        unawaited(
          _handlePlaybackCompleted().whenComplete(() {
            _handlingCompletion = false;
          }),
        );
      }
    });
    _errorSubscription = player.stream.error.listen((error) {
      if (!mounted || error.trim().isEmpty) return;
      setState(() {
        _isOpening = false;
        _playbackError =
            'This video could not be played. It may be damaged or use an unsupported format.';
      });
    });
    _initialize();
  }

  Future<void> _initialize() async {
    final settings = Provider.of<AppSettingsProvider>(context, listen: false);
    final bgProvider =
        Provider.of<VideoBackgroundProvider>(context, listen: false);
    final audioProvider =
        Provider.of<AudioPlayerProvider>(context, listen: false);
    if (_playlist.isEmpty) {
      if (mounted) {
        setState(() {
          _isOpening = false;
          _playbackError = 'No video was provided to the player.';
        });
      }
      return;
    }

    await _initBrightnessAndVolume();
    _brightness =
        settings.brightnessGesture ? await ScreenBrightness().application : 1.0;
    _videoFit = _fitFor(settings.defaultAspectRatio);
    _videoAspectRatio = _aspectRatioFor(settings.defaultAspectRatio);
    Duration? startPosition = widget.initialPosition;

    if (audioProvider.isPlaying) {
      await audioProvider.pauseAudio();
    }

    if (bgProvider.currentFilePath == _currentFilePath) {
      startPosition ??= bgProvider.currentPosition;
      await bgProvider.stopBackgroundPlayback();
    } else {
      await bgProvider.stopBackgroundPlayback();
    }

    if (!mounted) return;
    await _openCurrentItem(
      requestedPosition: startPosition,
      useSavedPosition: settings.resumeLastPosition,
    );
    _startHideTimer();
  }

  BoxFit _fitFor(AspectRatioMode mode) => switch (mode) {
        AspectRatioMode.fill => BoxFit.cover,
        AspectRatioMode.stretch => BoxFit.fill,
        _ => BoxFit.contain,
      };

  double? _aspectRatioFor(AspectRatioMode mode) => switch (mode) {
        AspectRatioMode.sixteenNine => 16 / 9,
        AspectRatioMode.fourThree => 4 / 3,
        _ => null,
      };

  Future<void> _openCurrentItem({
    Duration? requestedPosition,
    bool useSavedPosition = true,
  }) async {
    if (_currentFilePath.isEmpty) return;
    final uri = Uri.tryParse(_currentFilePath);
    final isNetwork = uri?.isScheme('http') == true ||
        uri?.isScheme('https') == true ||
        uri?.isScheme('rtsp') == true ||
        uri?.isScheme('rtmp') == true;
    if (!isNetwork && !await File(_currentFilePath).exists()) {
      if (mounted) {
        setState(() {
          _isOpening = false;
          _playbackError =
              'This video has moved or is no longer available on this device.';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isOpening = true;
        _playbackError = null;
        _scale = 1.0;
        _abStart = null;
        _abEnd = null;
      });
    }
    if (!mounted) return;

    try {
      final settings = Provider.of<AppSettingsProvider>(context, listen: false);
      await player.open(Media(_currentFilePath), play: true);
      await player.setRate(settings.defaultPlaybackSpeed);
      if (!settings.showSubtitles) {
        await player.setSubtitleTrack(SubtitleTrack.no());
      }

      var position = requestedPosition;
      if (position == null && useSavedPosition) {
        position = await _positionStore.load(
          _currentFilePath,
          PlaybackMediaType.video,
        );
      }
      final duration = player.state.duration;
      if (position != null &&
          position > Duration.zero &&
          (duration == Duration.zero || position < duration)) {
        await player.seek(position);
      }
      await settings.addRecentlyPlayed(_currentFilePath);
      _lastPersistedSecond = -1;
      if (mounted) {
        setState(() => _isOpening = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isOpening = false;
        _playbackError =
            'MarkedPlay could not open this video. Try another file or format.';
      });
    }
  }

  Future<void> _handlePlaybackCompleted() async {
    if (_currentFilePath.isNotEmpty) {
      await _positionStore.clear(
        _currentFilePath,
        PlaybackMediaType.video,
      );
    }
    if (!mounted) return;
    final settings = Provider.of<AppSettingsProvider>(context, listen: false);
    if (settings.repeatMode == RepeatMode.one) {
      await player.seek(Duration.zero);
      await player.play();
      return;
    }
    if (settings.repeatMode == RepeatMode.all) {
      await _playNext(wrap: true);
      return;
    }
    if (settings.autoPlayNext && _currentIndex < _playlist.length - 1) {
      await _playNext(wrap: false);
    }
  }

  Future<void> _playNext({bool wrap = false}) async {
    if (_playlist.isEmpty) return;
    final settings = Provider.of<AppSettingsProvider>(context, listen: false);
    var nextIndex = _currentIndex;
    if (settings.shuffle && _playlist.length > 1) {
      while (nextIndex == _currentIndex) {
        nextIndex = math.Random().nextInt(_playlist.length);
      }
    } else if (_currentIndex < _playlist.length - 1) {
      nextIndex++;
    } else if (wrap) {
      nextIndex = 0;
    } else {
      return;
    }
    await _saveLastPosition();
    if (!mounted) return;
    setState(() => _currentIndex = nextIndex);
    await _openCurrentItem(useSavedPosition: settings.resumeLastPosition);
  }

  Future<void> _playPrevious() async {
    if (_playlist.isEmpty || _currentIndex <= 0) return;
    final settings = Provider.of<AppSettingsProvider>(context, listen: false);
    await _saveLastPosition();
    if (!mounted) return;
    setState(() => _currentIndex--);
    await _openCurrentItem(useSavedPosition: settings.resumeLastPosition);
  }

  Future<void> _initBrightnessAndVolume() async {
    try {
      _brightness = await ScreenBrightness().application;
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
    WidgetsBinding.instance.removeObserver(this);
    if (_inBackgroundMode) {
      try {
        Provider.of<VideoBackgroundProvider>(context, listen: false)
            .stopBackgroundPlayback();
      } catch (e) {
        debugPrint("Error stopping background audio: $e");
      }
    }
    // Restore preferred orientations to default
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Also ensure we set it back to portrait if that's what the app expects
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);

    unawaited(_saveLastPosition());
    _hideTimer?.cancel();
    _indicatorTimer?.cancel();
    _positionSubscription?.cancel();
    _completedSubscription?.cancel();
    _errorSubscription?.cancel();
    _fadeController.dispose();
    _menuAnimationController.dispose();
    VolumeController.instance.showSystemUI = true;
    unawaited(ScreenBrightness().resetApplicationScreenBrightness());
    player.dispose();
    super.dispose();
  }

  Future<void> _saveLastPosition() async {
    if (_currentFilePath.isEmpty) return;
    final position = player.state.position;
    final duration = player.state.duration;
    final settings = Provider.of<AppSettingsProvider>(context, listen: false);
    if (!settings.resumeLastPosition) {
      await _positionStore.clear(
        _currentFilePath,
        PlaybackMediaType.video,
      );
      return;
    }
    await _positionStore.save(
      _currentFilePath,
      PlaybackMediaType.video,
      position,
      duration: duration,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final settings = Provider.of<AppSettingsProvider>(context, listen: false);
    final videoBgProvider =
        Provider.of<VideoBackgroundProvider>(context, listen: false);

    if (state == AppLifecycleState.paused) {
      if (player.state.playing) {
        _resumeOnForeground = true;
        if (settings.backgroundPlayMode == BackgroundPlayMode.audioOnly) {
          _inBackgroundMode = true;
          final currentPosition = player.state.position;
          unawaited(player.pause());
          unawaited(
            videoBgProvider.playVideoAsAudio(
              _currentFilePath,
              _playlist,
              _currentIndex,
              startPosition: currentPosition,
            ),
          );
        } else {
          unawaited(player.pause());
          unawaited(_saveLastPosition());
        }
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_inBackgroundMode) {
        final bgPosition = videoBgProvider.currentPosition;
        final wasPlaying = videoBgProvider.isPlaying;
        unawaited(videoBgProvider.pauseAudio());

        unawaited(player.seek(bgPosition));
        if (wasPlaying) {
          unawaited(player.play());
        } else {
          unawaited(player.pause());
        }
        _inBackgroundMode = false;
        _resumeOnForeground = false;
        setState(() {});
      } else if (_resumeOnForeground) {
        _resumeOnForeground = false;
        unawaited(player.play());
      }
    }
  }

  // Gesture Handlers
  void _onScaleStart(ScaleStartDetails details) {
    _baseScale = _scale;
    _dragDirection = _DragDirection.none;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_isLocked) return;

    if (details.pointerCount > 1) {
      _dragDirection = _DragDirection.none;
      setState(() {
        _scale = (_baseScale * details.scale).clamp(1.0, 5.0);
      });
      return;
    }

    if (_dragDirection == _DragDirection.none) {
      if (details.focalPointDelta.dx.abs() > details.focalPointDelta.dy.abs()) {
        _dragDirection = _DragDirection.horizontal;
      } else if (details.focalPointDelta.dy.abs() >
          details.focalPointDelta.dx.abs()) {
        _dragDirection = _DragDirection.vertical;
      }
    }

    if (_dragDirection == _DragDirection.vertical) {
      _handleVerticalUpdate(details);
    } else if (_dragDirection == _DragDirection.horizontal) {
      _handleHorizontalUpdate(details);
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (_dragDirection == _DragDirection.horizontal) {
      _handleHorizontalEnd();
    } else if (_dragDirection == _DragDirection.vertical) {
      _hideIndicators();
    }
    _dragDirection = _DragDirection.none;
    _startHideTimer();
  }

  void _handleVerticalUpdate(ScaleUpdateDetails details) {
    final settings = Provider.of<AppSettingsProvider>(context, listen: false);
    double delta =
        details.focalPointDelta.dy / MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    if (details.localFocalPoint.dx < width / 2) {
      if (!settings.brightnessGesture) return;
      setState(() {
        _showBrightnessIndicator = true;
        _showVolumeIndicator = false;
        _brightness = (_brightness - delta).clamp(0.0, 1.0);
      });
      ScreenBrightness().setApplicationScreenBrightness(_brightness);
    } else {
      if (!settings.volumeGesture) return;
      setState(() {
        _showVolumeIndicator = true;
        _showBrightnessIndicator = false;
        _volume = (_volume - delta).clamp(0.0, 1.0);
      });
      VolumeController.instance.setVolume(_volume);
    }
    _indicatorTimer?.cancel();
  }

  void _handleHorizontalUpdate(ScaleUpdateDetails details) {
    final settings = Provider.of<AppSettingsProvider>(context, listen: false);
    if (!settings.seekGesture) return;
    double delta =
        details.focalPointDelta.dx / MediaQuery.of(context).size.width;
    Duration duration = player.state.duration;
    if (duration == Duration.zero) return;

    int seekMillis = (delta * duration.inMilliseconds * 0.5).toInt();

    setState(() {
      _showSeekIndicator = true;
      if (_tempSeekPosition == Duration.zero) {
        _tempSeekPosition = player.state.position;
      }
      _tempSeekPosition += Duration(milliseconds: seekMillis);
      _tempSeekPosition = _tempSeekPosition.clamp(Duration.zero, duration);
    });
  }

  void _handleHorizontalEnd() {
    if (_showSeekIndicator) {
      player.seek(_tempSeekPosition);
      setState(() {
        _showSeekIndicator = false;
        _tempSeekPosition = Duration.zero;
      });
    }
  }

  void _seekRelative(int seconds) {
    final duration = player.state.duration;
    var target = player.state.position + Duration(seconds: seconds);
    if (target < Duration.zero) target = Duration.zero;
    if (duration > Duration.zero && target > duration) target = duration;
    player.seek(target);
  }

  Widget _buildPlaybackErrorOverlay() {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.88),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.video_file_outlined,
                  color: Colors.white70,
                  size: 64,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Video unavailable',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _playbackError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _openCurrentItem,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try again'),
                    ),
                    OutlinedButton(
                      onPressed: () => Navigator.maybePop(context),
                      child: const Text('Go back'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.space): () =>
            player.playOrPause(),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            _seekRelative(-settings.seekStep),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            _seekRelative(settings.seekStep),
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.pop(context),
        const SingleActivator(LogicalKeyboardKey.keyF): _toggleRotation,
      },
      child: Focus(
        autofocus: true,
        child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;

              if (player.state.playing) {
                if (settings.backgroundPlayMode ==
                    BackgroundPlayMode.audioOnly) {
                  final videoBgProvider = Provider.of<VideoBackgroundProvider>(
                      context,
                      listen: false);
                  await videoBgProvider.playVideoAsAudio(
                    _currentFilePath,
                    _playlist,
                    _currentIndex,
                    startPosition: player.state.position,
                  );
                  if (context.mounted) Navigator.pop(context);
                } else if (settings.backgroundPlayMode ==
                    BackgroundPlayMode.pip) {
                  Navigator.pop(context);
                } else if (settings.backgroundPlayMode ==
                    BackgroundPlayMode.askEveryTime) {
                  final choice = await _showBackgroundPlayChoice();
                  if (!context.mounted) return;
                  if (choice == 'background') {
                    final videoBgProvider =
                        Provider.of<VideoBackgroundProvider>(context,
                            listen: false);
                    await videoBgProvider.playVideoAsAudio(
                        _currentFilePath, _playlist, _currentIndex,
                        startPosition: player.state.position);
                    if (context.mounted) Navigator.pop(context);
                  } else if (choice == 'stop') {
                    if (context.mounted) Navigator.pop(context);
                  }
                } else {
                  Navigator.pop(context);
                }
              } else {
                Navigator.pop(context);
              }
            },
            child: Scaffold(
              backgroundColor: Colors.black,
              body: GestureDetector(
                onTap: _toggleControls,
                onScaleStart: _onScaleStart,
                onScaleUpdate: _onScaleUpdate,
                onScaleEnd: _onScaleEnd,
                onDoubleTapDown: (details) {
                  if (_isLocked) return;
                  final settings =
                      Provider.of<AppSettingsProvider>(context, listen: false);
                  if (!settings.doubleTapSeek) return;

                  final width = MediaQuery.of(context).size.width;
                  final seekStep = Duration(seconds: settings.seekStep);

                  if (details.localPosition.dx < width / 2) {
                    _seekRelative(-seekStep.inSeconds);
                  } else {
                    _seekRelative(seekStep.inSeconds);
                  }
                },
                child: Stack(
                  children: [
                    Center(
                      child: Transform.scale(
                        scale: _scale,
                        child: Video(
                          controller: controller,
                          controls: NoVideoControls,
                          fit: _videoFit,
                          aspectRatio: _videoAspectRatio,
                          wakelock: settings.keepScreenAwake,
                          pauseUponEnteringBackgroundMode: false,
                          resumeUponEnteringForegroundMode: false,
                          subtitleViewConfiguration: SubtitleViewConfiguration(
                            visible: settings.showSubtitles,
                            style: TextStyle(
                              height: 1.35,
                              fontSize: settings.subtitleSize,
                              color: settings.subtitleColor,
                              backgroundColor: settings.subtitleBackgroundColor,
                            ),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                          ),
                        ),
                      ),
                    ),

                    if (_isOpening)
                      const Center(
                        child:
                            CircularProgressIndicator(color: Colors.cyanAccent),
                      ),
                    if (_playbackError != null) _buildPlaybackErrorOverlay(),

                    // Gesture Overlays
                    if (_showBrightnessIndicator)
                      _buildCircularIndicator(Icons.brightness_6_rounded,
                          _brightness, Colors.orange),
                    if (_showVolumeIndicator)
                      _buildCircularIndicator(
                          Icons.volume_up_rounded, _volume, Colors.cyan),
                    if (_showSeekIndicator) _buildSeekOverlay(),

                    // Controls
                    if (_playbackError == null)
                      FadeTransition(
                        opacity: _fadeController,
                        child: IgnorePointer(
                          ignoring: !_showControls,
                          child:
                              _isLocked ? _buildLockedUI() : _buildControlsUI(),
                        ),
                      ),

                    // Floating Feature Buttons
                    if (_playbackError == null &&
                        _showControls &&
                        !_isLocked) ...[
                      _buildRotationButton(),
                      _buildExpandableFeatureButton(),
                    ],
                  ],
                ),
              ),
            )),
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
      child: ResponsiveBuilder(
        compact: (context, constraints) => _buildTopBarContent(compact: true),
        medium: (context, constraints) => _buildTopBarContent(compact: false),
        expanded: (context, constraints) => _buildTopBarContent(compact: false),
      ),
    );
  }

  Widget _buildTopBarContent({required bool compact}) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final isPortrait = orientation == Orientation.portrait;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              _buildGlassButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _currentFilePath.split('/').last,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 14 : 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (!isPortrait && !compact)
                      Text(
                        _currentFilePath,
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isPortrait && !compact) ...[
                    _buildGlassButton(
                      icon: Icons.audiotrack_rounded,
                      onPressed: _showAudioTracks,
                      size: 40,
                    ),
                    const SizedBox(width: 6),
                    _buildGlassButton(
                      icon: Icons.subtitles_rounded,
                      onPressed: _showSubtitleTracks,
                      size: 40,
                    ),
                    const SizedBox(width: 6),
                  ],
                  _buildGlassButton(
                    icon: Icons.more_vert_rounded,
                    onPressed: _showMoreSettings,
                    size: 40,
                  ),
                  const SizedBox(width: 6),
                  _buildGlassButton(
                    icon: Provider.of<AppSettingsProvider>(context)
                            .favorites
                            .contains(_currentFilePath)
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    onPressed: () =>
                        Provider.of<AppSettingsProvider>(context, listen: false)
                            .toggleFavorite(_currentFilePath),
                    size: 40,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      top: false,
      child: OrientationBuilder(
        builder: (context, orientation) {
          final isPortrait = orientation == Orientation.portrait;
          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1000),
              padding: EdgeInsets.symmetric(
                horizontal: isPortrait ? 12 : 16,
                vertical: isPortrait ? 5 : 10,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildProgressBar(),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      StreamBuilder<Duration>(
                        stream: player.stream.position,
                        builder: (context, snapshot) {
                          return Text(
                            _formatDuration(snapshot.data ?? Duration.zero),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                      const Spacer(),
                      Text(
                        _formatDuration(player.state.duration),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isPortrait ? 8 : 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildGlassButton(
                        icon: Icons.lock_open_rounded,
                        onPressed: () => setState(() {
                          _isLocked = true;
                          _showControls = true;
                          _startHideTimer();
                        }),
                        size: isPortrait ? 40 : 44,
                      ),
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildGlassButton(
                              icon: Icons.skip_previous_rounded,
                              onPressed:
                                  _currentIndex > 0 ? _playPrevious : null,
                              size: isPortrait ? 44 : 48,
                              color: _currentIndex > 0
                                  ? Colors.cyanAccent.withOpacity(0.1)
                                  : Colors.white.withOpacity(0.05),
                            ),
                            SizedBox(width: isPortrait ? 15 : 25),
                            StreamBuilder<bool>(
                              stream: player.stream.playing,
                              builder: (context, snapshot) {
                                final isPlaying = snapshot.data ?? false;
                                return Container(
                                  height: isPortrait ? 56 : 64,
                                  width: isPortrait ? 56 : 64,
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
                                        color:
                                            Colors.cyanAccent.withOpacity(0.2),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    iconSize: isPortrait ? 32 : 38,
                                    padding: EdgeInsets.zero,
                                    icon: Icon(
                                      isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: Colors.white,
                                    ),
                                    onPressed: () => player.playOrPause(),
                                  ),
                                );
                              },
                            ),
                            SizedBox(width: isPortrait ? 15 : 25),
                            _buildGlassButton(
                              icon: Icons.skip_next_rounded,
                              onPressed: _currentIndex < _playlist.length - 1
                                  ? _playNext
                                  : null,
                              size: isPortrait ? 44 : 48,
                              color: _currentIndex < _playlist.length - 1
                                  ? Colors.cyanAccent.withOpacity(0.1)
                                  : Colors.white.withOpacity(0.05),
                            ),
                          ],
                        ),
                      ),
                      _buildGlassButton(
                        icon: _getFitIcon(),
                        onPressed: _toggleVideoFit,
                        size: isPortrait ? 40 : 44,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          );
        },
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
            value: position.inMilliseconds
                .toDouble()
                .clamp(0, duration.inMilliseconds.toDouble()),
            max: duration.inMilliseconds.toDouble() == 0
                ? 1
                : duration.inMilliseconds.toDouble(),
            onChanged: (v) => player.seek(Duration(milliseconds: v.toInt())),
          ),
        );
      },
    );
  }

  // UI Components
  Widget _buildGlassButton({
    required IconData icon,
    VoidCallback? onPressed,
    double size = 44,
    Color? color,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: () {
        if (onPressed != null) {
          HapticFeedback.lightImpact();
          onPressed();
        }
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    (color ?? Colors.white).withValues(alpha: 0.2),
                    (color ?? Colors.white).withValues(alpha: 0.05),
                  ],
                ),
                border: Border.all(
                  color: (color ?? Colors.white).withValues(alpha: 0.3),
                  width: 1.2,
                ),
              ),
              child: Icon(
                icon,
                color: iconColor ?? Colors.white,
                size: size * 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircularIndicator(IconData icon, double value, Color color) {
    return Center(
      child: GlassCard(
        borderRadius: 100,
        blur: 15,
        color: Colors.black.withOpacity(0.3),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 40),
              const SizedBox(height: 8),
              Text(
                "${(value * 100).toInt()}%",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
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
                const Icon(Icons.fast_forward_rounded,
                    color: Colors.cyanAccent, size: 40),
                const SizedBox(height: 12),
                Text(
                  _formatDuration(_tempSeekPosition),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
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
  Future<String?> _showBackgroundPlayChoice() async {
    return await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10))),
          const Padding(
            padding: const EdgeInsets.all(20),
            child: Text("Background Playback",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading:
                const Icon(Icons.headphones_rounded, color: Colors.cyanAccent),
            title: const Text("Continue as Audio",
                style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context, 'background'),
          ),
          ListTile(
            leading:
                const Icon(Icons.stop_circle_rounded, color: Colors.redAccent),
            title: const Text("Stop Playback",
                style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context, 'stop'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showAudioTracks() {
    final tracks = player.state.tracks.audio;
    _showModernBottomSheet(
      title: "Audio Tracks",
      icon: Icons.audiotrack_rounded,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tracks.length,
        itemBuilder: (context, i) {
          final isSelected = player.state.track.audio == tracks[i];
          final trackName = tracks[i].title ?? "Track ${i + 1}";
          final lang = tracks[i].language ?? "Unknown Language";

          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.cyanAccent.withOpacity(0.1)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.music_note_rounded,
                color: isSelected ? Colors.cyanAccent : Colors.white60,
                size: 20,
              ),
            ),
            title: Text(
              trackName,
              style: TextStyle(
                color: isSelected ? Colors.cyanAccent : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              lang,
              style: TextStyle(
                  color: isSelected
                      ? Colors.cyanAccent.withOpacity(0.5)
                      : Colors.white38),
            ),
            trailing: isSelected
                ? const Icon(Icons.check_circle_rounded,
                    color: Colors.cyanAccent, size: 20)
                : null,
            onTap: () {
              player.setAudioTrack(tracks[i]);
              Navigator.pop(context);
              setState(() {});
            },
          );
        },
      ),
    );
  }

  void _showSubtitleTracks() {
    final tracks = player.state.tracks.subtitle;
    _showModernBottomSheet(
      title: "Subtitles",
      icon: Icons.subtitles_rounded,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.file_open_rounded,
                  color: Colors.cyanAccent, size: 20),
            ),
            title: const Text("Load External Subtitle",
                style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(context);
              try {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['srt', 'vtt', 'ass'],
                );
                if (result != null && result.files.single.path != null) {
                  await player.setSubtitleTrack(
                    SubtitleTrack.uri(result.files.single.path!),
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                        content: Text("Subtitle loaded successfully")),
                  );
                  setState(() {});
                }
              } catch (e) {
                debugPrint("Error picking file: $e");
              }
            },
          ),
          const Divider(color: Colors.white10, indent: 20, endIndent: 20),

          // "None" option
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: player.state.track.subtitle == SubtitleTrack.no()
                    ? Colors.cyanAccent.withOpacity(0.1)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.subtitles_off_rounded,
                color: player.state.track.subtitle == SubtitleTrack.no()
                    ? Colors.cyanAccent
                    : Colors.white60,
                size: 20,
              ),
            ),
            title: Text(
              "None",
              style: TextStyle(
                color: player.state.track.subtitle == SubtitleTrack.no()
                    ? Colors.cyanAccent
                    : Colors.white,
                fontWeight: player.state.track.subtitle == SubtitleTrack.no()
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            trailing: player.state.track.subtitle == SubtitleTrack.no()
                ? const Icon(Icons.check_circle_rounded,
                    color: Colors.cyanAccent, size: 20)
                : null,
            onTap: () {
              player.setSubtitleTrack(SubtitleTrack.no());
              Navigator.pop(context);
              setState(() {});
            },
          ),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tracks.length,
            itemBuilder: (context, i) {
              if (tracks[i] == SubtitleTrack.no())
                return const SizedBox.shrink();

              final isSelected = player.state.track.subtitle == tracks[i];
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.cyanAccent.withOpacity(0.1)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.closed_caption_rounded,
                    color: isSelected ? Colors.cyanAccent : Colors.white60,
                    size: 20,
                  ),
                ),
                title: Text(
                  tracks[i].title ?? "Subtitle ${i + 1}",
                  style: TextStyle(
                    color: isSelected ? Colors.cyanAccent : Colors.white,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  tracks[i].language ?? "Unknown Language",
                  style: TextStyle(
                      color: isSelected
                          ? Colors.cyanAccent.withOpacity(0.5)
                          : Colors.white38),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded,
                        color: Colors.cyanAccent, size: 20)
                    : null,
                onTap: () {
                  player.setSubtitleTrack(tracks[i]);
                  Navigator.pop(context);
                  setState(() {});
                },
              );
            },
          ),
        ],
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
            title: const Text("Playback Speed",
                style: TextStyle(color: Colors.white)),
            trailing: Text("${player.state.rate}x",
                style: const TextStyle(color: Colors.cyanAccent)),
            onTap: _showPlaybackSpeedMenu,
          ),
          ListTile(
            leading: const Icon(Icons.color_lens_rounded, color: Colors.white),
            title: const Text("Display Brightness",
                style: TextStyle(color: Colors.white)),
            onTap: _showVideoColorControls,
          ),
          ListTile(
            leading:
                const Icon(Icons.aspect_ratio_rounded, color: Colors.white),
            title:
                const Text("Fit Screen", style: TextStyle(color: Colors.white)),
            trailing: Text(_videoFit.name.toUpperCase(),
                style: const TextStyle(color: Colors.cyanAccent)),
            onTap: () {
              _toggleVideoFit();
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading:
                const Icon(Icons.info_outline_rounded, color: Colors.white),
            title: const Text("Playback Info",
                style: TextStyle(color: Colors.white)),
            onTap: _showPlaybackInfo,
          ),
        ],
      ),
    );
  }

  void _showVideoColorControls() {
    Navigator.pop(context);
    _showModernBottomSheet(
      title: "Display Brightness",
      icon: Icons.color_lens_rounded,
      child: StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildColorSlider("Brightness", _brightness, 0.0, 1.0, (v) {
                setSheetState(() => _brightness = v);
                ScreenBrightness().setApplicationScreenBrightness(v);
              }),
              TextButton.icon(
                onPressed: () async {
                  await ScreenBrightness().resetApplicationScreenBrightness();
                  final value = await ScreenBrightness().application;
                  setSheetState(() => _brightness = value);
                },
                icon: const Icon(Icons.brightness_auto_rounded),
                label: const Text('Use system brightness'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorSlider(String label, double value, double min, double max,
      Function(double) onChanged) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white)),
            Text(value.toStringAsFixed(2),
                style: const TextStyle(color: Colors.cyanAccent)),
          ],
        ),
        Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
            activeColor: Colors.cyanAccent),
      ],
    );
  }

  void _showPlaybackInfo() {
    Navigator.pop(context); // Close more settings sheet
    final state = player.state;
    final track = state.track;

    _showModernBottomSheet(
      title: "Playback Info",
      icon: Icons.info_outline_rounded,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _diagRow("Resolution", "${state.width} x ${state.height}"),
            _diagRow("Audio Track", track.audio.title ?? "Unknown"),
            _diagRow("Subtitle Track", track.subtitle.title ?? "None"),
            _diagRow("Playback Speed", "${state.rate}x"),
            _diagRow(
                "Video Format", _currentFilePath.split('.').last.toUpperCase()),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _diagRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value,
              style: const TextStyle(
                  color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
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
          final currentRate = player.state.rate;

          return Container(
            height: 160,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Stack(
              alignment: Alignment.center,
              children: [
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
                IgnorePointer(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) =>
                            ScaleTransition(scale: anim, child: child),
                        child: Text(
                          "${currentRate.toStringAsFixed(2)}x",
                          key: ValueKey(currentRate),
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                            shadows: [
                              Shadow(color: Colors.cyanAccent, blurRadius: 10)
                            ],
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
                ...List.generate(speeds.length, (index) {
                  final double angle =
                      (index * (math.pi * 1.1) / (speeds.length - 1)) -
                          (math.pi * 1.05);
                  const double radius = 70.0;
                  final double x = math.cos(angle) * radius;
                  final double y = math.sin(angle) * radius;

                  final isSelected = (currentRate - speeds[index]).abs() < 0.01;

                  return Transform.translate(
                    offset: Offset(x, y),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        player.setRate(speeds[index]);
                        setSheetState(() {});
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
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? Colors.cyanAccent
                                : Colors.white.withOpacity(0.1),
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.white24,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.cyanAccent.withOpacity(0.4),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : [],
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
    // Brief delay to allow orientation change to settle before showing controls/timer
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _startHideTimer();
    });
  }

  void _toggleVideoFit() {
    setState(() {
      _videoAspectRatio = null;
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

  void _toggleABRepeat() {
    setState(() {
      if (_abStart == null) {
        _abStart = player.state.position;
      } else if (_abEnd == null) {
        _abEnd = player.state.position;
        if (_abEnd! <= _abStart!) {
          _abStart = null;
          _abEnd = null;
        }
      } else {
        _abStart = null;
        _abEnd = null;
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
    final orientation = MediaQuery.of(context).orientation;
    final isPortrait = orientation == Orientation.portrait;
    return Positioned(
      left: isPortrait ? 15 : 30,
      bottom: isPortrait ? 120 : 80,
      child: _buildGlassButton(
        icon: _isFullScreen
            ? Icons.screen_rotation_rounded
            : Icons.screen_lock_portrait_rounded,
        onPressed: _toggleRotation,
        size: isPortrait ? 50 : 56,
        color: Colors.white,
      ),
    );
  }

  Widget _buildExpandableFeatureButton() {
    final orientation = MediaQuery.of(context).orientation;
    final isPortrait = orientation == Orientation.portrait;
    return Positioned(
      right: isPortrait ? 15 : 30,
      bottom: isPortrait ? 120 : null,
      top: isPortrait ? null : 0,
      child: Center(
        child: SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ..._buildCircularButtons(),
              _buildGlassButton(
                icon: _isExtraMenuOpen
                    ? Icons.close_rounded
                    : Icons.grid_view_rounded,
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
                size: isPortrait ? 54 : 60,
                color: _isExtraMenuOpen ? Colors.redAccent : Colors.cyanAccent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCircularButtons() {
    final settings = Provider.of<AppSettingsProvider>(context, listen: false);
    final features = [
      {
        'icon': Icons.speed_rounded,
        'label': "${player.state.rate}x",
        'onTap': _showPlaybackSpeedMenu
      },
      {
        'icon': settings.backgroundPlayMode != BackgroundPlayMode.off
            ? Icons.headphones_rounded
            : Icons.headphones_outlined,
        'label': "BG",
        'onTap': () {
          if (settings.backgroundPlayMode == BackgroundPlayMode.off) {
            settings.setBackgroundPlayMode(BackgroundPlayMode.audioOnly);
          } else {
            settings.setBackgroundPlayMode(BackgroundPlayMode.off);
          }
          setState(() {});
        },
        'color': settings.backgroundPlayMode != BackgroundPlayMode.off
            ? Colors.cyanAccent
            : null,
      },
      {
        'icon': Icons.repeat_rounded,
        'label': settings.repeatMode.name.toUpperCase(),
        'onTap': () {
          final nextMode = RepeatMode.values[
              (settings.repeatMode.index + 1) % RepeatMode.values.length];
          settings.setRepeatMode(nextMode);
          setState(() {});
        }
      },
      {
        'icon': Icons.loop_rounded,
        'label': _abStart == null ? "A-B" : (_abEnd == null ? "A-" : "A-B ON"),
        'onTap': _toggleABRepeat
      },
      {
        'icon': Icons.aspect_ratio_rounded,
        'label': "Fit",
        'onTap': _toggleVideoFit
      },
    ];

    final int count = features.length;
    const double startAngle = 120.0;
    const double endAngle = 240.0;

    return List.generate(count, (index) {
      final double angleDeg = count <= 1
          ? 180.0
          : startAngle + (index * ((endAngle - startAngle) / (count - 1)));
      final double angleRad = angleDeg * (math.pi / 180.0);
      const double radius = 100.0;

      return AnimatedBuilder(
        animation: _menuAnimation,
        builder: (context, child) {
          final double currentRadius = radius * _menuAnimation.value;
          final double x = math.cos(angleRad) * currentRadius;
          final double y = math.sin(angleRad) * currentRadius;

          return Transform.translate(
            offset: Offset(x, y),
            child: IgnorePointer(
              ignoring: !_isExtraMenuOpen,
              child: Opacity(
                opacity: _menuAnimation.value.clamp(0.0, 1.0),
                child: _buildFeatureSubButton(
                  icon: features[index]['icon'] as IconData,
                  label: features[index]['label'] as String,
                  onTap: features[index]['onTap'] as VoidCallback,
                  size: 46,
                  color: features[index]['color'] as Color?,
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildFeatureSubButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    double size = 48,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildGlassButton(
            icon: icon,
            onPressed: onTap,
            size: size,
            color: color?.withOpacity(0.3),
            iconColor: color,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }

  void _showModernBottomSheet(
      {required String title, required IconData icon, required Widget child}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black45,
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {},
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: MediaQuery.of(context).size.width > 600
                    ? 500
                    : double.infinity,
                margin: EdgeInsets.fromLTRB(
                    20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
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
                                child: Icon(icon,
                                    color: Colors.cyanAccent, size: 22),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close_rounded,
                                    color: Colors.white38),
                              ),
                            ],
                          ),
                        ),
                        const Divider(color: Colors.white10, height: 1),
                        Flexible(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.of(context).size.height * 0.6,
                            ),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: child,
                            ),
                          ),
                        ),
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
