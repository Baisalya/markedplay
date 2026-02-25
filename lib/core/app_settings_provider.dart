import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'media_enums.dart';

class AppSettingsProvider extends ChangeNotifier {

  AppTheme _theme = AppTheme.neon;
  ViewMode _viewMode = ViewMode.grid;
  SortMode _sortMode = SortMode.name;

  Color _customPrimary = Colors.blueAccent;

  AppTheme get theme => _theme;
  ViewMode get viewMode => _viewMode;
  SortMode get sortMode => _sortMode;
  Color get customPrimary => _customPrimary;

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

    _customPrimary = Color(
        prefs.getInt("customPrimary") ??
            Colors.blueAccent.value);

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

  void setViewMode(ViewMode mode) async {
    _viewMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("viewMode", mode.index);
    notifyListeners();
  }

  void setSortMode(SortMode mode) async {
    _sortMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("sortMode", mode.index);
    notifyListeners();
  }
}