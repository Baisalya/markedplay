import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:markedplay/Pages/videoplayer/VideoListScreen.dart';
import 'package:markedplay/Pages/videoplayer/Videoplayer.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

import '../../core/app_settings_provider.dart';
import '../../core/media_enums.dart';
import '../../core/theme_helper.dart';

import '../../core/services/media_permission_service.dart';
import '../../core/services/video_service.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/file_browser_service.dart';

import '../../widgets/modern_drawer.dart';

import 'DirectoryScreen.dart';
import 'audio player/AudioListScreen.dart';
import 'audio player/Audioplayer.dart';
import 'audio player/Audioplayerprovider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {

  // ================= SERVICES =================
  final _permissionService = MediaPermissionService();
  final _videoService = VideoService();
  final _audioService = AudioService();
  final _fileBrowserService = FileBrowserService();

  // ================= STATE =================
  int _selectedIndex = 0;
  bool _hasPermission = false;

  List<AssetPathEntity> videoFolders = [];
  List<AlbumModel> audioFolders = [];
  List<FileSystemEntity> _rootItems = [];
  late AnimationController _bgController;

  final String _rootPath = "/storage/emulated/0";

  // ================= INIT =================

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
    final granted =
    await _permissionService.requestPermissions();

    if (!granted) return;

    videoFolders =
    await _videoService.getVideoFolders();

    audioFolders =
    await _audioService.getAlbums();

    if (mounted) {
      setState(() => _hasPermission = true);
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  // ================= FILE OPENER =================

  void _openFile(String path) {
    if (_selectedIndex == 0 &&
        _fileBrowserService.isVideoFile(path)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(
            filePath: path,
          ),
        ),
      );
    }

    if (_selectedIndex == 1 &&
        _fileBrowserService.isAudioFile(path)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AudioPlayerScreen(
            filePath: path,
            startPosition:
            Provider.of<AudioPlayerProvider>(
              context,
              listen: false,
            ).currentPosition,
          ),
        ),
      );
    }
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {

    final settings = context.watch<AppSettingsProvider>();
    final theme = settings.theme;
    if (settings.browseMode == BrowseMode.folders &&
        _rootItems.isEmpty) {
      _loadRoot();
    }
    return Scaffold(
      extendBody: true,   // 🔥 ADD THIS
      backgroundColor: Colors.transparent,
      drawer: ModernDrawer(
        currentViewMode: settings.viewMode,
        currentSortMode: settings.sortMode,
        onViewChanged: settings.setViewMode,
        onSortChanged: settings.setSortMode,
      ),
      body: Stack(

        children: [

          AnimatedBuilder(
            animation: _bgController,
            builder: (_, __) {
              return Container(
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
            bottom: false,  // 🔥 IMPORTANT
            child: Column(
              children: [

                _buildTopBar(theme, settings),

                Expanded(
                  child: !_hasPermission
                      ? const Center(
                    child:
                    CircularProgressIndicator(),
                  )
                      : _selectedIndex == 0
                      ? _videoSection(
                      theme, settings)
                      : _audioSection(
                      theme, settings),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar:
      _buildBottomNav(theme, settings),
    );
  }

  // ================= TOP BAR =================

  Widget _buildTopBar(
      AppTheme theme,
      AppSettingsProvider settings) {

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
        children: [
          Builder(
            builder: (context) =>
                IconButton(
                  icon: Icon(
                    Icons.menu,
                    color: ThemeHelper.primary(
                      theme,
                      customColor:
                      settings.customPrimary,
                    ),
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
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color:
              ThemeHelper.textPrimary(
                  theme),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  // ================= VIDEO SECTION =================

  Widget _videoSection(
      AppTheme theme,
      AppSettingsProvider settings) {

    switch (settings.browseMode) {

      case BrowseMode.allFolders:
        return _videoAlbumMode(
            theme, settings);

      case BrowseMode.folders:
        return _rootFolderUI(theme, settings);

      case BrowseMode.files:
        return _videoFilesMode(
            theme, settings);
    }
  }

  // ================= AUDIO SECTION =================

  Widget _audioSection(
      AppTheme theme,
      AppSettingsProvider settings) {

    switch (settings.browseMode) {

      case BrowseMode.allFolders:
        return _audioAlbumMode(
            theme, settings);

      case BrowseMode.folders:
        return _rootFolderUI(theme, settings);

      case BrowseMode.files:
        return _audioFilesMode(
            theme, settings);
    }
  }

  // ================= ROOT DIRECTORY =================
  Future<void> _loadRoot() async {
    final items = await _fileBrowserService
        .loadDirectory(_rootPath, _selectedIndex == 0);

    if (!mounted) return;

    setState(() {
      _rootItems = items;
    });
  }

  // ================= VIDEO ALBUM MODE =================

  Widget _videoAlbumMode(
      AppTheme theme,
      AppSettingsProvider settings) {

    List<AssetPathEntity> folders =
    List.from(videoFolders);

    if (settings.sortMode == SortMode.name) {
      folders.sort((a, b) =>
          a.name.compareTo(b.name));
    }

    return _buildFolderUI(
      titles: folders.map((e) => e.name).toList(),
      icon: Icons.video_library,
      settings: settings,
      theme: theme,
      onTap: (index) async {

        final videos =
        await _videoService
            .getVideosFromFolder(
            folders[index]);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoListScreen(
              folderName:
              folders[index].name,
              videos: videos,
            ),
          ),
        );
      },
    );
  }
  // ================= AUDIO ALBUM MODE =================

  Widget _audioAlbumMode(
      AppTheme theme,
      AppSettingsProvider settings) {

    List<AlbumModel> albums =
    List.from(audioFolders);

    if (settings.sortMode == SortMode.name) {
      albums.sort((a, b) =>
          a.album.compareTo(b.album));
    }

    return _buildFolderUI(
      titles: albums.map((e) => e.album).toList(),
      icon: Icons.album,
      settings: settings,
      theme: theme,
      onTap: (index) async {

        final songs =
        await _audioService
            .getSongsFromAlbum(
            albums[index].id);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AudioListScreen(
              albumName:
              albums[index].album,
              songs: songs,
            ),
          ),
        );
      },
    );
  }
  // ================= FILE MODES =================

  Widget _videoFilesMode(
      AppTheme theme,
      AppSettingsProvider settings) {

    return FutureBuilder(
      future: _videoService.getAllVideos(),
      builder: (_, snapshot) {

        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator());
        }

        final videos = snapshot.data!;

        return _buildFileUI(
          titles: videos
              .map((e) => e.title ?? "Unknown")
              .toList(),
          icon: Icons.play_circle,
          settings: settings,
          theme: theme,
          onTap: (index) async {

            final file =
            await videos[index].file;

            if (file != null) {
              _openFile(file.path);
            }
          },
        );
      },
    );
  }
  //

  Widget _audioFilesMode(
      AppTheme theme,
      AppSettingsProvider settings) {

    return FutureBuilder(
      future: _audioService.getAllSongs(),
      builder: (_, snapshot) {

        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator());
        }

        final songs = snapshot.data!;

        return _buildFileUI(
          titles:
          songs.map((e) => e.title).toList(),
          icon: Icons.music_note,
          settings: settings,
          theme: theme,
          onTap: (index) {
            _openFile(songs[index].data);
          },
        );
      },
    );
  }

  //
  Widget _buildFolderUI({
    required List<String> titles,
    required IconData icon,
    required Function(int) onTap,
    required AppSettingsProvider settings,
    required AppTheme theme,
  }) {
    if (settings.viewMode == ViewMode.list) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: titles.length,
        itemBuilder: (_, index) {
          return ListTile(
            leading: Icon(
              icon,
              color: ThemeHelper.primary(
                theme,
                customColor: settings.customPrimary,
              ),
            ),
            title: Text(
              titles[index],
              style: TextStyle(
                color: ThemeHelper.textPrimary(theme),
              ),
            ),
            onTap: () => onTap(index),
          );
        },
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: titles.length,
      gridDelegate:
      const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (_, index) {
        return _modernCard(
          icon: icon,
          title: titles[index],
          onTap: () => onTap(index),
          theme: theme,
          settings: settings,
        );
      },
    );
  }
  //
  Widget _buildFileUI({
    required List<String> titles,
    required Function(int) onTap,
    required IconData icon,
    required AppSettingsProvider settings,
    required AppTheme theme,
  }) {
    if (settings.viewMode == ViewMode.list) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: titles.length,
        itemBuilder: (_, index) {
          return ListTile(
            leading: Icon(
              icon,
              color: ThemeHelper.primary(
                theme,
                customColor: settings.customPrimary,
              ),
            ),
            title: Text(
              titles[index],
              style: TextStyle(
                color: ThemeHelper.textPrimary(theme),
              ),
            ),
            onTap: () => onTap(index),
          );
        },
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: titles.length,
      gridDelegate:
      const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (_, index) {
        return _modernCard(
          icon: icon,
          title: titles[index],
          onTap: () => onTap(index),
          theme: theme,
          settings: settings,
        );
      },
    );
  }
  //
  // ================= BOTTOM NAV =================

  Widget _buildBottomNav(
      AppTheme theme,
      AppSettingsProvider settings) {

    final primaryColor = ThemeHelper.primary(
      theme,
      customColor: settings.customPrimary,
    );

    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ThemeHelper.cardColor(
            theme,
            customColor: settings.customPrimary,
          ), // 👈 slightly transparent
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.video_library, 0, theme, settings),
            _navItem(Icons.music_note, 1, theme, settings),
          ],
        ),
      ),
    );
  }

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

    final textColor = ThemeHelper.textPrimary(theme);

    final contrastColor =
    ThemeData.estimateBrightnessForColor(primaryColor) ==
        Brightness.dark
        ? Colors.white
        : Colors.black;

    return GestureDetector(
      onTap: () {
        if (_selectedIndex == index) return;

        setState(() {
          _selectedIndex = index;
          _rootItems.clear(); // reload root for folder mode
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
            horizontal: 26, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 250),
          scale: isSelected ? 1.05 : 1.0,
          child: Icon(
            icon,
            size: 26,
            color: isSelected
                ? contrastColor
                : textColor,
          ),
        ),
      ),
    );
  }
  // ================= modern card =================
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

  Widget _rootFolderUI(
      AppTheme theme,
      AppSettingsProvider settings) {

    if (_rootItems.isEmpty) {
      return const Center(
          child: CircularProgressIndicator());
    }

    List<FileSystemEntity> sorted =
    List.from(_rootItems);

    if (settings.sortMode == SortMode.name) {
      sorted.sort((a, b) =>
          a.path.split('/').last
              .compareTo(b.path.split('/').last));
    }

    if (settings.viewMode == ViewMode.list) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sorted.length,
        itemBuilder: (_, index) {
          final item = sorted[index];
          final name =
              item.path.split('/').last;

          return ListTile(
            leading: Icon(
              item is Directory
                  ? Icons.folder
                  : Icons.insert_drive_file,
              color: ThemeHelper.primary(
                theme,
                customColor:
                settings.customPrimary,
              ),
            ),
            title: Text(
              name,
              style: TextStyle(
                color:
                ThemeHelper.textPrimary(
                    theme),
              ),
            ),
            onTap: () {
              if (item is Directory) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        DirectoryScreen(
                          path: item.path,
                          isVideo:
                          _selectedIndex == 0,
                        ),
                  ),
                );
              } else {
                _openFile(item.path);
              }
            },
          );
        },
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      gridDelegate:
      const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (_, index) {
        final item = sorted[index];
        final name =
            item.path.split('/').last;

        return _modernCard(
          icon: item is Directory
              ? Icons.folder
              : Icons.insert_drive_file,
          title: name,
          theme: theme,
          settings: settings,
          onTap: () {
            if (item is Directory) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      DirectoryScreen(
                        path: item.path,
                        isVideo:
                        _selectedIndex == 0,
                      ),
                ),
              );
            } else {
              _openFile(item.path);
            }
          },
        );
      },
    );
  }
}