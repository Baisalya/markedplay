import 'dart:async';
import 'package:flutter/material.dart';
class AutoScrollText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final double fontSize;
  final Duration scrollDuration;

  AutoScrollText({
    required this.text,
    required this.style,
    this.fontSize = 26.0,
    this.scrollDuration = const Duration(seconds: 10),
  });

  @override
  _AutoScrollTextState createState() => _AutoScrollTextState();
}

class _AutoScrollTextState extends State<AutoScrollText> {
  late ScrollController _scrollController;
  Timer? _timer;
  double _textWidth = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _startScrolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startScrolling() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final TextPainter textPainter = TextPainter(
        text: TextSpan(text: widget.text, style: widget.style),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout();

      setState(() {
        _textWidth = textPainter.size.width;
      });

      _timer = Timer.periodic(widget.scrollDuration, (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_scrollController.hasClients) {
          double maxScrollExtent = _scrollController.position.maxScrollExtent;
          double nextOffset = _scrollController.offset + 50.0; // Scroll by 50 units

          if (nextOffset > maxScrollExtent) {
            nextOffset = 0;
            _scrollController.jumpTo(0);
          } else {
            _scrollController.animateTo(
              nextOffset,
              duration: widget.scrollDuration,
              curve: Curves.linear,
            );
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.fontSize * 1.2,
      child: ListView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        children: [
          Text(
            widget.text,
            style: widget.style,
          ),
          SizedBox(width: _textWidth), // Add empty space to create a loop effect
        ],
      ),
    );
  }
}


