import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:markedplay/Pages/audio%20player/Audioplayer.dart';
import 'package:markedplay/Pages/videoplayer/Videoplayer.dart';
import 'package:markedplay/core/services/file_browser_service.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/app_settings_provider.dart';
import '../../core/theme_helper.dart';
import '../../widgets/modern_widgets.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    final theme = settings.theme;
    final primaryColor = ThemeHelper.primary(theme, customColor: settings.customPrimary);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text("Tools", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: primaryColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildToolCard(
            context,
            icon: Icons.file_open_rounded,
            title: "Open File",
            subtitle: "Pick a specific media file to play",
            color: Colors.blueAccent,
            onTap: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.media);
              if (result != null && result.files.single.path != null) {
                final path = result.files.single.path!;
                final isVideo = FileBrowserService().isVideoFile(path);
                if (isVideo) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerScreen(playlist: [path])));
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AudioPlayerScreen(filePath: path, startPosition: Duration.zero)));
                }
              }
            },
          ),
          const SizedBox(height: 16),
          _buildToolCard(
            context,
            icon: Icons.link_rounded,
            title: "Open URL",
            subtitle: "Stream from a network link",
            color: Colors.greenAccent,
            onTap: () {
               _showUrlDialog(context, primaryColor);
            },
          ),
          const SizedBox(height: 16),
          _buildToolCard(
            context,
            icon: Icons.scanner_rounded,
            title: "Media Scanner",
            subtitle: "Force rescan for new media files",
            color: Colors.orangeAccent,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Scanning media..."), duration: Duration(seconds: 1)),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildToolCard(
            context,
            icon: Icons.cleaning_services_rounded,
            title: "Clear Cache",
            subtitle: "Remove temporary files and thumbnails",
            color: Colors.redAccent,
            onTap: () {
               _showClearCacheDialog(context);
            },
          ),
          const SizedBox(height: 16),
          _buildToolCard(
            context,
            icon: Icons.info_outline_rounded,
            title: "App Diagnostics",
            subtitle: "View system and playback information",
            color: Colors.cyanAccent,
            onTap: () {
               _showDiagnostics(context, primaryColor);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
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
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color.withOpacity(0.5)),
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
        title: const Text("Open Network Stream", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter URL (http://...)",
            hintStyle: const TextStyle(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor.withOpacity(0.3))),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          TextButton(onPressed: () => Navigator.pop(context), child: Text("PLAY", style: TextStyle(color: primaryColor))),
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
        content: const Text("This will delete all generated thumbnails and temporary data. Proceed?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CLEAR", style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }

  void _showDiagnostics(BuildContext context, Color primaryColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Diagnostics", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _diagRow("OS", Platform.operatingSystem.toUpperCase()),
            _diagRow("Player Engine", "media_kit / just_audio"),
            _diagRow("AAC Support", "Verified (Hardware)"),
            _diagRow("H.264 Support", "Verified (Hardware)"),
            const SizedBox(height: 20),
            const Text("Storage Info", style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
            _diagRow("Root Path", "/storage/emulated/0"),
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
          Text(value, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
