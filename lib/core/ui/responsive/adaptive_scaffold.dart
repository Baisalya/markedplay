import 'package:flutter/material.dart';
import 'app_breakpoints.dart';

class AdaptiveScaffold extends StatelessWidget {
  final Widget body;
  final Widget? drawer;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final List<NavigationRailDestination>? railDestinations;
  final int? selectedIndex;
  final ValueChanged<int>? onSelectedIndexChanged;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final Color? backgroundColor;

  const AdaptiveScaffold({
    super.key,
    required this.body,
    this.drawer,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.railDestinations,
    this.selectedIndex,
    this.onSelectedIndexChanged,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    bool isExpanded = AppBreakpoints.isExpanded(context);

    if (isExpanded &&
        railDestinations != null &&
        selectedIndex != null &&
        onSelectedIndexChanged != null) {
      return Scaffold(
        appBar: appBar,
        drawer: drawer,
        backgroundColor: backgroundColor,
        extendBody: extendBody,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        body: Row(
          children: [
            NavigationRail(
              extended: true,
              destinations: railDestinations!,
              selectedIndex: selectedIndex!,
              onDestinationSelected: onSelectedIndexChanged,
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: body),
          ],
        ),
        floatingActionButton: floatingActionButton,
      );
    }

    return Scaffold(
      appBar: appBar,
      drawer: drawer,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      backgroundColor: backgroundColor,
    );
  }
}
