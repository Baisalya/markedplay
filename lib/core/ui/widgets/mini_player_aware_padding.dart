import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Pages/audio player/Audioplayerprovider.dart';
import '../../../Pages/videoplayer/VideoBackgroundProvider.dart';

class MiniPlayerAwarePadding extends StatelessWidget {
  final Widget child;
  final double basePadding;

  const MiniPlayerAwarePadding({
    super.key,
    required this.child,
    this.basePadding = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioPlayerProvider>();
    final videoProvider = context.watch<VideoBackgroundProvider>();

    bool isMiniPlayerVisible = audioProvider.currentFilePath != null ||
        videoProvider.currentFilePath != null;

    // Approximate height of MiniPlayer + some margin
    double bottomPadding = isMiniPlayerVisible ? 80.0 : 0.0;

    return Padding(
      padding: EdgeInsets.only(bottom: basePadding + bottomPadding),
      child: child,
    );
  }
}
