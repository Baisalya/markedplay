import 'package:photo_manager/photo_manager.dart';

class VideoService {

  Future<List<AssetPathEntity>> getVideoFolders() async {
    return await PhotoManager.getAssetPathList(
      type: RequestType.video,
    );
  }

  Future<List<AssetEntity>> getVideosFromFolder(
      AssetPathEntity folder) async {
    return await folder.getAssetListPaged(
      page: 0,
      size: 1000,
    );
  }

  Future<List<AssetEntity>> getAllVideos() async {
    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.video,
    );

    if (paths.isEmpty) return [];

    return paths.first.getAssetListPaged(
      page: 0,
      size: 2000,
    );
  }
}