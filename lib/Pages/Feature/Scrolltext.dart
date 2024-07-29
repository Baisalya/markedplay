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
  late Timer _timer;
  double _textWidth = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _startScrolling();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _timer.cancel();
    super.dispose();
  }

  void _startScrolling() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final textKey = GlobalKey();
      final textWidget = Text(widget.text, style: widget.style, key: textKey);

      // Render the text widget to get its width
      final textRenderBox = textKey.currentContext?.findRenderObject() as RenderBox?;
      if (textRenderBox != null) {
        _textWidth = textRenderBox.size.width;
        _scrollController.jumpTo(0);
        _timer = Timer.periodic(widget.scrollDuration, (timer) {
          _scrollController.animateTo(
            _scrollController.offset >= _textWidth ? 0 : _scrollController.offset + _textWidth,
            duration: Duration(milliseconds: 500),
            curve: Curves.linear,
          );
        });
      }
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


