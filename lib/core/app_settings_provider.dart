import 'package:flutter/material.dart' hide RepeatMode;
import 'package:shared_preferences/shared_preferences.dart';

import 'media_enums.dart';

class AppSettingsProvider extends ChangeNotifier {
  // --- UI Settings ---
  AppTheme _theme = AppTheme.neon;
  ViewMode _viewMode = ViewMode.grid;
  SortMode _sortMode = SortMode.name;
  BrowseMode _browseMode = BrowseMode.allFolders;
  Color _customPrimary = Colors.blueAccent;
  List<String> _favorites = [];
  List<String> _recentlyPlayed = [];

  // --- Playback Settings ---
  BackgroundPlayMode _backgroundPlayMode = BackgroundPlayMode.off;
  bool _resumeLastPosition = true;
  bool _autoPlayNext = true;
  RepeatMode _repeatMode = RepeatMode.off;
  bool _shuffle = false;
  double _defaultPlaybackSpeed = 1.0;
  bool _rememberSpeedPerFile = false;
  int _seekStep = 10; // seconds
  bool _doubleTapSeek = true;
  bool _pauseOnHeadphonesDisconnected = true;
  bool _keepScreenAwake = true;
  bool _lockControlsDuringPlayback = false;

  // --- Video Settings ---
  DecoderMode _decoderMode = DecoderMode.auto;
  AspectRatioMode _defaultAspectRatio = AspectRatioMode.fit;
  bool _autoRotateVideo = true;
  bool _rememberOrientationPerVideo = false;
  bool _brightnessGesture = true;
  bool _volumeGesture = true;
  bool _seekGesture = true;

  // --- Audio Settings ---
  bool _resumeLastPositionAudio = true;
  bool _rememberLastPlayedSong = true;

  // --- Subtitle Settings ---
  bool _showSubtitles = true;
  bool _autoLoadSubtitles = true;
  double _subtitleSize = 18.0;
  int _subtitleColorValue = Colors.white.toARGB32();
  int _subtitleBackgroundColorValue = Colors.black45.toARGB32();
  String _subtitleEncoding = 'utf-8';

  // --- Library Settings ---
  bool _showHiddenFiles = false;

  // --- Getters ---
  AppTheme get theme => _theme;
  ViewMode get viewMode => _viewMode;
  SortMode get sortMode => _sortMode;
  BrowseMode get browseMode => _browseMode;
  Color get customPrimary => _customPrimary;
  List<String> get favorites => List.unmodifiable(_favorites);
  List<String> get recentlyPlayed => List.unmodifiable(_recentlyPlayed);

  BackgroundPlayMode get backgroundPlayMode => _backgroundPlayMode;
  bool get resumeLastPosition => _resumeLastPosition;
  bool get autoPlayNext => _autoPlayNext;
  RepeatMode get repeatMode => _repeatMode;
  bool get shuffle => _shuffle;
  double get defaultPlaybackSpeed => _defaultPlaybackSpeed;
  bool get rememberSpeedPerFile => _rememberSpeedPerFile;
  int get seekStep => _seekStep;
  bool get doubleTapSeek => _doubleTapSeek;
  bool get pauseOnHeadphonesDisconnected => _pauseOnHeadphonesDisconnected;
  bool get keepScreenAwake => _keepScreenAwake;
  bool get lockControlsDuringPlayback => _lockControlsDuringPlayback;

  DecoderMode get decoderMode => _decoderMode;
  AspectRatioMode get defaultAspectRatio => _defaultAspectRatio;
  bool get autoRotateVideo => _autoRotateVideo;
  bool get rememberOrientationPerVideo => _rememberOrientationPerVideo;
  bool get brightnessGesture => _brightnessGesture;
  bool get volumeGesture => _volumeGesture;
  bool get seekGesture => _seekGesture;

  bool get resumeLastPositionAudio => _resumeLastPositionAudio;
  bool get rememberLastPlayedSong => _rememberLastPlayedSong;

  bool get showSubtitles => _showSubtitles;
  bool get autoLoadSubtitles => _autoLoadSubtitles;
  double get subtitleSize => _subtitleSize;
  Color get subtitleColor => Color(_subtitleColorValue);
  Color get subtitleBackgroundColor => Color(_subtitleBackgroundColorValue);
  String get subtitleEncoding => _subtitleEncoding;

  bool get showHiddenFiles => _showHiddenFiles;

  AppSettingsProvider() {
    _loadSettings();
  }

  // ================= LOAD =================

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _theme = _enumFromIndex(
      AppTheme.values,
      prefs.getInt("theme"),
      AppTheme.neon,
    );
    _viewMode = _enumFromIndex(
      ViewMode.values,
      prefs.getInt("viewMode"),
      ViewMode.grid,
    );
    _sortMode = _enumFromIndex(
      SortMode.values,
      prefs.getInt("sortMode"),
      SortMode.name,
    );
    _browseMode = _enumFromIndex(
      BrowseMode.values,
      prefs.getInt("browseMode"),
      BrowseMode.allFolders,
    );
    _customPrimary =
        Color(prefs.getInt("customPrimary") ?? Colors.blueAccent.toARGB32());
    _favorites = prefs.getStringList("favorites") ?? [];
    _recentlyPlayed = prefs.getStringList("recentlyPlayed") ?? [];

    _backgroundPlayMode = _enumFromIndex(
      BackgroundPlayMode.values,
      prefs.getInt("backgroundPlayMode"),
      BackgroundPlayMode.off,
    );
    _resumeLastPosition = prefs.getBool("resumeLastPosition") ?? true;
    _autoPlayNext = prefs.getBool("autoPlayNext") ?? true;
    _repeatMode = _enumFromIndex(
      RepeatMode.values,
      prefs.getInt("repeatMode"),
      RepeatMode.off,
    );
    _shuffle = prefs.getBool("shuffle") ?? false;
    _defaultPlaybackSpeed = prefs.getDouble("defaultPlaybackSpeed") ?? 1.0;
    _rememberSpeedPerFile = prefs.getBool("rememberSpeedPerFile") ?? false;
    _seekStep = prefs.getInt("seekStep") ?? 10;
    _doubleTapSeek = prefs.getBool("doubleTapSeek") ?? true;
    _pauseOnHeadphonesDisconnected =
        prefs.getBool("pauseOnHeadphonesDisconnected") ?? true;
    _keepScreenAwake = prefs.getBool("keepScreenAwake") ?? true;
    _lockControlsDuringPlayback =
        prefs.getBool("lockControlsDuringPlayback") ?? false;

    _decoderMode = _enumFromIndex(
      DecoderMode.values,
      prefs.getInt("decoderMode"),
      DecoderMode.auto,
    );
    _defaultAspectRatio = _enumFromIndex(
      AspectRatioMode.values,
      prefs.getInt("defaultAspectRatio"),
      AspectRatioMode.fit,
    );
    _autoRotateVideo = prefs.getBool("autoRotateVideo") ?? true;
    _rememberOrientationPerVideo =
        prefs.getBool("rememberOrientationPerVideo") ?? false;
    _brightnessGesture = prefs.getBool("brightnessGesture") ?? true;
    _volumeGesture = prefs.getBool("volumeGesture") ?? true;
    _seekGesture = prefs.getBool("seekGesture") ?? true;

    _resumeLastPositionAudio = prefs.getBool("resumeLastPositionAudio") ?? true;
    _rememberLastPlayedSong = prefs.getBool("rememberLastPlayedSong") ?? true;

    _showSubtitles = prefs.getBool("showSubtitles") ?? true;
    _autoLoadSubtitles = prefs.getBool("autoLoadSubtitles") ?? true;
    _subtitleSize = prefs.getDouble("subtitleSize") ?? 18.0;
    _subtitleColorValue =
        prefs.getInt("subtitleColor") ?? Colors.white.toARGB32();
    _subtitleBackgroundColorValue =
        prefs.getInt("subtitleBackgroundColor") ?? Colors.black45.toARGB32();
    _subtitleEncoding = prefs.getString("subtitleEncoding") ?? 'utf-8';

    _showHiddenFiles = prefs.getBool("showHiddenFiles") ?? false;

    notifyListeners();
  }

  T _enumFromIndex<T extends Enum>(
    List<T> values,
    int? index,
    T fallback,
  ) {
    if (index == null || index < 0 || index >= values.length) {
      return fallback;
    }
    return values[index];
  }

  // ================= SETTERS =================

  Future<void> _setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    notifyListeners();
  }

  Future<void> _setInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
    notifyListeners();
  }

  Future<void> _setDouble(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value);
    notifyListeners();
  }

  Future<void> _setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
    notifyListeners();
  }

  // BROWSE MODE
  Future<void> setBrowseMode(BrowseMode mode) async {
    _browseMode = mode;
    await _setInt("browseMode", mode.index);
  }

  // THEME
  Future<void> setTheme(AppTheme theme) async {
    _theme = theme;
    await _setInt("theme", theme.index);
  }

  Future<void> setCustomColor(Color color) async {
    _customPrimary = color;
    await _setInt("customPrimary", color.toARGB32());
  }

  // VIEW
  Future<void> setViewMode(ViewMode mode) async {
    _viewMode = mode;
    await _setInt("viewMode", mode.index);
  }

  Future<void> setSortMode(SortMode mode) async {
    _sortMode = mode;
    await _setInt("sortMode", mode.index);
  }

  // FAVORITES & RECENT
  Future<void> toggleFavorite(String path) async {
    if (_favorites.contains(path)) {
      _favorites.remove(path);
    } else {
      _favorites.add(path);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList("favorites", _favorites);
    notifyListeners();
  }

  Future<void> addRecentlyPlayed(String path) async {
    _recentlyPlayed.remove(path);
    _recentlyPlayed.insert(0, path);
    if (_recentlyPlayed.length > 20) _recentlyPlayed.removeLast();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList("recentlyPlayed", _recentlyPlayed);
    notifyListeners();
  }

  Future<void> clearRecentlyPlayed() async {
    _recentlyPlayed.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList("recentlyPlayed", _recentlyPlayed);
    notifyListeners();
  }

  Future<void> removeRecentlyPlayed(String path) async {
    if (!_recentlyPlayed.remove(path)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList("recentlyPlayed", _recentlyPlayed);
    notifyListeners();
  }

  // PLAYBACK SETTERS
  Future<void> setBackgroundPlayMode(BackgroundPlayMode mode) async {
    _backgroundPlayMode = mode;
    await _setInt("backgroundPlayMode", mode.index);
  }

  Future<void> setResumeLastPosition(bool value) async {
    _resumeLastPosition = value;
    await _setBool("resumeLastPosition", value);
  }

  Future<void> setAutoPlayNext(bool value) async {
    _autoPlayNext = value;
    await _setBool("autoPlayNext", value);
  }

  Future<void> setRepeatMode(RepeatMode mode) async {
    _repeatMode = mode;
    await _setInt("repeatMode", mode.index);
  }

  Future<void> setShuffle(bool value) async {
    _shuffle = value;
    await _setBool("shuffle", value);
  }

  Future<void> setDefaultPlaybackSpeed(double value) async {
    _defaultPlaybackSpeed = value;
    await _setDouble("defaultPlaybackSpeed", value);
  }

  Future<void> setRememberSpeedPerFile(bool value) async {
    _rememberSpeedPerFile = value;
    await _setBool("rememberSpeedPerFile", value);
  }

  Future<void> setSeekStep(int value) async {
    _seekStep = value;
    await _setInt("seekStep", value);
  }

  Future<void> setDoubleTapSeek(bool value) async {
    _doubleTapSeek = value;
    await _setBool("doubleTapSeek", value);
  }

  Future<void> setPauseOnHeadphonesDisconnected(bool value) async {
    _pauseOnHeadphonesDisconnected = value;
    await _setBool("pauseOnHeadphonesDisconnected", value);
  }

  Future<void> setKeepScreenAwake(bool value) async {
    _keepScreenAwake = value;
    await _setBool("keepScreenAwake", value);
  }

  Future<void> setLockControlsDuringPlayback(bool value) async {
    _lockControlsDuringPlayback = value;
    await _setBool("lockControlsDuringPlayback", value);
  }

  // VIDEO SETTERS
  Future<void> setDecoderMode(DecoderMode mode) async {
    _decoderMode = mode;
    await _setInt("decoderMode", mode.index);
  }

  Future<void> setDefaultAspectRatio(AspectRatioMode mode) async {
    _defaultAspectRatio = mode;
    await _setInt("defaultAspectRatio", mode.index);
  }

  Future<void> setAutoRotateVideo(bool value) async {
    _autoRotateVideo = value;
    await _setBool("autoRotateVideo", value);
  }

  Future<void> setRememberOrientationPerVideo(bool value) async {
    _rememberOrientationPerVideo = value;
    await _setBool("rememberOrientationPerVideo", value);
  }

  Future<void> setBrightnessGesture(bool value) async {
    _brightnessGesture = value;
    await _setBool("brightnessGesture", value);
  }

  Future<void> setVolumeGesture(bool value) async {
    _volumeGesture = value;
    await _setBool("volumeGesture", value);
  }

  Future<void> setSeekGesture(bool value) async {
    _seekGesture = value;
    await _setBool("seekGesture", value);
  }

  // AUDIO SETTERS
  Future<void> setResumeLastPositionAudio(bool value) async {
    _resumeLastPositionAudio = value;
    await _setBool("resumeLastPositionAudio", value);
  }

  Future<void> setRememberLastPlayedSong(bool value) async {
    _rememberLastPlayedSong = value;
    await _setBool("rememberLastPlayedSong", value);
  }

  // SUBTITLE SETTERS
  Future<void> setShowSubtitles(bool value) async {
    _showSubtitles = value;
    await _setBool("showSubtitles", value);
  }

  Future<void> setAutoLoadSubtitles(bool value) async {
    _autoLoadSubtitles = value;
    await _setBool("autoLoadSubtitles", value);
  }

  Future<void> setSubtitleSize(double value) async {
    _subtitleSize = value;
    await _setDouble("subtitleSize", value);
  }

  Future<void> setSubtitleColor(Color color) async {
    _subtitleColorValue = color.toARGB32();
    await _setInt("subtitleColor", color.toARGB32());
  }

  Future<void> setSubtitleBackgroundColor(Color color) async {
    _subtitleBackgroundColorValue = color.toARGB32();
    await _setInt("subtitleBackgroundColor", color.toARGB32());
  }

  Future<void> setSubtitleEncoding(String encoding) async {
    _subtitleEncoding = encoding;
    await _setString("subtitleEncoding", encoding);
  }

  // LIBRARY SETTERS
  Future<void> setShowHiddenFiles(bool value) async {
    _showHiddenFiles = value;
    await _setBool("showHiddenFiles", value);
  }
}
