import 'package:flutter/material.dart' hide RepeatMode;
import 'package:provider/provider.dart';

import '../../core/app_settings_provider.dart';
import '../../core/media_enums.dart';
import '../../core/theme_helper.dart';
import '../../widgets/modern_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    final theme = settings.theme;
    final primaryColor = ThemeHelper.primary(theme, customColor: settings.customPrimary);
    final backgroundColor = Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text("Settings", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: primaryColor),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildSectionHeader("Appearance", primaryColor),
          _buildThemeTile(context, settings, primaryColor),
          if (settings.theme == AppTheme.custom)
            _buildCustomColorTile(context, settings, primaryColor),

          _buildSectionHeader("Playback", primaryColor),
          _buildEnumTile<BackgroundPlayMode>(
            context: context,
            title: "Background Play",
            subtitle: "Behavior when leaving the player",
            value: settings.backgroundPlayMode,
            options: BackgroundPlayMode.values,
            onChanged: settings.setBackgroundPlayMode,
            primaryColor: primaryColor,
          ),
          _buildSwitchTile(
            title: "Resume last position",
            value: settings.resumeLastPosition,
            onChanged: settings.setResumeLastPosition,
            primaryColor: primaryColor,
          ),
          _buildSwitchTile(
            title: "Auto-play next file",
            value: settings.autoPlayNext,
            onChanged: settings.setAutoPlayNext,
            primaryColor: primaryColor,
          ),
          _buildEnumTile<RepeatMode>(
            context: context,
            title: "Repeat Mode",
            value: settings.repeatMode,
            options: RepeatMode.values,
            onChanged: settings.setRepeatMode,
            primaryColor: primaryColor,
          ),
          _buildIntPickerTile(
            context: context,
            title: "Seek step",
            value: settings.seekStep,
            options: [5, 10, 15, 30],
            suffix: "s",
            onChanged: settings.setSeekStep,
            primaryColor: primaryColor,
          ),
          _buildSwitchTile(
            title: "Double-tap seek",
            value: settings.doubleTapSeek,
            onChanged: settings.setDoubleTapSeek,
            primaryColor: primaryColor,
          ),
          _buildSwitchTile(
            title: "Keep screen awake",
            value: settings.keepScreenAwake,
            onChanged: settings.setKeepScreenAwake,
            primaryColor: primaryColor,
          ),

          _buildSectionHeader("Video", primaryColor),
          _buildEnumTile<AspectRatioMode>(
            context: context,
            title: "Default Aspect Ratio",
            value: settings.defaultAspectRatio,
            options: AspectRatioMode.values,
            onChanged: settings.setDefaultAspectRatio,
            primaryColor: primaryColor,
          ),
          _buildSwitchTile(
            title: "Brightness gesture",
            value: settings.brightnessGesture,
            onChanged: settings.setBrightnessGesture,
            primaryColor: primaryColor,
          ),
          _buildSwitchTile(
            title: "Volume gesture",
            value: settings.volumeGesture,
            onChanged: settings.setVolumeGesture,
            primaryColor: primaryColor,
          ),
          _buildSwitchTile(
            title: "Seek gesture",
            value: settings.seekGesture,
            onChanged: settings.setSeekGesture,
            primaryColor: primaryColor,
          ),

          _buildSectionHeader("Subtitles", primaryColor),
          _buildSwitchTile(
            title: "Show subtitles",
            value: settings.showSubtitles,
            onChanged: settings.setShowSubtitles,
            primaryColor: primaryColor,
          ),
          _buildSwitchTile(
            title: "Auto-load subtitles",
            value: settings.autoLoadSubtitles,
            onChanged: settings.setAutoLoadSubtitles,
            primaryColor: primaryColor,
          ),
          _buildIntPickerTile(
            context: context,
            title: "Subtitle Size",
            value: settings.subtitleSize.toInt(),
            options: [12, 14, 16, 18, 20, 24, 28, 32],
            suffix: "px",
            onChanged: (val) => settings.setSubtitleSize(val.toDouble()),
            primaryColor: primaryColor,
          ),
          ListTile(
            title: const Text("Subtitle Color", style: TextStyle(color: Colors.white)),
            trailing: CircleAvatar(backgroundColor: settings.subtitleColor, radius: 12),
            onTap: () => _showColorPicker(context, settings, type: 'subtitle'),
          ),
          ListTile(
            title: const Text("Subtitle Background", style: TextStyle(color: Colors.white)),
            trailing: CircleAvatar(backgroundColor: settings.subtitleBackgroundColor, radius: 12),
            onTap: () => _showColorPicker(context, settings, type: 'subtitleBackground'),
          ),

          _buildSectionHeader("Library", primaryColor),
          _buildSwitchTile(
            title: "Show hidden files",
            value: settings.showHiddenFiles,
            onChanged: settings.setShowHiddenFiles,
            primaryColor: primaryColor,
          ),
          ListTile(
            title: const Text("Clear recent history", style: TextStyle(color: Colors.white)),
            leading: Icon(Icons.history_rounded, color: primaryColor),
            onTap: () async {
              final confirmed = await _showConfirmDialog(context, "Clear History", "Are you sure you want to clear your playback history?");
              if (confirmed) settings.clearRecentlyPlayed();
            },
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildThemeTile(BuildContext context, AppSettingsProvider settings, Color primaryColor) {
    return ListTile(
      leading: Icon(Icons.palette_rounded, color: primaryColor),
      title: const Text("Theme", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text(settings.theme.name.toUpperCase(), style: TextStyle(color: Colors.white60, fontSize: 12)),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: primaryColor),
      onTap: () => _showThemePicker(context, settings),
    );
  }

  Widget _buildCustomColorTile(BuildContext context, AppSettingsProvider settings, Color primaryColor) {
    return ListTile(
      leading: Icon(Icons.color_lens_rounded, color: primaryColor),
      title: const Text("Custom Accent Color", style: TextStyle(color: Colors.white)),
      trailing: CircleAvatar(backgroundColor: settings.customPrimary, radius: 12),
      onTap: () => _showColorPicker(context, settings),
    );
  }

  Widget _buildSwitchTile({required String title, required bool value, required Function(bool) onChanged, required Color primaryColor}) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      value: value,
      onChanged: onChanged,
      activeColor: primaryColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildEnumTile<T extends Enum>({
    required BuildContext context,
    required String title,
    String? subtitle,
    required T value,
    required List<T> options,
    required Function(T) onChanged,
    required Color primaryColor,
  }) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle ?? value.name.toUpperCase(), style: const TextStyle(color: Colors.white60, fontSize: 12)),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: primaryColor),
      onTap: () => _showEnumPicker(context, title, value, options, onChanged),
    );
  }

  Widget _buildIntPickerTile({
    required BuildContext context,
    required String title,
    required int value,
    required List<int> options,
    required Function(int) onChanged,
    required Color primaryColor,
    String suffix = "",
  }) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text("$value$suffix", style: const TextStyle(color: Colors.white60, fontSize: 12)),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: primaryColor),
      onTap: () => _showIntPicker(context, title, value, options, onChanged, suffix),
    );
  }

  // --- PICKERS ---

  void _showThemePicker(BuildContext context, AppSettingsProvider settings) {
    _showEnumPicker(context, "Select Theme", settings.theme, AppTheme.values, (val) {
      settings.setTheme(val);
      if (val == AppTheme.custom) _showColorPicker(context, settings);
    });
  }

  void _showEnumPicker<T extends Enum>(BuildContext context, String title, T currentValue, List<T> options, Function(T) onChanged) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, i) => ListTile(
                title: Text(options[i].name.toUpperCase(), style: TextStyle(color: options[i] == currentValue ? Colors.cyanAccent : Colors.white)),
                trailing: options[i] == currentValue ? const Icon(Icons.check_circle_rounded, color: Colors.cyanAccent) : null,
                onTap: () {
                  onChanged(options[i]);
                  Navigator.pop(context);
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showIntPicker(BuildContext context, String title, int currentValue, List<int> options, Function(int) onChanged, String suffix) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ...options.map((opt) => ListTile(
            title: Text("$opt$suffix", style: TextStyle(color: opt == currentValue ? Colors.cyanAccent : Colors.white)),
            trailing: opt == currentValue ? const Icon(Icons.check_circle_rounded, color: Colors.cyanAccent) : null,
            onTap: () {
              onChanged(opt);
              Navigator.pop(context);
            },
          )).toList(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showColorPicker(BuildContext context, AppSettingsProvider settings, {String type = 'accent'}) {
    final colors = [
      Colors.blue, Colors.purple, Colors.red, Colors.green,
      Colors.orange, Colors.teal, Colors.pink, Colors.amber,
      Colors.white, Colors.black, Colors.grey, Colors.cyanAccent,
    ];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(type == 'accent' ? "Accent Color" : "Pick Color", style: const TextStyle(color: Colors.white)),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors.map((color) => GestureDetector(
            onTap: () {
              if (type == 'accent') settings.setCustomColor(color);
              if (type == 'subtitle') settings.setSubtitleColor(color);
              if (type == 'subtitleBackground') settings.setSubtitleBackgroundColor(color);
              Navigator.pop(context);
            },
            child: CircleAvatar(backgroundColor: color, radius: 22),
          )).toList(),
        ),
      ),
    );
  }

  Future<bool> _showConfirmDialog(BuildContext context, String title, String message) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("CLEAR", style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    ) ?? false;
  }
}
