import 'package:photo_manager/photo_manager.dart';
import 'package:on_audio_query/on_audio_query.dart';

class MediaPermissionService {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  Future<bool> requestPermissions() async {
    final photoPermission =
    await PhotoManager.requestPermissionExtend();

    if (!(photoPermission.isAuth || photoPermission.hasAccess)) {
      await PhotoManager.openSetting();
      return false;
    }

    bool audioPermission = await _audioQuery.permissionsStatus();

    if (!audioPermission) {
      audioPermission = await _audioQuery.permissionsRequest();
      if (!audioPermission) return false;
    }

    return true;
  }
}