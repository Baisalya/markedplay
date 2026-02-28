import 'package:on_audio_query/on_audio_query.dart';

class AudioService {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  Future<List<AlbumModel>> getAlbums() async {
    return await _audioQuery.queryAlbums();
  }

  Future<List<SongModel>> getSongsFromAlbum(int id) async {
    return await _audioQuery.queryAudiosFrom(
      AudiosFromType.ALBUM_ID,
      id,
    );
  }

  Future<List<SongModel>> getAllSongs() async {
    return await _audioQuery.querySongs();
  }
}