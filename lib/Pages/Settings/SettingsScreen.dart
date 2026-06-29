import 'package:flutter/material.dart' hide RepeatMode;
import 'package:provider/provider.dart';

import '../../core/app_settings_provider.dart';
import '../../core/media_enums.dart';
import '../../core/theme_helper.dart';
import '../../core/ui/widgets/mini_player_aware_padding.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    final theme = settings.theme;
    final primaryColor =
        ThemeHelper.primary(theme, customColor: settings.customPrimary);
    final backgroundColor =
        ThemeHelper.background(theme, customColor: settings.customPrimary);
    final textPrimary = ThemeHelper.textPrimary(theme);

    final appBarColor =
        ThemeHelper.appBarColor(theme, customColor: settings.customPrimary);

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        centerTitle: true,
        title: Text("Settings",
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: primaryColor),
      ),
      body: MiniPlayerAwarePadding(
        child: SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    options: BackgroundPlayMode.values
                        .where((mode) => mode != BackgroundPlayMode.pip)
                        .toList(),
                    onChanged: settings.setBackgroundPlayMode,
                    primaryColor: primaryColor,
                    theme: theme,
                  ),
                  _buildSwitchTile(
                    title: "Resume last position",
                    value: settings.resumeLastPosition,
                    onChanged: settings.setResumeLastPosition,
                    primaryColor: primaryColor,
                    theme: theme,
                  ),
                  _buildSwitchTile(
                    title: "Auto-play next file",
                    value: settings.autoPlayNext,
                    onChanged: settings.setAutoPlayNext,
                    primaryColor: primaryColor,
                    theme: theme,
                  ),
                  _buildEnumTile<RepeatMode>(
                    context: context,
                    title: "Repeat Mode",
                    value: settings.repeatMode,
                    options: RepeatMode.values,
                    onChanged: settings.setRepeatMode,
                    primaryColor: primaryColor,
                    theme: theme,
                  ),
                  _buildSwitchTile(
                    title: "Shuffle queue",
                    value: settings.shuffle,
                    onChanged: settings.setShuffle,
                    primaryColor: primaryColor,
                    theme: theme,
                  ),
                  ListTile(
                    title: Text(
                      'Default playback speed',
                      style: TextStyle(color: textPrimary),
                    ),
                    subtitle: Text(
                      '${settings.defaultPlaybackSpeed}x',
                      style: TextStyle(
                        color: ThemeHelper.textSecondary(theme),
                        fontSize: 12,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: primaryColor,
                    ),
                    onTap: () => _showSpeedPicker(context, settings),
                  ),
                  _buildIntPickerTile(
                    context: context,
                    title: "Seek step",
                    value: settings.seekStep,
                    options: [5, 10, 15, 30],
                    suffix: "s",
                    onChanged: settings.setSeekStep,
                    primaryColor: primaryColor,
                    theme: theme,
                  ),
                  _buildSwitchTile(
                    title: "Double-tap seek",
                    value: settings.doubleTapSeek,
                    onChanged: settings.setDoubleTapSeek,
                    primaryColor: primaryColor,
                    theme: theme,
                  ),
                  _buildSwitchTile(
                    title: "Keep screen awake",
                    value: settings.keepScreenAwake,
                    onChanged: settings.setKeepScreenAwake,
                    primaryColor: primaryColor,
                    theme: theme,
                  ),
                  _buildSectionHeader("Audio", primaryColor),
                  _buildSwitchTile(
                    title: "Resume music where I stopped",
                    value: settings.resumeLastPositionAudio,
                    onChanged: settings.setResumeLastPositionAudio,
                    primaryColor: primaryColor,
                    theme: theme,
                  ),
                  _buildSectionHeader("Video", primaryColor),
                  _buildEnumTile<AspectRatioMode>(
                    context: context,
                    title: "Default Aspect Ratio",
                    value: settings.defaultAspectRatio,
                    options: AspectRatioMode.values,
                    onChanged: settings.setDefaultAspectRatio,
                    primaryColor: primaryColor,
                    theme: theme,
                  ),
                  _buildSwitchTile(
                    title: "Brightness gesture",
                    value: settings.brightnessGesture,
                    onChanged: settings.setBrightnessGesture,
                    primaryColor: primaryColor,
                    theme: theme,
                  ),
                  _buildSwitchTile(
                    title: "Volume gesture",
                    value: settings.volumeGesture,
                    onChanged: settings.setVolumeGesture,
                    primaryColor: primaryColor,
                    theme: theme,
                  ),
                  _buildSwitchTile(
                    title: "Seek gesture",
                    value: settings.seekGesture,
                    onChanged: settings.setSeekGesture,
                    primaryColor: primaryColor,
                    theme: theme,
                  ),
                  _buildSectionHeader("Subtitles", primaryColor),
                  _buildSwitchTile(
                    title: "Show subtitles",
                    value: settings.showSubtitles,
                    onChanged: settings.setShowSubtitles,
                    primaryColor: primaryColor,
                    theme: theme,
                  ),
                  _buildSwitchTile(
                    title: "Auto-load subtitles",
                    value: settings.autoLoadSubtitles,
                    onChanged: settings.setAutoLoadSubtitles,
                    primaryColor: primaryColor,
                    theme: theme,
                  ),
                  _buildIntPickerTile(
                    context: context,
                    title: "Subtitle Size",
                    value: settings.subtitleSize.toInt(),
                    options: [12, 14, 16, 18, 20, 24, 28, 32],
                    suffix: "px",
                    onChanged: (val) =>
                        settings.setSubtitleSize(val.toDouble()),
                    primaryColor: primaryColor,
                    theme: theme,
                  ),
                  ListTile(
                    title: Text("Subtitle Color",
                        style: TextStyle(color: textPrimary)),
                    trailing: CircleAvatar(
                        backgroundColor: settings.subtitleColor, radius: 12),
                    onTap: () =>
                        _showColorPicker(context, settings, type: 'subtitle'),
                  ),
                  ListTile(
                    title: Text("Subtitle Background",
                        style: TextStyle(color: textPrimary)),
                    trailing: CircleAvatar(
                        backgroundColor: settings.subtitleBackgroundColor,
                        radius: 12),
                    onTap: () => _showColorPicker(context, settings,
                        type: 'subtitleBackground'),
                  ),
                  _buildSectionHeader("Library", primaryColor),
                  _buildSwitchTile(
                    title: "Show hidden files",
                    value: settings.showHiddenFiles,
                    onChanged: settings.setShowHiddenFiles,
                    primaryColor: primaryColor,
                    theme: theme,
                  ),
                  ListTile(
                    title: Text("Clear recent history",
                        style: TextStyle(color: textPrimary)),
                    leading: Icon(Icons.history_rounded, color: primaryColor),
                    onTap: () async {
                      final confirmed = await _showConfirmDialog(
                          context,
                          "Clear History",
                          "Are you sure you want to clear your playback history?");
                      if (confirmed) settings.clearRecentlyPlayed();
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildThemeTile(
      BuildContext context, AppSettingsProvider settings, Color primaryColor) {
    final textPrimary = ThemeHelper.textPrimary(settings.theme);
    final textSecondary = ThemeHelper.textSecondary(settings.theme);

    return ListTile(
      leading: Icon(Icons.palette_rounded, color: primaryColor),
      title: Text("Theme",
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
      subtitle: Text(settings.theme.name.toUpperCase(),
          style: TextStyle(color: textSecondary, fontSize: 12)),
      trailing:
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: primaryColor),
      onTap: () => _showThemePicker(context, settings),
    );
  }

  Widget _buildCustomColorTile(
      BuildContext context, AppSettingsProvider settings, Color primaryColor) {
    final textPrimary = ThemeHelper.textPrimary(settings.theme);

    return ListTile(
      leading: Icon(Icons.color_lens_rounded, color: primaryColor),
      title: Text("Custom Accent Color", style: TextStyle(color: textPrimary)),
      trailing:
          CircleAvatar(backgroundColor: settings.customPrimary, radius: 12),
      onTap: () => _showColorPicker(context, settings),
    );
  }

  Widget _buildSwitchTile(
      {required String title,
      required bool value,
      required Function(bool) onChanged,
      required Color primaryColor,
      required AppTheme theme}) {
    return SwitchListTile(
      title:
          Text(title, style: TextStyle(color: ThemeHelper.textPrimary(theme))),
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
    required AppTheme theme,
  }) {
    return ListTile(
      title:
          Text(title, style: TextStyle(color: ThemeHelper.textPrimary(theme))),
      subtitle: Text(subtitle ?? value.name.toUpperCase(),
          style:
              TextStyle(color: ThemeHelper.textSecondary(theme), fontSize: 12)),
      trailing:
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: primaryColor),
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
    required AppTheme theme,
    String suffix = "",
  }) {
    return ListTile(
      title:
          Text(title, style: TextStyle(color: ThemeHelper.textPrimary(theme))),
      subtitle: Text("$value$suffix",
          style:
              TextStyle(color: ThemeHelper.textSecondary(theme), fontSize: 12)),
      trailing:
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: primaryColor),
      onTap: () =>
          _showIntPicker(context, title, value, options, onChanged, suffix),
    );
  }

  // --- PICKERS ---

  void _showThemePicker(BuildContext context, AppSettingsProvider settings) {
    _showEnumPicker(context, "Select Theme", settings.theme, AppTheme.values,
        (val) {
      settings.setTheme(val);
      if (val == AppTheme.custom) _showColorPicker(context, settings);
    });
  }

  void _showSpeedPicker(
    BuildContext context,
    AppSettingsProvider settings,
  ) {
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Default playback speed',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: speeds.map((speed) {
                  return ChoiceChip(
                    label: Text('${speed}x'),
                    selected:
                        (settings.defaultPlaybackSpeed - speed).abs() < 0.01,
                    onSelected: (_) {
                      settings.setDefaultPlaybackSpeed(speed);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEnumPicker<T extends Enum>(BuildContext context, String title,
      T currentValue, List<T> options, Function(T) onChanged) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10))),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, i) => ListTile(
                title: Text(options[i].name.toUpperCase(),
                    style: TextStyle(
                        color: options[i] == currentValue
                            ? Colors.cyanAccent
                            : Colors.white)),
                trailing: options[i] == currentValue
                    ? const Icon(Icons.check_circle_rounded,
                        color: Colors.cyanAccent)
                    : null,
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

  void _showIntPicker(BuildContext context, String title, int currentValue,
      List<int> options, Function(int) onChanged, String suffix) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10))),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ),
          ...options
              .map((opt) => ListTile(
                    title: Text("$opt$suffix",
                        style: TextStyle(
                            color: opt == currentValue
                                ? Colors.cyanAccent
                                : Colors.white)),
                    trailing: opt == currentValue
                        ? const Icon(Icons.check_circle_rounded,
                            color: Colors.cyanAccent)
                        : null,
                    onTap: () {
                      onChanged(opt);
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showColorPicker(BuildContext context, AppSettingsProvider settings,
      {String type = 'accent'}) {
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.white,
      Colors.black,
      Colors.grey,
      Colors.cyanAccent,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(type == 'accent' ? "Accent Color" : "Pick Color",
            style: const TextStyle(color: Colors.white)),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors
              .map((color) => GestureDetector(
                    onTap: () {
                      if (type == 'accent') settings.setCustomColor(color);
                      if (type == 'subtitle') settings.setSubtitleColor(color);
                      if (type == 'subtitleBackground')
                        settings.setSubtitleBackgroundColor(color);
                      Navigator.pop(context);
                    },
                    child: CircleAvatar(backgroundColor: color, radius: 22),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Future<bool> _showConfirmDialog(
      BuildContext context, String title, String message) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: Text(title, style: const TextStyle(color: Colors.white)),
            content:
                Text(message, style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("CANCEL")),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("CLEAR",
                      style: TextStyle(color: Colors.redAccent))),
            ],
          ),
        ) ??
        false;
  }
}
