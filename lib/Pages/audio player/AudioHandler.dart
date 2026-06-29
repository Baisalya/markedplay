import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class MyAudioHandler extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer();
  Future<void> Function()? _onAudioSkipToNext;
  Future<void> Function()? _onAudioSkipToPrevious;
  Future<void> Function()? _onVideoSkipToNext;
  Future<void> Function()? _onVideoSkipToPrevious;
  Duration _seekStep = const Duration(seconds: 10);
  static final _notificationClickController =
      StreamController<bool>.broadcast();
  static Stream<bool> get notificationClickStream =>
      _notificationClickController.stream;

  MyAudioHandler() {
    _player.playbackEventStream.map(_transformEvent).listen((state) {
      playbackState.add(state);
    });

    _player.durationStream.listen((duration) {
      if (duration != null && mediaItem.value != null) {
        mediaItem.add(mediaItem.value!.copyWith(duration: duration));
      }
    });

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.completed,
        ));
      }
    });
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> fastForward() {
    final duration = _player.duration;
    var target = _player.position + _seekStep;
    if (duration != null && target > duration) target = duration;
    return seek(target);
  }

  @override
  Future<void> rewind() {
    var target = _player.position - _seekStep;
    if (target < Duration.zero) target = Duration.zero;
    return seek(target);
  }

  @override
  Future<void> skipToNext() async {
    if (mediaItem.value?.extras?['type'] == 'video') {
      await _onVideoSkipToNext?.call();
    } else {
      await _onAudioSkipToNext?.call();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (mediaItem.value?.extras?['type'] == 'video') {
      await _onVideoSkipToPrevious?.call();
    } else {
      await _onAudioSkipToPrevious?.call();
    }
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }

  Future<void> setAudioSource(String filePath, MediaItem item) async {
    await _player.setFilePath(filePath);
    mediaItem.add(item.copyWith(duration: _player.duration ?? item.duration));
  }

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  void configureControls({
    Future<void> Function()? onSkipToNext,
    Future<void> Function()? onSkipToPrevious,
    Duration? seekStep,
  }) {
    _onAudioSkipToNext = onSkipToNext;
    _onAudioSkipToPrevious = onSkipToPrevious;
    if (seekStep != null) _seekStep = seekStep;
  }

  void configureVideoControls({
    Future<void> Function()? onSkipToNext,
    Future<void> Function()? onSkipToPrevious,
  }) {
    _onVideoSkipToNext = onSkipToNext;
    _onVideoSkipToPrevious = onSkipToPrevious;
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.loading,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.ready: AudioProcessingState.ready,
            ProcessingState.completed: AudioProcessingState.completed,
          }[_player.processingState] ??
          AudioProcessingState.idle,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  @override
  Future<void> click([MediaButton button = MediaButton.media]) async {
    _notificationClickController.add(true);
    super.click(button);
  }

  AudioPlayer get player => _player;
}
