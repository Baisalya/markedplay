import 'package:flutter/material.dart';
import 'package:markedplay/Pages/audio%20player/Audioplayer.dart';
import 'package:markedplay/Pages/videoplayer/Videoplayer.dart';
import 'package:markedplay/core/services/file_browser_service.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../core/app_settings_provider.dart';
import '../../core/media_enums.dart';
import '../../core/theme_helper.dart';
import '../../widgets/modern_widgets.dart';
import '../../core/ui/widgets/mini_player_aware_padding.dart';
import '../../core/ui/responsive/responsive_builder.dart';
import '../../core/services/thumbnail_service.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    final theme = settings.theme;
    final primaryColor =
        ThemeHelper.primary(theme, customColor: settings.customPrimary);
    final textPrimary = ThemeHelper.textPrimary(theme);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text("Tools",
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: primaryColor),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: ThemeHelper.backgroundGradient(theme,
                  customColor: settings.customPrimary),
            ),
          ),
          MiniPlayerAwarePadding(
            child: SafeArea(
              child: ResponsiveBuilder(
                compact: (context, constraints) =>
                    _buildToolsList(context, primaryColor, false, theme),
                medium: (context, constraints) =>
                    _buildToolsList(context, primaryColor, true, theme),
                expanded: (context, constraints) =>
                    _buildToolsList(context, primaryColor, true, theme),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsList(
      BuildContext context, Color primaryColor, bool isWide, AppTheme theme) {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: isWide ? 1000 : 600),
        child: GridView.count(
          padding: const EdgeInsets.all(20),
          crossAxisCount: isWide ? 2 : 1,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: isWide ? 2.5 : 3.5,
          children: [
            _buildToolCard(
              context,
              icon: Icons.file_open_rounded,
              title: "Open File",
              subtitle: "Pick a specific media file to play",
              color: Colors.blueAccent,
              theme: theme,
              onTap: () async {
                FilePickerResult? result =
                    await FilePicker.platform.pickFiles(type: FileType.media);
                if (result != null && result.files.single.path != null) {
                  final path = result.files.single.path!;
                  final browser = FileBrowserService();
                  if (!context.mounted) return;
                  if (browser.isVideoFile(path)) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                VideoPlayerScreen(playlist: [path])));
                  } else if (browser.isAudioFile(path)) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => AudioPlayerScreen(
                                filePath: path, startPosition: Duration.zero)));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('This file type is not supported.'),
                      ),
                    );
                  }
                }
              },
            ),
            _buildToolCard(
              context,
              icon: Icons.link_rounded,
              title: "Open URL",
              subtitle: "Stream from a network link",
              color: Colors.greenAccent,
              theme: theme,
              onTap: () => _showUrlDialog(context, primaryColor),
            ),
            _buildToolCard(
              context,
              icon: Icons.scanner_rounded,
              title: "Media Scanner",
              subtitle: "Force rescan for new media files",
              color: Colors.orangeAccent,
              theme: theme,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Return to the library and pull down to rescan media.",
                    ),
                  ),
                );
              },
            ),
            _buildToolCard(
              context,
              icon: Icons.cleaning_services_rounded,
              title: "Clear Cache",
              subtitle: "Remove temporary files and thumbnails",
              color: Colors.redAccent,
              theme: theme,
              onTap: () => _showClearCacheDialog(context),
            ),
            _buildToolCard(
              context,
              icon: Icons.info_outline_rounded,
              title: "App Diagnostics",
              subtitle: "View system and playback information",
              color: Colors.cyanAccent,
              theme: theme,
              onTap: () => _showDiagnostics(context, primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required Color color,
      required VoidCallback onTap,
      required AppTheme theme}) {
    final textPrimary = ThemeHelper.textPrimary(theme);
    final textSecondary = ThemeHelper.textSecondary(theme);

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        borderRadius: 20,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15)),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: TextStyle(color: textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: color.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }

  void _showUrlDialog(BuildContext context, Color primaryColor) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("Open Network Stream",
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter URL (http://...)",
            hintStyle: const TextStyle(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: primaryColor.withOpacity(0.3))),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: primaryColor)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL")),
          TextButton(
            onPressed: () {
              final uri = Uri.tryParse(controller.text.trim());
              if (uri == null ||
                  !(uri.isScheme('http') || uri.isScheme('https'))) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Enter a valid http or https URL.')),
                );
                return;
              }
              final value = uri.toString();
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VideoPlayerScreen(playlist: [value]),
                ),
              );
            },
            child: Text("PLAY", style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("Clear Cache", style: TextStyle(color: Colors.white)),
        content: const Text(
            "This will delete all generated thumbnails and temporary data. Proceed?",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL")),
          TextButton(
            onPressed: () async {
              await ThumbnailService().clearAll();
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thumbnail cache cleared.')),
              );
            },
            child:
                const Text("CLEAR", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showDiagnostics(BuildContext context, Color primaryColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Diagnostics",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _diagRow(
                "OS", kIsWeb ? 'WEB' : Platform.operatingSystem.toUpperCase()),
            _diagRow("Player Engine", "media_kit / just_audio"),
            _diagRow("Codec Support", "Depends on device and file"),
            const SizedBox(height: 20),
            const Text("Storage Info",
                style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
            _diagRow(
                "Library",
                !kIsWeb && Platform.isAndroid
                    ? "/storage/emulated/0"
                    : "File picker"),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _diagRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value,
              style: const TextStyle(
                  color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
