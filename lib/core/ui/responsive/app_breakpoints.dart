import 'package:flutter/material.dart';

class AppBreakpoints {
  static const double compact = 600.0;
  static const double medium = 1024.0;

  static bool isCompact(BuildContext context) =>
      MediaQuery.of(context).size.width < compact;

  static bool isMedium(BuildContext context) =>
      MediaQuery.of(context).size.width >= compact &&
      MediaQuery.of(context).size.width < medium;

  static bool isExpanded(BuildContext context) =>
      MediaQuery.of(context).size.width >= medium;
}
