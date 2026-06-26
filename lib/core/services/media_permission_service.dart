import 'package:photo_manager/photo_manager.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class MediaPermissionService {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  Future<bool> requestPermissions() async {
    // Handle Android 13+ READ_MEDIA_AUDIO and READ_MEDIA_VIDEO
    if (Platform.isAndroid) {
      final photoPermission = await PhotoManager.requestPermissionExtend();
      if (!(photoPermission.isAuth || photoPermission.hasAccess)) {
        await PhotoManager.openSetting();
        return false;
      }

      bool audioPermission = await _audioQuery.permissionsStatus();
      if (!audioPermission) {
        audioPermission = await _audioQuery.permissionsRequest();
        if (!audioPermission) {
          // Fallback check for Android 13+
          final status = await Permission.audio.status;
          if (!status.isGranted) {
             final request = await Permission.audio.request();
             if (!request.isGranted) return false;
          }
        }
      }
    }

    return true;
  }
}
