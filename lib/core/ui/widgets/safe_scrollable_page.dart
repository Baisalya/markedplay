import 'package:flutter/material.dart';

class SafeScrollablePage extends StatelessWidget {
  final Widget child;
  final List<Widget>? slivers;
  final EdgeInsetsGeometry? padding;
  final bool useSafeArea;

  const SafeScrollablePage({
    super.key,
    this.child = const SizedBox.shrink(),
    this.slivers,
    this.padding,
    this.useSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (slivers != null) {
      content = CustomScrollView(
        slivers: slivers!,
      );
    } else {
      content = SingleChildScrollView(
        padding: padding,
        child: child,
      );
    }

    if (useSafeArea) {
      return SafeArea(child: content);
    }
    return content;
  }
}
