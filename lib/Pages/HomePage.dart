import 'dart:io';
import 'dart:async';
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
import 'Tools/ToolsScreen.dart';
import '../widgets/mini_player.dart';

import '../widgets/SearchDelegate.dart';
import 'audio player/Audioplayerprovider.dart';
import 'videoplayer/VideoBackgroundProvider.dart';
import '../core/ui/responsive/adaptive_scaffold.dart';
import '../core/ui/responsive/responsive_builder.dart';
import '../core/ui/responsive/app_breakpoints.dart';
import '../core/ui/widgets/mini_player_aware_padding.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _permissionService = MediaPermissionService();
  final _videoService = VideoService();
  final _audioService = AudioService();
  final _fileBrowserService = FileBrowserService();

  int _selectedIndex = 0;
  bool _hasVideoPermission = false;
  bool _hasAudioPermission = false;
  bool _permissionNeedsSettings = false;
  bool _isInitializing = true;
  String? _initializationError;

  List<AssetPathEntity> videoFolders = [];
  List<AlbumModel> audioFolders = [];
  List<FileSystemEntity> _videoRootItems = [];
  List<FileSystemEntity> _audioRootItems = [];
  bool _isLoadingRoot = false;
  Future<List<AssetEntity>>? _allVideosFuture;
  Future<List<SongModel>>? _allSongsFuture;
  StreamSubscription<bool>? _notificationSubscription;

  final String _rootPath = "/storage/emulated/0";

  @override
  void initState() {
    super.initState();
    _initMedia();
    _setupNotificationListener();
  }

  Future<void> _initMedia() async {
    if (mounted) {
      setState(() {
        _isInitializing = true;
        _initializationError = null;
      });
    }

    try {
      final result = await _permissionService.requestPermissions();
      final folders = await Future.wait<dynamic>([
        if (result.videoGranted) _videoService.getVideoFolders(),
        if (result.audioGranted) _audioService.getAlbums(),
      ]);

      var resultIndex = 0;
      final loadedVideoFolders = result.videoGranted
          ? folders[resultIndex++] as List<AssetPathEntity>
          : <AssetPathEntity>[];
      final loadedAudioFolders = result.audioGranted
          ? folders[resultIndex] as List<AlbumModel>
          : <AlbumModel>[];

      if (!mounted) return;
      setState(() {
        _hasVideoPermission = result.videoGranted;
        _hasAudioPermission = result.audioGranted;
        _permissionNeedsSettings = result.requiresSettings;
        videoFolders = loadedVideoFolders;
        audioFolders = loadedAudioFolders;
        _allVideosFuture =
            result.videoGranted ? _videoService.getAllVideos() : null;
        _allSongsFuture =
            result.audioGranted ? _audioService.getAllSongs() : null;
        _isInitializing = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _initializationError = 'Your media library could not be loaded.';
        _isInitializing = false;
      });
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _setupNotificationListener() {
    _notificationSubscription =
        MyAudioHandler.notificationClickStream.listen((_) {
      if (!mounted) return;

      final videoProvider =
          Provider.of<VideoBackgroundProvider>(context, listen: false);
      final audioProvider =
          Provider.of<AudioPlayerProvider>(context, listen: false);

      if (videoProvider.currentFilePath != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoPlayerScreen(
              playlist: videoProvider.currentPlaylist ??
                  [videoProvider.currentFilePath!],
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
            startPosition: Duration.zero,
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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _loadRoot();
        });
      }
    }

    final primaryColor =
        ThemeHelper.primary(theme, customColor: settings.customPrimary);

    return AdaptiveScaffold(
      backgroundColor:
          ThemeHelper.background(theme, customColor: settings.customPrimary),
      extendBody: true,
      extendBodyBehindAppBar: true,
      drawer: ModernDrawer(
        currentViewMode: settings.viewMode,
        currentSortMode: settings.sortMode,
        onViewChanged: settings.setViewMode,
        onSortChanged: settings.setSortMode,
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: SafeArea(child: _buildModernTopBar(theme, settings)),
      ),
      railDestinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.video_library_rounded),
          label: Text("Videos"),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.music_note_rounded),
          label: Text("Music"),
        ),
      ],
      selectedIndex: _selectedIndex,
      onSelectedIndexChanged: (index) {
        setState(() => _selectedIndex = index);
        _loadRoot();
      },
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: ThemeHelper.backgroundGradient(
                theme,
                customColor: settings.customPrimary,
              ),
            ),
          ),
          MiniPlayerAwarePadding(
            child: SafeArea(
              child: _isInitializing
                  ? const LoadingStateWidget(label: 'Finding your media…')
                  : _initializationError != null
                      ? ErrorStateWidget(
                          title: 'Could not load your library',
                          message: _initializationError!,
                          actionLabel: 'Try again',
                          onAction: _initMedia,
                        )
                      : !_hasPermissionForCurrentTab
                          ? _buildPermissionEmptyState()
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
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MultiMiniPlayer(),
          if (!AppBreakpoints.isExpanded(context))
            _buildFloatingBottomNav(theme, settings),
        ],
      ),
    );
  }

  Widget _buildModernTopBar(AppTheme theme, AppSettingsProvider settings) {
    final textPrimary = ThemeHelper.textPrimary(theme);
    final textSecondary = ThemeHelper.textSecondary(theme);
    // Use transparent background for the top bar card
    const appBarColor = Colors.transparent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: GlassCard(
        borderRadius: 20,
        blur: 20,
        color: appBarColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Builder(
                builder: (context) => IconButton(
                  icon: Icon(Icons.menu_rounded, color: textPrimary),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedIndex == 0 ? "Videos" : "Music",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.search_rounded, color: textSecondary),
                onPressed: () async {
                  if (_selectedIndex == 1) {
                    final songs =
                        await (_allSongsFuture ??= _audioService.getAllSongs());
                    if (!mounted) return;
                    showSearch(
                      context: context,
                      delegate: MediaSearchDelegate(
                        songs: songs,
                        onFileTap: _openFile,
                      ),
                    );
                  } else {
                    final videos = await (_allVideosFuture ??=
                        _videoService.getAllVideos());
                    if (!mounted) return;
                    showSearch(
                      context: context,
                      delegate: VideoSearchDelegate(
                        videos: videos,
                        onVideoTap: (video) async {
                          final file = await video.file;
                          if (file != null && mounted) {
                            _openFile(file.path);
                          }
                        },
                      ),
                    );
                  }
                },
              ),
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: textSecondary),
                onPressed: () => _loadRoot(refresh: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _hasPermissionForCurrentTab =>
      _selectedIndex == 0 ? _hasVideoPermission : _hasAudioPermission;

  Widget _buildPermissionEmptyState() {
    if (!_permissionService.supportsMediaLibrary) {
      return EmptyStateWidget(
        icon: Icons.file_open_rounded,
        title: 'Open media from this device',
        subtitle:
            'Automatic library scanning is not available on this platform. You can still choose a media file directly.',
        buttonText: 'Open a file',
        onButtonPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ToolsScreen()),
        ),
      );
    }

    return ErrorStateWidget(
      title: _selectedIndex == 0 ? 'Allow video access' : 'Allow music access',
      message:
          'MarkedPlay only uses this permission to show and play media stored on your device.',
      actionLabel: _permissionNeedsSettings ? 'Open settings' : 'Allow access',
      onAction: _permissionNeedsSettings
          ? () => _permissionService.openSettings()
          : _initMedia,
      secondaryActionLabel: _permissionNeedsSettings ? 'Try again' : null,
      onSecondaryAction: _permissionNeedsSettings ? _initMedia : null,
    );
  }

  Widget _buildMainContent(AppTheme theme, AppSettingsProvider settings) {
    // Dashboard logic if we wanted one, but for now we follow the browseMode
    return _selectedIndex == 0
        ? _videoSection(theme, settings)
        : _audioSection(theme, settings);
  }

  Widget _videoSection(AppTheme theme, AppSettingsProvider settings) {
    switch (settings.browseMode) {
      case BrowseMode.allFolders:
        return _videoAlbumMode(theme, settings);
      case BrowseMode.folders:
        return _rootFolderUI(theme, settings);
      case BrowseMode.files:
        return _videoFilesMode(theme, settings);
    }
  }

  Widget _audioSection(AppTheme theme, AppSettingsProvider settings) {
    switch (settings.browseMode) {
      case BrowseMode.allFolders:
        return _audioAlbumMode(theme, settings);
      case BrowseMode.folders:
        return _rootFolderUI(theme, settings);
      case BrowseMode.files:
        return _audioFilesMode(theme, settings);
    }
  }

  // --- REUSABLE MEDIA COMPONENTS ---

  Widget _buildFloatingBottomNav(AppTheme theme, AppSettingsProvider settings) {
    final primaryColor =
        ThemeHelper.primary(theme, customColor: settings.customPrimary);
    final cardColor =
        ThemeHelper.cardColor(theme, customColor: settings.customPrimary);

    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 20),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        child: GlassCard(
          borderRadius: 30,
          color: cardColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(Icons.video_library_rounded, "Videos", 0,
                    primaryColor, theme),
                _buildNavItem(
                    Icons.music_note_rounded, "Music", 1, primaryColor, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index,
      Color primaryColor, AppTheme theme) {
    final isSelected = _selectedIndex == index;
    final textSecondary = ThemeHelper.textSecondary(theme);

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
          color:
              isSelected ? primaryColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? primaryColor : textSecondary,
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
    if (_isLoadingRoot) return;
    if (!Platform.isAndroid || !_hasPermissionForCurrentTab) {
      if (mounted) {
        setState(() => _isLoadingRoot = false);
      }
      return;
    }

    final isVideo = _selectedIndex == 0;
    if (!refresh) {
      if (isVideo && _videoRootItems.isNotEmpty) return;
      if (!isVideo && _audioRootItems.isNotEmpty) return;
    }

    if (!mounted) return;
    final showHiddenFiles =
        Provider.of<AppSettingsProvider>(context, listen: false)
            .showHiddenFiles;
    setState(() => _isLoadingRoot = true);
    if (refresh) {
      _fileBrowserService.clearCache();
      await ThumbnailService().clearAll();
    }

    final items = await _fileBrowserService.loadDirectory(
      _rootPath,
      isVideo,
      showHiddenFiles: showHiddenFiles,
    );

    if (mounted) {
      setState(() {
        if (isVideo)
          _videoRootItems = items;
        else
          _audioRootItems = items;
        _isLoadingRoot = false;
      });
    }
  }

  Widget _videoAlbumMode(AppTheme theme, AppSettingsProvider settings) {
    List<AssetPathEntity> folders = List.from(videoFolders);
    if (settings.sortMode == SortMode.name)
      folders.sort((a, b) => a.name.compareTo(b.name));

    return _buildFolderUI(
      titles: folders.map((e) => e.name).toList(),
      icon: Icons.video_collection_rounded,
      onTap: (index) async {
        final videos = await _videoService.getVideosFromFolder(folders[index]);
        if (!mounted) return;
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => VideoListScreen(
                    folderName: folders[index].name, videos: videos)));
      },
      theme: theme,
      settings: settings,
    );
  }

  Widget _audioAlbumMode(AppTheme theme, AppSettingsProvider settings) {
    List<AlbumModel> albums = List.from(audioFolders);
    if (settings.sortMode == SortMode.name)
      albums.sort((a, b) => a.album.compareTo(b.album));

    return _buildFolderUI(
      titles: albums.map((e) => e.album).toList(),
      icon: Icons.album_rounded,
      onTap: (index) async {
        final songs = await _audioService.getSongsFromAlbum(albums[index].id);
        if (!mounted) return;
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => AudioListScreen(
                    albumName: albums[index].album, songs: songs)));
      },
      theme: theme,
      settings: settings,
    );
  }

  Widget _videoFilesMode(AppTheme theme, AppSettingsProvider settings) {
    return FutureBuilder<List<AssetEntity>>(
      future: _allVideosFuture ??= _videoService.getAllVideos(),
      builder: (_, snapshot) {
        if (snapshot.hasError) {
          return ErrorStateWidget(
            title: 'Videos could not be loaded',
            message: 'Check media access, then try again.',
            actionLabel: 'Try again',
            onAction: () {
              setState(() {
                _allVideosFuture = _videoService.getAllVideos();
              });
            },
          );
        }
        if (!snapshot.hasData) {
          return const LoadingStateWidget(label: 'Loading videos…');
        }
        final videos = snapshot.data!;
        if (videos.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.video_library_outlined,
            title: 'No videos found',
            subtitle: 'Add a video to this device, then pull down to rescan.',
          );
        }
        final sortedVideos = [...videos];
        switch (settings.sortMode) {
          case SortMode.name:
            sortedVideos.sort(
              (a, b) => (a.title ?? '')
                  .toLowerCase()
                  .compareTo((b.title ?? '').toLowerCase()),
            );
          case SortMode.date:
            sortedVideos.sort(
              (a, b) => b.createDateTime.compareTo(a.createDateTime),
            );
          case SortMode.duration:
            sortedVideos.sort((a, b) => b.duration.compareTo(a.duration));
          case SortMode.size:
            sortedVideos.sort(
              (a, b) => (b.width * b.height).compareTo(a.width * a.height),
            );
        }
        return _buildFileUI(
          titles: sortedVideos.map((e) => e.title ?? "Unknown Video").toList(),
          icon: Icons.play_circle_filled_rounded,
          onTap: (index) async {
            final file = await sortedVideos[index].file;
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
      future: _allSongsFuture ??= _audioService.getAllSongs(),
      builder: (_, snapshot) {
        if (snapshot.hasError) {
          return ErrorStateWidget(
            title: 'Music could not be loaded',
            message: 'Check media access, then try again.',
            actionLabel: 'Try again',
            onAction: () {
              setState(() {
                _allSongsFuture = _audioService.getAllSongs();
              });
            },
          );
        }
        if (!snapshot.hasData) {
          return const LoadingStateWidget(label: 'Loading music…');
        }
        final songs = snapshot.data!;
        if (songs.isEmpty)
          return const EmptyStateWidget(
              icon: Icons.music_note_rounded,
              title: "No Songs Found",
              subtitle: "We couldn't find any audio files on your device.");
        final sortedSongs = [...songs];
        switch (settings.sortMode) {
          case SortMode.name:
            sortedSongs.sort(
              (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
            );
          case SortMode.date:
            sortedSongs.sort(
              (a, b) => (b.dateAdded ?? 0).compareTo(a.dateAdded ?? 0),
            );
          case SortMode.size:
            sortedSongs.sort((a, b) => b.size.compareTo(a.size));
          case SortMode.duration:
            sortedSongs.sort(
              (a, b) => (b.duration ?? 0).compareTo(a.duration ?? 0),
            );
        }
        final audioProvider =
            Provider.of<AudioPlayerProvider>(context, listen: false);

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: sortedSongs.length,
          itemBuilder: (_, index) => SongTile(
            song: sortedSongs[index],
            isPlaying: audioProvider.currentFilePath == sortedSongs[index].data,
            trailing: IconButton(
              tooltip: settings.favorites.contains(sortedSongs[index].data)
                  ? 'Remove favorite'
                  : 'Add favorite',
              icon: Icon(
                settings.favorites.contains(sortedSongs[index].data)
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
              ),
              onPressed: () => settings.toggleFavorite(sortedSongs[index].data),
            ),
            onTap: () {
              audioProvider.updatePlaylist(sortedSongs);
              _openFile(sortedSongs[index].data);
            },
          ),
        );
      },
    );
  }

  Widget _buildFolderUI(
      {required List<String> titles,
      required IconData icon,
      required Function(int) onTap,
      required AppTheme theme,
      required AppSettingsProvider settings}) {
    if (titles.isEmpty) {
      return EmptyStateWidget(
        icon: icon,
        title: _selectedIndex == 0 ? 'No video folders' : 'No music albums',
        subtitle: 'Pull down to scan your media library again.',
      );
    }
    return ResponsiveBuilder(
      compact: (context, constraints) => GridView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: titles.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
        ),
        itemBuilder: (_, index) => _modernMediaCard(
            icon: icon,
            title: titles[index],
            onTap: () => onTap(index),
            theme: theme,
            settings: settings),
      ),
      medium: (context, constraints) => GridView.builder(
        padding: const EdgeInsets.all(30),
        itemCount: titles.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 25,
          mainAxisSpacing: 25,
        ),
        itemBuilder: (_, index) => _modernMediaCard(
            icon: icon,
            title: titles[index],
            onTap: () => onTap(index),
            theme: theme,
            settings: settings),
      ),
      expanded: (context, constraints) => GridView.builder(
        padding: const EdgeInsets.all(40),
        itemCount: titles.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 30,
          mainAxisSpacing: 30,
        ),
        itemBuilder: (_, index) => _modernMediaCard(
            icon: icon,
            title: titles[index],
            onTap: () => onTap(index),
            theme: theme,
            settings: settings),
      ),
    );
  }

  Widget _buildFileUI(
      {required List<String> titles,
      required IconData icon,
      required Function(int) onTap,
      required AppTheme theme,
      required AppSettingsProvider settings}) {
    if (settings.viewMode == ViewMode.list) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: titles.length,
            itemBuilder: (_, index) => ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              leading: GlassCard(
                borderRadius: 12,
                blur: 5,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(icon,
                      color: ThemeHelper.primary(theme,
                          customColor: settings.customPrimary)),
                ),
              ),
              title: Text(
                titles[index],
                style: TextStyle(
                  color: ThemeHelper.textPrimary(theme),
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => onTap(index),
            ),
          ),
        ),
      );
    }
    return _buildFolderUI(
        titles: titles,
        icon: icon,
        onTap: onTap,
        theme: theme,
        settings: settings);
  }

  Widget _modernMediaCard(
      {required IconData icon,
      required String title,
      required VoidCallback onTap,
      required AppTheme theme,
      required AppSettingsProvider settings}) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        borderRadius: 25,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 48,
                color: ThemeHelper.primary(theme,
                    customColor: settings.customPrimary)),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ThemeHelper.textPrimary(theme),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rootFolderUI(AppTheme theme, AppSettingsProvider settings) {
    final items = _selectedIndex == 0 ? _videoRootItems : _audioRootItems;
    if (_isLoadingRoot && items.isEmpty)
      return const Center(child: CircularProgressIndicator());
    if (items.isEmpty)
      return const EmptyStateWidget(
          icon: Icons.folder_open_rounded,
          title: "No Folders",
          subtitle: "We couldn't find any media folders in this directory.");

    List<FileSystemEntity> sorted = List.from(items);
    if (settings.sortMode == SortMode.name)
      sorted.sort(
          (a, b) => a.path.split('/').last.compareTo(b.path.split('/').last));

    return ResponsiveBuilder(
      compact: (context, constraints) =>
          _buildRootGrid(sorted, 2, theme, settings),
      medium: (context, constraints) =>
          _buildRootGrid(sorted, 3, theme, settings),
      expanded: (context, constraints) =>
          _buildRootGrid(sorted, 5, theme, settings),
    );
  }

  Widget _buildRootGrid(List<FileSystemEntity> sorted, int crossAxisCount,
      AppTheme theme, AppSettingsProvider settings) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: sorted.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20),
      itemBuilder: (_, index) {
        final item = sorted[index];
        final name = item.path.split('/').last;
        return _modernMediaCard(
          icon: item is Directory
              ? Icons.folder_rounded
              : Icons.insert_drive_file_rounded,
          title: name,
          theme: theme,
          settings: settings,
          onTap: () {
            if (item is Directory) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => DirectoryScreen(
                          path: item.path, isVideo: _selectedIndex == 0)));
            } else {
              _openFile(item.path);
            }
          },
        );
      },
    );
  }
}
