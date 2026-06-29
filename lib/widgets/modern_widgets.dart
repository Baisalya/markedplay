import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../core/app_settings_provider.dart';
import '../core/theme_helper.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color? color;
  final double blur;
  final Border? border;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 25,
    this.color,
    this.blur = 15,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: color ?? Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ??
                Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class ModernIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final double size;
  final double? iconSize;

  const ModernIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.size = 48,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: (color ?? Colors.white).withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        iconSize: iconSize,
        icon: Icon(icon, color: color ?? Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    final theme = settings.theme;
    final textPrimary = ThemeHelper.textPrimary(theme);
    final textSecondary = ThemeHelper.textSecondary(theme);

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: textPrimary.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 64, color: textSecondary),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              if (buttonText != null && onButtonPressed != null) ...[
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: onButtonPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: textPrimary.withOpacity(0.1),
                    foregroundColor: textPrimary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(buttonText!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class LoadingStateWidget extends StatelessWidget {
  final String label;

  const LoadingStateWidget({
    super.key,
    this.label = 'Loading your media…',
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    final accent = ThemeHelper.primary(
      settings.theme,
      customColor: settings.customPrimary,
    );

    return Center(
      child: Semantics(
        label: label,
        liveRegion: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: accent),
            const SizedBox(height: 16),
            Text(
              label,
              style: TextStyle(
                color: ThemeHelper.textSecondary(settings.theme),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  const ErrorStateWidget({
    super.key,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    final accent = ThemeHelper.primary(
      settings.theme,
      customColor: settings.customPrimary,
    );

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 64, color: accent),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ThemeHelper.textPrimary(settings.theme),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ThemeHelper.textSecondary(settings.theme),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(actionLabel),
              ),
              if (secondaryActionLabel != null &&
                  onSecondaryAction != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onSecondaryAction,
                  child: Text(secondaryActionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SongTile extends StatelessWidget {
  final SongModel song;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool isPlaying;

  const SongTile({
    super.key,
    required this.song,
    required this.onTap,
    this.trailing,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    final theme = settings.theme;
    final textPrimary = ThemeHelper.textPrimary(theme);
    final textSecondary = ThemeHelper.textSecondary(theme);

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: textPrimary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: QueryArtworkWidget(
          id: song.id,
          type: ArtworkType.AUDIO,
          nullArtworkWidget: Icon(
            Icons.music_note_rounded,
            color: isPlaying ? Colors.cyanAccent : textSecondary,
          ),
        ),
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isPlaying ? Colors.cyanAccent : textPrimary,
          fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        song.artist ?? "Unknown Artist",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: textSecondary, fontSize: 12),
      ),
      trailing: trailing,
    );
  }
}

class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;

  const ModernCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    final theme = settings.theme;
    final cardColor = color ?? ThemeHelper.cardColor(theme);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AlbumArt extends StatelessWidget {
  final int id;
  final ArtworkType type;
  final double borderRadius;
  final double? size;

  const AlbumArt({
    super.key,
    required this.id,
    this.type = ArtworkType.AUDIO,
    this.borderRadius = 15,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: QueryArtworkWidget(
        id: id,
        type: type,
        artworkWidth: size ?? 200,
        artworkHeight: size ?? 200,
        nullArtworkWidget: Container(
          width: size ?? 200,
          height: size ?? 200,
          color: Colors.white.withValues(alpha: 0.05),
          child: Icon(
            type == ArtworkType.AUDIO
                ? Icons.music_note_rounded
                : Icons.video_library_rounded,
            color: Colors.white24,
            size: size != null ? size! * 0.5 : 30,
          ),
        ),
      ),
    );
  }
}
