import 'package:flutter/material.dart';
import 'package:markedplay/Pages/videoplayer/VideoListScreen.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../widgets/media_appbar.dart';
import 'audio player/AudioListScreen.dart';
import 'audio player/Audioplayer.dart';
import 'audio player/Audioplayerprovider.dart';
import 'videoplayer/Videoplayer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _hasPermission = false;

  final OnAudioQuery _audioQuery = OnAudioQuery();
  final MediaAppBarController _appBarController =
  MediaAppBarController();

  List<AssetPathEntity> videoFolders = [];
  List<AlbumModel> audioFolders = [];

  String? lastPlayedVideo;
  String? lastPlayedAudio;

  @override
  void initState() {
    super.initState();

    _appBarController.addListener(() {
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initMedia();
    });
  }

  Future<void> _initMedia() async {
    final pmPermission = await PhotoManager.requestPermissionExtend();
    if (!pmPermission.isAuth) {
      PhotoManager.openSetting();
      return;
    }

    bool audioPermission = await _audioQuery.permissionsStatus();
    if (!audioPermission) {
      audioPermission = await _audioQuery.permissionsRequest();
      if (!audioPermission) return;
    }

    videoFolders =
    await PhotoManager.getAssetPathList(type: RequestType.video);

    audioFolders = await _audioQuery.queryAlbums();

    setState(() {
      _hasPermission = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MediaAppBarWidget(
        title:
        _selectedIndex == 0 ? "Video Folders" : "Music Folders",
        controller: _appBarController,
      ),
      body: !_hasPermission
          ? const Center(child: Text("Permission Required"))
          : _selectedIndex == 0
          ? _buildVideoFolders()
          : _buildAudioFolders(),
      bottomNavigationBar: _bottomNav(),
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildFAB(),
      ),
    );
  }

  // ================= VIDEO =================

  Widget _buildVideoFolders() {
    _applyVideoSort();

    return _appBarController.viewMode == ViewMode.list
        ? ListView.builder(
      itemCount: videoFolders.length,
      itemBuilder: (_, index) =>
          _videoTile(videoFolders[index]),
    )
        : GridView.builder(
      gridDelegate:
      const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
      ),
      itemCount: videoFolders.length,
      itemBuilder: (_, index) =>
          _videoGrid(videoFolders[index]),
    );
  }

  Widget _videoTile(AssetPathEntity folder) {
    return ListTile(
      leading: const Icon(Icons.folder, size: 35),
      title: Text(folder.name),
      subtitle: FutureBuilder<int>(
        future: folder.assetCountAsync,
        builder: (_, snapshot) {
          if (!snapshot.hasData) return const Text("Loading...");
          return Text("${snapshot.data} videos");
        },
      ),
      onTap: () async {
        final videos =
        await folder.getAssetListPaged(page: 0, size: 1000);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoListScreen(
              folderName: folder.name,
              videos: videos,
            ),
          ),
        );
      },
    );
  }

  Widget _videoGrid(AssetPathEntity folder) {
    return FutureBuilder<int>(
      future: folder.assetCountAsync,
      builder: (_, snapshot) {
        return Card(
          child: InkWell(
            onTap: () async {
              final videos =
              await folder.getAssetListPaged(page: 0, size: 1000);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VideoListScreen(
                    folderName: folder.name,
                    videos: videos,
                  ),
                ),
              );
            },
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder, size: 50),
                  const SizedBox(height: 8),
                  Text(folder.name,
                      textAlign: TextAlign.center),
                  if (snapshot.hasData)
                    Text("${snapshot.data} videos"),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _applyVideoSort() {
    switch (_appBarController.sortMode) {
      case SortMode.name:
        videoFolders.sort(
                (a, b) => a.name.compareTo(b.name));
        break;
      case SortMode.date:
        break; // MediaStore handles internally
      case SortMode.size:
        break;
    }
  }

  // ================= AUDIO =================

  Widget _buildAudioFolders() {
    _applyAudioSort();

    return _appBarController.viewMode == ViewMode.list
        ? ListView.builder(
      itemCount: audioFolders.length,
      itemBuilder: (_, index) =>
          _audioTile(audioFolders[index]),
    )
        : GridView.builder(
      gridDelegate:
      const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
      ),
      itemCount: audioFolders.length,
      itemBuilder: (_, index) =>
          _audioGrid(audioFolders[index]),
    );
  }

  Widget _audioTile(AlbumModel album) {
    return ListTile(
      leading: const Icon(Icons.folder, size: 35),
      title: Text(album.album),
      subtitle: Text("${album.numOfSongs} songs"),
      onTap: () async {
        final songs = await _audioQuery.queryAudiosFrom(
          AudiosFromType.ALBUM_ID,
          album.id,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AudioListScreen(
              albumName: album.album,
              songs: songs,
            ),
          ),
        );
      },
    );
  }

  Widget _audioGrid(AlbumModel album) {
    return Card(
      child: InkWell(
        onTap: () async {
          final songs = await _audioQuery.queryAudiosFrom(
            AudiosFromType.ALBUM_ID,
            album.id,
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AudioListScreen(
                albumName: album.album,
                songs: songs,
              ),
            ),
          );
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.folder, size: 50),
              const SizedBox(height: 8),
              Text(album.album,
                  textAlign: TextAlign.center),
              Text("${album.numOfSongs} songs"),
            ],
          ),
        ),
      ),
    );
  }

  void _applyAudioSort() {
    switch (_appBarController.sortMode) {
      case SortMode.name:
        audioFolders.sort(
                (a, b) => a.album.compareTo(b.album));
        break;
      case SortMode.date:
        break;
      case SortMode.size:
        audioFolders.sort((a, b) =>
            b.numOfSongs.compareTo(a.numOfSongs));
        break;
    }
  }

  // ================= NAVIGATION =================

  Widget _bottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (i) => setState(() => _selectedIndex = i),
      selectedItemColor: Colors.cyanAccent,
      backgroundColor: Colors.black87,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.video_library),
          label: "Videos",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.music_note),
          label: "Music",
        ),
      ],
    );
  }

  Widget? _buildFAB() {
    // Decide if FAB should be visible
    final bool showFab =
        (_selectedIndex == 0 && lastPlayedVideo != null) ||
            (_selectedIndex == 1 && lastPlayedAudio != null);

    if (!showFab) return null;

    return FloatingActionButton(
      child: const Icon(Icons.play_arrow),
      onPressed: () {
        if (_selectedIndex == 0 && lastPlayedVideo != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  VideoPlayerScreen(filePath: lastPlayedVideo!),
            ),
          );
        }

        if (_selectedIndex == 1 && lastPlayedAudio != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AudioPlayerScreen(
                filePath: lastPlayedAudio!,
                startPosition:
                Provider.of<AudioPlayerProvider>(
                  context,
                  listen: false,
                ).currentPosition,
              ),
            ),
          );
        }
      },
    );
  }}