import 'package:photo_manager/photo_manager.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart' as permissions;
import 'package:flutter/foundation.dart';
import 'dart:io';

class MediaPermissionResult {
  final bool audioGranted;
  final bool videoGranted;
  final bool requiresSettings;

  const MediaPermissionResult({
    required this.audioGranted,
    required this.videoGranted,
    this.requiresSettings = false,
  });
}

class MediaPermissionService {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  bool get supportsMediaLibrary =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<MediaPermissionResult> requestPermissions() async {
    if (!supportsMediaLibrary) {
      return const MediaPermissionResult(
        audioGranted: false,
        videoGranted: false,
      );
    }

    final photoPermission = await PhotoManager.requestPermissionExtend(
      requestOption: const PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: RequestType.video,
          mediaLocation: false,
        ),
      ),
    );
    final videoGranted = photoPermission.isAuth || photoPermission.hasAccess;

    var audioGranted = await _audioQuery.permissionsStatus();
    if (!audioGranted) {
      audioGranted = await _audioQuery.permissionsRequest();
    }

    var requiresSettings = false;
    if (Platform.isAndroid) {
      final audioStatus = await permissions.Permission.audio.status;
      final videoStatus = await permissions.Permission.videos.status;
      requiresSettings =
          audioStatus.isPermanentlyDenied || videoStatus.isPermanentlyDenied;
      final notificationStatus =
          await permissions.Permission.notification.status;
      if ((audioGranted || videoGranted) && notificationStatus.isDenied) {
        await permissions.Permission.notification.request();
      }
    } else if (Platform.isIOS) {
      final photosStatus = await permissions.Permission.photos.status;
      requiresSettings = photosStatus.isPermanentlyDenied;
    }

    return MediaPermissionResult(
      audioGranted: audioGranted,
      videoGranted: videoGranted,
      requiresSettings: requiresSettings,
    );
  }

  Future<bool> openSettings() => permissions.openAppSettings();
}
