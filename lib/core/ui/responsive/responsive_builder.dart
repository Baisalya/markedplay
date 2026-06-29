import 'package:flutter/material.dart';
import 'app_breakpoints.dart';

typedef ResponsiveWidgetBuilder = Widget Function(
    BuildContext context, BoxConstraints constraints);

class ResponsiveBuilder extends StatelessWidget {
  final ResponsiveWidgetBuilder compact;
  final ResponsiveWidgetBuilder? medium;
  final ResponsiveWidgetBuilder? expanded;

  const ResponsiveBuilder({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppBreakpoints.medium) {
          return (expanded ?? medium ?? compact)(context, constraints);
        }
        if (constraints.maxWidth >= AppBreakpoints.compact) {
          return (medium ?? compact)(context, constraints);
        }
        return compact(context, constraints);
      },
    );
  }
}
