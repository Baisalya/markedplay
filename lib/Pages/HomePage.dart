import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:markedplay/Pages/videoplayer/VideoListScreen.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../core/app_settings_provider.dart';
import '../core/media_enums.dart';
import '../core/theme_helper.dart';
import '../widgets/modern_drawer.dart';
import 'audio player/AudioListScreen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {

  int _selectedIndex = 0;
  bool _hasPermission = false;

  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<AssetPathEntity> videoFolders = [];
  List<AlbumModel> audioFolders = [];

  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _initMedia();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  Future<void> _initMedia() async {
    try {
      final permission =
      await PhotoManager.requestPermissionExtend();

      if (!(permission.isAuth || permission.hasAccess)) {
        await PhotoManager.openSetting();
        return;
      }

      bool audioPermission =
      await _audioQuery.permissionsStatus();
      if (!audioPermission) {
        audioPermission =
        await _audioQuery.permissionsRequest();
        if (!audioPermission) return;
      }

      videoFolders =
      await PhotoManager.getAssetPathList(
          type: RequestType.video);

      audioFolders =
      await _audioQuery.queryAlbums();

      if (mounted) {
        setState(() => _hasPermission = true);
      }
    } catch (e) {
      debugPrint("Media init error: $e");
    }
  }

  @override
  void dispose() {
    _bgController.stop();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final settings =
    context.watch<AppSettingsProvider>();

    final theme = settings.theme;

    final primaryColor = ThemeHelper.primary(
      theme,
      customColor: settings.customPrimary,
    );

    final backgroundColor =
    ThemeHelper.background(
      theme,
      customColor: settings.customPrimary,
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBody: true,

      drawer: ModernDrawer(
        currentViewMode: settings.viewMode,
        currentSortMode: settings.sortMode,
        onViewChanged: settings.setViewMode,
        onSortChanged: settings.setSortMode,
      ),

      body: Stack(
        children: [

          // ================= BACKGROUND =================

          AnimatedBuilder(
            animation: _bgController,
            builder: (_, __) {
              return AnimatedContainer(
                duration:
                const Duration(milliseconds: 400),
                decoration: BoxDecoration(
                  gradient:
                  ThemeHelper.backgroundGradient(
                    theme,
                    customColor:
                    settings.customPrimary,
                  ),
                ),
              );
            },
          ),

          SafeArea(
            child: Column(
              children: [

                // ================= APP BAR =================

                Padding(
                  padding:
                  const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,
                    children: [
                      Builder(
                        builder: (context) =>
                            IconButton(
                              icon: Icon(
                                Icons.menu,
                                color: primaryColor,
                              ),
                              onPressed: () =>
                                  Scaffold.of(context)
                                      .openDrawer(),
                            ),
                      ),
                      Text(
                        _selectedIndex == 0
                            ? "Your Videos"
                            : "Your Music",
                        style: TextStyle(
                          color:
                          ThemeHelper
                              .textPrimary(
                              theme),
                          fontSize: 22,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                      Icon(
                        Icons.search,
                        color: ThemeHelper
                            .textSecondary(
                            theme),
                      ),
                    ],
                  ),
                ),

                // ================= BODY =================

                Expanded(
                  child: !_hasPermission
                      ? Center(
                    child: Text(
                      "Permission Required",
                      style: TextStyle(
                        color:
                        ThemeHelper
                            .textPrimary(
                            theme),
                      ),
                    ),
                  )
                      : _selectedIndex == 0
                      ? _videoUI(
                      settings, theme)
                      : _audioUI(
                      settings, theme),
                ),
              ],
            ),
          ),
        ],
      ),

      // ================= BOTTOM NAV =================

      bottomNavigationBar: Container(
        margin:
        const EdgeInsets.all(16),
        padding:
        const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:
          ThemeHelper.cardColor(
            theme,
            customColor:
            settings.customPrimary,
          ),
          borderRadius:
          BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment:
          MainAxisAlignment
              .spaceAround,
          children: [
            _navItem(
                Icons.video_library,
                0,
                theme,
                settings),
            _navItem(
                Icons.music_note,
                1,
                theme,
                settings),
          ],
        ),
      ),
    );
  }

  // ================= NAV ITEM =================
  Widget _navItem(
      IconData icon,
      int index,
      AppTheme theme,
      AppSettingsProvider settings,
      ) {
    final isSelected = _selectedIndex == index;

    final primaryColor = ThemeHelper.primary(
      theme,
      customColor: settings.customPrimary,
    );

    // 🔥 AUTO CONTRAST COLOR
    final iconContrastColor =
    ThemeData.estimateBrightnessForColor(primaryColor)
        == Brightness.dark
        ? Colors.white
        : Colors.black;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(
            horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          color: isSelected
              ? iconContrastColor
              : ThemeHelper.textPrimary(theme),
        ),
      ),
    );
  }

  // ================= VIDEO UI =================

  Widget _videoUI(
      AppSettingsProvider settings,
      AppTheme theme) {

    if (settings.viewMode ==
        ViewMode.list) {
      return ListView.builder(
        padding:
        const EdgeInsets.all(16),
        itemCount:
        videoFolders.length,
        itemBuilder: (_, index) {
          final folder =
          videoFolders[index];

          return ListTile(
            leading: Icon(
              Icons.video_library,
              color:
              ThemeHelper.primary(
                  theme,
                  customColor: settings
                      .customPrimary),
            ),
            title: Text(
              folder.name,
              style: TextStyle(
                  color: ThemeHelper
                      .textPrimary(
                      theme)),
            ),
            onTap: () async {
              final videos =
              await folder
                  .getAssetListPaged(
                  page: 0,
                  size: 1000);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      VideoListScreen(
                        folderName:
                        folder.name,
                        videos: videos,
                      ),
                ),
              );
            },
          );
        },
      );
    }

    return GridView.builder(
      padding:
      const EdgeInsets.all(16),
      itemCount:
      videoFolders.length,
      gridDelegate:
      const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16),
      itemBuilder: (_, index) {
        final folder =
        videoFolders[index];

        return _modernCard(
          icon: Icons.video_library,
          title: folder.name,
          onTap: () async {
            final videos =
            await folder
                .getAssetListPaged(
                page: 0,
                size: 1000);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    VideoListScreen(
                      folderName:
                      folder.name,
                      videos: videos,
                    ),
              ),
            );
          },
          theme: theme,
          settings: settings,
        );
      },
    );
  }

  // ================= AUDIO UI =================

  Widget _audioUI(
      AppSettingsProvider settings,
      AppTheme theme) {

    if (settings.viewMode ==
        ViewMode.list) {
      return ListView.builder(
        padding:
        const EdgeInsets.all(16),
        itemCount:
        audioFolders.length,
        itemBuilder: (_, index) {
          final album =
          audioFolders[index];

          return ListTile(
            leading: Icon(
              Icons.music_note,
              color:
              ThemeHelper.primary(
                  theme,
                  customColor: settings
                      .customPrimary),
            ),
            title: Text(
              album.album,
              style: TextStyle(
                  color: ThemeHelper
                      .textPrimary(
                      theme)),
            ),
            subtitle: Text(
              "${album.numOfSongs} songs",
              style: TextStyle(
                  color: ThemeHelper
                      .textSecondary(
                      theme)),
            ),
            onTap: () async {
              final songs =
              await _audioQuery
                  .queryAudiosFrom(
                  AudiosFromType
                      .ALBUM_ID,
                  album.id);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AudioListScreen(
                        albumName:
                        album.album,
                        songs: songs,
                      ),
                ),
              );
            },
          );
        },
      );
    }

    return GridView.builder(
      padding:
      const EdgeInsets.all(16),
      itemCount:
      audioFolders.length,
      gridDelegate:
      const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16),
      itemBuilder: (_, index) {
        final album =
        audioFolders[index];

        return _modernCard(
          icon: Icons.music_note,
          title: album.album,
          subtitle:
          "${album.numOfSongs} songs",
          onTap: () async {
            final songs =
            await _audioQuery
                .queryAudiosFrom(
                AudiosFromType
                    .ALBUM_ID,
                album.id);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AudioListScreen(
                      albumName:
                      album.album,
                      songs: songs,
                    ),
              ),
            );
          },
          theme: theme,
          settings: settings,
        );
      },
    );
  }

  // ================= CARD =================

  Widget _modernCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    required AppTheme theme,
    required AppSettingsProvider settings,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color:
          ThemeHelper.cardColor(
            theme,
            customColor:
            settings.customPrimary,
          ),
          borderRadius:
          BorderRadius.circular(25),
          border: Border.all(
            color:
            ThemeHelper.borderColor(
              theme,
              customColor:
              settings.customPrimary,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color:
              ThemeHelper.primary(
                  theme,
                  customColor: settings
                      .customPrimary),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign:
              TextAlign.center,
              style: TextStyle(
                color: ThemeHelper
                    .textPrimary(theme),
                fontWeight:
                FontWeight.bold,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: TextStyle(
                  color: ThemeHelper
                      .textSecondary(
                      theme),
                ),
              ),
          ],
        ),
      ),
    );
  }
}