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

import '../../core/services/thumbnail_service.dart';
import '../../widgets/modern_drawer.dart';
import '../../widgets/modern_widgets.dart';
import 'audio player/AudioHandler.dart';
import 'audio player/Audioplayer.dart';
import 'audio player/AudioListScreen.dart';
import 'DirectoryScreen.dart';
import '../widgets/mini_player.dart';

import 'audio player/Audioplayerprovider.dart';
import 'videoplayer/VideoBackgroundProvider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {

  final _permissionService = MediaPermissionService();
  final _videoService = VideoService();
  final _audioService = AudioService();
  final _fileBrowserService = FileBrowserService();

  int _selectedIndex = 0;
  bool _hasPermission = false;

  List<AssetPathEntity> videoFolders = [];
  List<AlbumModel> audioFolders = [];
  List<FileSystemEntity> _videoRootItems = [];
  List<FileSystemEntity> _audioRootItems = [];
  bool _isLoadingRoot = false;
  late AnimationController _bgController;

  final String _rootPath = "/storage/emulated/0";

  @override
  void initState() {
    super.initState();
    _initMedia();
    _setupNotificationListener();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  Future<void> _initMedia() async {
    final granted = await _permissionService.requestPermissions();
    if (!granted) return;

    videoFolders = await _videoService.getVideoFolders();
    audioFolders = await _audioService.getAlbums();

    if (mounted) {
      setState(() => _hasPermission = true);
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  void _setupNotificationListener() {
    MyAudioHandler.notificationClickStream.listen((_) {
      if (!mounted) return;
      
      final videoProvider = Provider.of<VideoBackgroundProvider>(context, listen: false);
      final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);

      if (videoProvider.currentFilePath != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoPlayerScreen(
              playlist: videoProvider.currentPlaylist ?? [videoProvider.currentFilePath!],
              initialIndex: videoProvider.currentIndex,
            ),
          ),
        );
        videoProvider.pauseAudio();
      } else if (audioProvider.currentFilePath != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AudioPlayerScreen(
              filePath: audioProvider.currentFilePath!,
              startPosition: audioProvider.currentPosition,
            ),
          ),
        );
      }
    });
  }

  void _openFile(String path) {
    final settings = Provider.of<AppSettingsProvider>(context, listen: false);
    settings.addRecentlyPlayed(path);

    if (_selectedIndex == 0 && _fileBrowserService.isVideoFile(path)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(
            playlist: [path],
            initialIndex: 0,
          ),
        ),
      );
    }

    if (_selectedIndex == 1 && _fileBrowserService.isAudioFile(path)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AudioPlayerScreen(
            filePath: path,
            startPosition: Provider.of<AudioPlayerProvider>(context, listen: false).currentPosition,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    final theme = settings.theme;
    
    if (settings.browseMode == BrowseMode.folders) {
      final items = _selectedIndex == 0 ? _videoRootItems : _audioRootItems;
      if (items.isEmpty && !_isLoadingRoot) {
        _loadRoot();
      }
    }

    final primaryColor = ThemeHelper.primary(theme, customColor: settings.customPrimary);

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.black,
      drawer: ModernDrawer(
        currentViewMode: settings.viewMode,
        currentSortMode: settings.sortMode,
        onViewChanged: settings.setViewMode,
        onSortChanged: settings.setSortMode,
      ),
      body: Stack(
        children: [
          // Animated Background
          AnimatedBuilder(
            animation: _bgController,
            builder: (_, __) {
              return Container(
                decoration: BoxDecoration(
                  gradient: ThemeHelper.backgroundGradient(
                    theme,
                    customColor: settings.customPrimary,
                  ),
                ),
              );
            },
          ),
          
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildModernTopBar(theme, settings),
                Expanded(
                  child: !_hasPermission
                      ? _buildPermissionEmptyState(primaryColor)
                      : RefreshIndicator(
                          color: primaryColor,
                          onRefresh: () async {
                             if (settings.browseMode == BrowseMode.folders) {
                               await _loadRoot(refresh: true);
                             } else {
                               await _initMedia();
                             }
                          },
                          child: _buildMainContent(theme, settings),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MultiMiniPlayer(),
          _buildFloatingBottomNav(theme, settings),
        ],
      ),
    );
  }

  Widget _buildModernTopBar(AppTheme theme, AppSettingsProvider settings) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: GlassCard(
        borderRadius: 20,
        blur: 20,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Colors.white),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedIndex == 0 ? "Videos" : "Music",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search_rounded, color: Colors.white70),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                onPressed: () => _loadRoot(refresh: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionEmptyState(Color primaryColor) {
    return EmptyStateWidget(
      icon: Icons.security_rounded,
      title: "Storage Permission Required",
      subtitle: "To display your media files, MarkedPlay needs access to your storage.",
      buttonText: "Grant Permission",
      onButtonPressed: _initMedia,
    );
  }

  Widget _buildMainContent(AppTheme theme, AppSettingsProvider settings) {
    // Dashboard logic if we wanted one, but for now we follow the browseMode
    return _selectedIndex == 0 ? _videoSection(theme, settings) : _audioSection(theme, settings);
  }

  Widget _videoSection(AppTheme theme, AppSettingsProvider settings) {
    switch (settings.browseMode) {
      case BrowseMode.allFolders: return _videoAlbumMode(theme, settings);
      case BrowseMode.folders: return _rootFolderUI(theme, settings);
      case BrowseMode.files: return _videoFilesMode(theme, settings);
    }
  }

  Widget _audioSection(AppTheme theme, AppSettingsProvider settings) {
    switch (settings.browseMode) {
      case BrowseMode.allFolders: return _audioAlbumMode(theme, settings);
      case BrowseMode.folders: return _rootFolderUI(theme, settings);
      case BrowseMode.files: return _audioFilesMode(theme, settings);
    }
  }

  // --- REUSABLE MEDIA COMPONENTS ---

  Widget _buildFloatingBottomNav(AppTheme theme, AppSettingsProvider settings) {
    final primaryColor = ThemeHelper.primary(theme, customColor: settings.customPrimary);

    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 20),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        child: GlassCard(
          borderRadius: 30,
          color: Colors.white.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(Icons.video_library_rounded, "Videos", 0, primaryColor),
                _buildNavItem(Icons.music_note_rounded, "Music", 1, primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, Color primaryColor) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        if (_selectedIndex == index) return;
        setState(() => _selectedIndex = index);
        _loadRoot();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? primaryColor : Colors.white54,
              size: 26,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  // --- DATA LOADING & ADAPTORS ---

  Future<void> _loadRoot({bool refresh = false}) async {
    final isVideo = _selectedIndex == 0;
    if (!refresh) {
      if (isVideo && _videoRootItems.isNotEmpty) return;
      if (!isVideo && _audioRootItems.isNotEmpty) return;
    }

    setState(() => _isLoadingRoot = true);
    if (refresh) {
      _fileBrowserService.clearCache();
      await ThumbnailService().clearAll();
    }

    final items = await _fileBrowserService.loadDirectory(_rootPath, isVideo);

    if (mounted) {
      setState(() {
        if (isVideo) _videoRootItems = items;
        else _audioRootItems = items;
        _isLoadingRoot = false;
      });
    }
  }

  Widget _videoAlbumMode(AppTheme theme, AppSettingsProvider settings) {
    List<AssetPathEntity> folders = List.from(videoFolders);
    if (settings.sortMode == SortMode.name) folders.sort((a, b) => a.name.compareTo(b.name));

    return _buildFolderUI(
      titles: folders.map((e) => e.name).toList(),
      icon: Icons.video_collection_rounded,
      onTap: (index) async {
        final videos = await _videoService.getVideosFromFolder(folders[index]);
        Navigator.push(context, MaterialPageRoute(builder: (_) => VideoListScreen(folderName: folders[index].name, videos: videos)));
      },
      theme: theme,
      settings: settings,
    );
  }

  Widget _audioAlbumMode(AppTheme theme, AppSettingsProvider settings) {
    List<AlbumModel> albums = List.from(audioFolders);
    if (settings.sortMode == SortMode.name) albums.sort((a, b) => a.album.compareTo(b.album));

    return _buildFolderUI(
      titles: albums.map((e) => e.album).toList(),
      icon: Icons.album_rounded,
      onTap: (index) async {
        final songs = await _audioService.getSongsFromAlbum(albums[index].id);
        Navigator.push(context, MaterialPageRoute(builder: (_) => AudioListScreen(albumName: albums[index].album, songs: songs)));
      },
      theme: theme,
      settings: settings,
    );
  }

  Widget _videoFilesMode(AppTheme theme, AppSettingsProvider settings) {
    return FutureBuilder<List<AssetEntity>>(
      future: _videoService.getAllVideos(),
      builder: (_, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final videos = snapshot.data!;
        return _buildFileUI(
          titles: videos.map((e) => e.title ?? "Unknown Video").toList(),
          icon: Icons.play_circle_filled_rounded,
          onTap: (index) async {
            final file = await videos[index].file;
            if (file != null) _openFile(file.path);
          },
          theme: theme,
          settings: settings,
        );
      },
    );
  }

  Widget _audioFilesMode(AppTheme theme, AppSettingsProvider settings) {
    return FutureBuilder<List<SongModel>>(
      future: _audioService.getAllSongs(),
      builder: (_, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final songs = snapshot.data!;
        return _buildFileUI(
          titles: songs.map((e) => e.title).toList(),
          icon: Icons.music_note_rounded,
          onTap: (index) => _openFile(songs[index].data),
          theme: theme,
          settings: settings,
        );
      },
    );
  }

  Widget _buildFolderUI({required List<String> titles, required IconData icon, required Function(int) onTap, required AppTheme theme, required AppSettingsProvider settings}) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: titles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 20, mainAxisSpacing: 20,
      ),
      itemBuilder: (_, index) => _modernMediaCard(icon: icon, title: titles[index], onTap: () => onTap(index), theme: theme, settings: settings),
    );
  }

  Widget _buildFileUI({required List<String> titles, required IconData icon, required Function(int) onTap, required AppTheme theme, required AppSettingsProvider settings}) {
    if (settings.viewMode == ViewMode.list) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: titles.length,
        itemBuilder: (_, index) => ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          leading: GlassCard(borderRadius: 12, blur: 5, child: Padding(padding: const EdgeInsets.all(8.0), child: Icon(icon, color: ThemeHelper.primary(theme, customColor: settings.customPrimary)))),
          title: Text(titles[index], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          onTap: () => onTap(index),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: titles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 20, mainAxisSpacing: 20),
      itemBuilder: (_, index) => _modernMediaCard(icon: icon, title: titles[index], onTap: () => onTap(index), theme: theme, settings: settings),
    );
  }

  Widget _modernMediaCard({required IconData icon, required String title, required VoidCallback onTap, required AppTheme theme, required AppSettingsProvider settings}) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        borderRadius: 25,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: ThemeHelper.primary(theme, customColor: settings.customPrimary)),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rootFolderUI(AppTheme theme, AppSettingsProvider settings) {
    final items = _selectedIndex == 0 ? _videoRootItems : _audioRootItems;
    if (_isLoadingRoot && items.isEmpty) return const Center(child: CircularProgressIndicator());
    if (items.isEmpty) return const EmptyStateWidget(icon: Icons.folder_open_rounded, title: "No Folders", subtitle: "We couldn't find any media folders in this directory.");

    List<FileSystemEntity> sorted = List.from(items);
    if (settings.sortMode == SortMode.name) sorted.sort((a, b) => a.path.split('/').last.compareTo(b.path.split('/').last));

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: sorted.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 20, mainAxisSpacing: 20),
      itemBuilder: (_, index) {
        final item = sorted[index];
        final name = item.path.split('/').last;
        return _modernMediaCard(
          icon: item is Directory ? Icons.folder_rounded : Icons.insert_drive_file_rounded,
          title: name,
          theme: theme,
          settings: settings,
          onTap: () {
            if (item is Directory) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => DirectoryScreen(path: item.path, isVideo: _selectedIndex == 0)));
            } else {
              _openFile(item.path);
            }
          },
        );
      },
    );
  }
}
