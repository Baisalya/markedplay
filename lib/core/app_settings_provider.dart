import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'media_enums.dart';

class AppSettingsProvider extends ChangeNotifier {

  AppTheme _theme = AppTheme.neon;
  ViewMode _viewMode = ViewMode.grid;
  SortMode _sortMode = SortMode.name;
  BrowseMode _browseMode = BrowseMode.allFolders;
  List<String> _favorites = [];
  List<String> _recentlyPlayed = [];

  Color _customPrimary = Colors.blueAccent;

  AppTheme get theme => _theme;
  ViewMode get viewMode => _viewMode;
  SortMode get sortMode => _sortMode;
  BrowseMode get browseMode => _browseMode;
  Color get customPrimary => _customPrimary;
  List<String> get favorites => _favorites;
  List<String> get recentlyPlayed => _recentlyPlayed;

  AppSettingsProvider() {
    _loadSettings();
  }

  // ================= LOAD =================

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _theme = AppTheme.values[
    prefs.getInt("theme") ?? 0];

    _viewMode = ViewMode.values[
    prefs.getInt("viewMode") ?? 0];

    _sortMode = SortMode.values[
    prefs.getInt("sortMode") ?? 0];

    _browseMode = BrowseMode.values[
    prefs.getInt("browseMode") ?? 0];

    _customPrimary = Color(
        prefs.getInt("customPrimary") ??
            Colors.blueAccent.value);

    _favorites = prefs.getStringList("favorites") ?? [];
    _recentlyPlayed = prefs.getStringList("recentlyPlayed") ?? [];

    notifyListeners();
  }

  // ================= BROWSE MODE =================

  Future<void> setBrowseMode(BrowseMode mode) async {
    _browseMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("browseMode", mode.index);
    notifyListeners();
  }

  // ================= THEME =================

  Future<void> setTheme(AppTheme theme) async {
    _theme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("theme", theme.index);
    notifyListeners();
  }

  Future<void> setCustomColor(Color color) async {
    _customPrimary = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        "customPrimary", color.value);
    notifyListeners();
  }

  // ================= VIEW =================

  Future<void> setViewMode(ViewMode mode) async {
    _viewMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("viewMode", mode.index);
    notifyListeners();
  }

  Future<void> setSortMode(SortMode mode) async {
    _sortMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("sortMode", mode.index);
    notifyListeners();
  }

  // ================= FAVORITES & RECENT =================

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
}