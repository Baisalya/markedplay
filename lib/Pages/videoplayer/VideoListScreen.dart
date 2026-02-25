import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

import '../../core/app_settings_provider.dart';
import '../../core/media_enums.dart';
import '../../core/theme_helper.dart';
import 'Videoplayer.dart';

class VideoListScreen extends StatelessWidget {
  final String folderName;
  final List<AssetEntity> videos;

  const VideoListScreen({
    super.key,
    required this.folderName,
    required this.videos,
  });

  @override
  Widget build(BuildContext context) {

    final settings = context.watch<AppSettingsProvider>();
    final theme = settings.theme;

    final primaryColor = ThemeHelper.primary(
      theme,
      customColor: settings.customPrimary,
    );

    final backgroundColor = ThemeHelper.background(
      theme,
      customColor: settings.customPrimary,
    );

    final sortedVideos = [...videos];

    // 🔥 Global Sorting
    if (settings.sortMode == SortMode.name) {
      sortedVideos.sort(
            (a, b) => (a.title ?? "")
            .compareTo(b.title ?? ""),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        backgroundColor: ThemeHelper.appBarColor(
          theme,
          customColor: settings.customPrimary,
        ),
        elevation: 0,
        centerTitle: true,
        title: Text(
          folderName,
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        iconTheme: IconThemeData(
          color: primaryColor,
        ),
      ),

      body: settings.viewMode == ViewMode.list
          ? _buildListView(
        context,
        sortedVideos,
        theme,
        settings,
      )
          : _buildGridView(
        context,
        sortedVideos,
        theme,
        settings,
      ),
    );
  }

  // ================= LIST VIEW =================

  Widget _buildListView(
      BuildContext context,
      List<AssetEntity> videos,
      AppTheme theme,
      AppSettingsProvider settings,
      ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: videos.length,
      itemBuilder: (_, index) {

        final video = videos[index];

        return FutureBuilder<File?>(
          future: video.file,
          builder: (_, snapshot) {

            if (!snapshot.hasData) {
              return const SizedBox();
            }

            return Container(
              margin:
              const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: ThemeHelper.cardColor(
                  theme,
                  customColor: settings.customPrimary,
                ),
                borderRadius:
                BorderRadius.circular(16),
                border: Border.all(
                  color: ThemeHelper.borderColor(
                    theme,
                    customColor:
                    settings.customPrimary,
                  ),
                ),
              ),
              child: ListTile(
                leading:
                FutureBuilder<Uint8List?>(
                  future:
                  video.thumbnailDataWithSize(
                    const ThumbnailSize(
                        200, 200),
                  ),
                  builder: (_, snap) {

                    if (!snap.hasData) {
                      return Icon(
                        Icons.video_library,
                        color:
                        ThemeHelper.primary(
                          theme,
                          customColor:
                          settings
                              .customPrimary,
                        ),
                      );
                    }

                    return ClipRRect(
                      borderRadius:
                      BorderRadius.circular(
                          8),
                      child: Image.memory(
                        snap.data!,
                        width: 70,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
                title: Text(
                  video.title ?? "Video",
                  style: TextStyle(
                    color: ThemeHelper
                        .textPrimary(theme),
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          VideoPlayerScreen(
                            filePath:
                            snapshot.data!.path,
                          ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // ================= GRID VIEW =================

  Widget _buildGridView(
      BuildContext context,
      List<AssetEntity> videos,
      AppTheme theme,
      AppSettingsProvider settings,
      ) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate:
      const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: videos.length,
      itemBuilder: (_, index) {

        final video = videos[index];

        return FutureBuilder<File?>(
          future: video.file,
          builder: (_, snapshot) {

            if (!snapshot.hasData) {
              return const SizedBox();
            }

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        VideoPlayerScreen(
                          filePath:
                          snapshot.data!.path,
                        ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: ThemeHelper.cardColor(
                    theme,
                    customColor:
                    settings.customPrimary,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                      20),
                  border: Border.all(
                    color: ThemeHelper.borderColor(
                      theme,
                      customColor:
                      settings.customPrimary,
                    ),
                  ),
                ),
                child: Column(
                  children: [

                    // 🎬 Thumbnail
                    Expanded(
                      child:
                      FutureBuilder<
                          Uint8List?>(
                        future:
                        video.thumbnailDataWithSize(
                          const ThumbnailSize(
                              400, 400),
                        ),
                        builder:
                            (_, snap) {

                          if (!snap.hasData) {
                            return Icon(
                              Icons.video_library,
                              color:
                              ThemeHelper
                                  .primary(
                                theme,
                                customColor:
                                settings
                                    .customPrimary,
                              ),
                              size: 40,
                            );
                          }

                          return ClipRRect(
                            borderRadius:
                            const BorderRadius
                                .vertical(
                              top:
                              Radius.circular(
                                  20),
                            ),
                            child:
                            Image.memory(
                              snap.data!,
                              width: double
                                  .infinity,
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
                    ),

                    // 🎞 Title
                    Padding(
                      padding:
                      const EdgeInsets
                          .all(8),
                      child: Text(
                        video.title ??
                            "Video",
                        maxLines: 1,
                        overflow:
                        TextOverflow
                            .ellipsis,
                        style:
                        TextStyle(
                          color: ThemeHelper
                              .textPrimary(
                              theme),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}