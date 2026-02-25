import 'package:flutter/material.dart';

enum ViewMode { list, grid }
enum SortMode { name, date, size }

class MediaAppBarController extends ChangeNotifier {
  ViewMode viewMode = ViewMode.list;
  SortMode sortMode = SortMode.name;

  void toggleView() {
    viewMode =
    viewMode == ViewMode.list ? ViewMode.grid : ViewMode.list;
    notifyListeners();
  }

  void setSortMode(SortMode mode) {
    sortMode = mode;
    notifyListeners();
  }
}

class MediaAppBarWidget extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final MediaAppBarController controller;

  const MediaAppBarWidget({
    super.key,
    required this.title,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
        // 🔄 Grid / List Toggle
        IconButton(
          icon: Icon(
            controller.viewMode == ViewMode.list
                ? Icons.grid_view
                : Icons.list,
          ),
          onPressed: controller.toggleView,
        ),

        // 🔽 Sort Menu
        PopupMenuButton<SortMode>(
          icon: const Icon(Icons.sort),
          onSelected: controller.setSortMode,
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: SortMode.name,
              child: Text("Sort by Name"),
            ),
            PopupMenuItem(
              value: SortMode.date,
              child: Text("Sort by Date"),
            ),
            PopupMenuItem(
              value: SortMode.size,
              child: Text("Sort by Size"),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}