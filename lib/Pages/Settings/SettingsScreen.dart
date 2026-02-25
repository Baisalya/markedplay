import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_settings_provider.dart';
import '../../core/media_enums.dart';
import '../../core/theme_helper.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    final theme = settings.theme;

    final primaryColor = ThemeHelper.primary(
      theme,
      customColor: settings.customPrimary,
    );

    final backgroundColor = ThemeHelper.background(
      theme,
      customColor: settings.customPrimary,
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Settings",
          style: TextStyle(color: primaryColor),
        ),
        iconTheme: IconThemeData(color: primaryColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          const SizedBox(height: 20),

          // ================= THEME TILE =================

          ListTile(
            leading: Icon(Icons.color_lens, color: primaryColor),
            title: Text(
              "Theme",
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              settings.theme.name.toUpperCase(),
              style: TextStyle(
                color: primaryColor.withOpacity(0.7),
              ),
            ),
            trailing: Icon(Icons.arrow_forward_ios,
                size: 16,
                color: primaryColor),
            onTap: () {
              _showThemePicker(context, settings);
            },
          ),

          // ================= CUSTOM COLOR TILE =================

          if (settings.theme == AppTheme.custom)
            ListTile(
              leading: Icon(Icons.palette,
                  color: primaryColor),
              title: Text(
                "Custom Color",
                style: TextStyle(
                  color: ThemeHelper.textPrimary(theme),
                ),
              ),
              trailing: CircleAvatar(
                backgroundColor: settings.customPrimary,
              ),
              onTap: () {
                _showColorPicker(context, settings);
              },
            ),
        ],
      ),
    );
  }

  // ================= THEME PICKER =================

  void _showThemePicker(
      BuildContext context,
      AppSettingsProvider settings,
      ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: AppTheme.values.map((theme) {
              return RadioListTile<AppTheme>(
                value: theme,
                groupValue: settings.theme,
                activeColor: settings.customPrimary,
                title: const Text(
                  "",
                ),
                subtitle: Text(
                  theme.name.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white),
                ),
                onChanged: (value) {
                  if (value != null) {

                    Navigator.pop(sheetContext);

                    Future.microtask(() {
                      settings.setTheme(value);

                      if (value == AppTheme.custom) {
                        _showColorPicker(context, settings);
                      }
                    });
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ================= COLOR PICKER =================

  void _showColorPicker(
      BuildContext context,
      AppSettingsProvider settings,
      ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text(
            "Choose Color",
            style: TextStyle(color: Colors.white),
          ),
          content: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              Colors.blue,
              Colors.purple,
              Colors.red,
              Colors.green,
              Colors.orange,
              Colors.teal,
              Colors.pink,
              Colors.amber,
            ].map((color) {
              return GestureDetector(
                onTap: () {

                  Navigator.pop(dialogContext);

                  Future.microtask(() {
                    settings.setCustomColor(color);
                  });
                },
                child: CircleAvatar(
                  backgroundColor: color,
                  radius: 22,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}