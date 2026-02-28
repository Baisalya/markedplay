import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Pages/Settings/SettingsScreen.dart';
import '../core/app_settings_provider.dart';
import '../core/media_enums.dart';
import '../core/theme_helper.dart';

class ModernDrawer extends StatelessWidget {
  final ViewMode currentViewMode;
  final SortMode currentSortMode;
  final Function(ViewMode) onViewChanged;
  final Function(SortMode) onSortChanged;

  const ModernDrawer({
    super.key,
    required this.currentViewMode,
    required this.currentSortMode,
    required this.onViewChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {

    final settings = context.watch<AppSettingsProvider>();
    final theme = settings.theme;

    final primaryColor = ThemeHelper.primary(
      theme,
      customColor: settings.customPrimary,
    );

    return Drawer(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            decoration: BoxDecoration(
              color: ThemeHelper.cardColor(
                theme,
                customColor: settings.customPrimary,
              ),
              border: Border(
                right: BorderSide(
                  color: ThemeHelper.borderColor(
                    theme,
                    customColor: settings.customPrimary,
                  ),
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 40,
            ),
            child: ListView(
              children: [

                // ================= TITLE =================

                Text(
                  "⚡ MarkedPlay",
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 40),
                _sectionTitle("Browse Mode", theme),

                _drawerTile(
                  icon: Icons.dashboard,
                  title: "All Folders",
                  selected: settings.browseMode == BrowseMode.allFolders,
                  onTap: () => settings.setBrowseMode(BrowseMode.allFolders),
                  theme: theme,
                  settings: settings,
                ),

                _drawerTile(
                  icon: Icons.folder,
                  title: "Folders",
                  selected: settings.browseMode == BrowseMode.folders,
                  onTap: () => settings.setBrowseMode(BrowseMode.folders),
                  theme: theme,
                  settings: settings,
                ),

                _drawerTile(
                  icon: Icons.insert_drive_file,
                  title: "Files",
                  selected: settings.browseMode == BrowseMode.files,
                  onTap: () => settings.setBrowseMode(BrowseMode.files),
                  theme: theme,
                  settings: settings,
                ),

                const SizedBox(height: 30),
                _sectionTitle("View Mode", theme),

                _drawerTile(
                  icon: Icons.grid_view,
                  title: "Grid View",
                  selected:
                  currentViewMode == ViewMode.grid,
                  onTap: () =>
                      onViewChanged(ViewMode.grid),
                  theme: theme,
                  settings: settings,
                ),

                _drawerTile(
                  icon: Icons.list,
                  title: "List View",
                  selected:
                  currentViewMode == ViewMode.list,
                  onTap: () =>
                      onViewChanged(ViewMode.list),
                  theme: theme,
                  settings: settings,
                ),

                const SizedBox(height: 30),

                _sectionTitle("Sort By", theme),

                _drawerTile(
                  icon: Icons.sort_by_alpha,
                  title: "Name",
                  selected:
                  currentSortMode == SortMode.name,
                  onTap: () =>
                      onSortChanged(SortMode.name),
                  theme: theme,
                  settings: settings,
                ),

                _drawerTile(
                  icon: Icons.date_range,
                  title: "Date",
                  selected:
                  currentSortMode == SortMode.date,
                  onTap: () =>
                      onSortChanged(SortMode.date),
                  theme: theme,
                  settings: settings,
                ),

                _drawerTile(
                  icon: Icons.storage,
                  title: "Size",
                  selected:
                  currentSortMode == SortMode.size,
                  onTap: () =>
                      onSortChanged(SortMode.size),
                  theme: theme,
                  settings: settings,
                ),

                const SizedBox(height: 30),

                _sectionTitle("More", theme),

                _drawerTile(
                  icon: Icons.settings,
                  title: "Settings",
                  selected: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                        const SettingsScreen(),
                      ),
                    );
                  },
                  theme: theme,
                  settings: settings,
                ),

                _drawerTile(
                  icon: Icons.info_outline,
                  title: "About",
                  selected: false,
                  onTap: () {},
                  theme: theme,
                  settings: settings,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= SECTION TITLE =================

  Widget _sectionTitle(
      String title,
      AppTheme theme,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: ThemeHelper.textSecondary(theme),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ================= DRAWER TILE =================

  Widget _drawerTile({
    required IconData icon,
    required String title,
    required bool selected,
    required VoidCallback onTap,
    required AppTheme theme,
    required AppSettingsProvider settings,
  }) {

    final primaryColor = ThemeHelper.primary(
      theme,
      customColor: settings.customPrimary,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: selected
            ? primaryColor.withOpacity(0.2)
            : Colors.transparent,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: selected
              ? primaryColor
              : ThemeHelper.textPrimary(theme),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: selected
                ? primaryColor
                : ThemeHelper.textPrimary(theme),
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}