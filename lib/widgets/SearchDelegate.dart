import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'modern_widgets.dart';

class MediaSearchDelegate extends SearchDelegate {
  final List<SongModel> songs;
  final Function(String) onFileTap;

  MediaSearchDelegate({required this.songs, required this.onFileTap});

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildList();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildList();
  }

  Widget _buildList() {
    final results = songs.where((s) =>
        s.title.toLowerCase().contains(query.toLowerCase()) ||
        (s.artist?.toLowerCase().contains(query.toLowerCase()) ?? false)
    ).toList();

    if (results.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.search_off_rounded,
        title: "No songs found",
        subtitle: "Try a different search term.",
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        return SongTile(
          song: results[index],
          onTap: () {
            onFileTap(results[index].data);
            close(context, null);
          },
        );
      },
    );
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white54),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white),
      ),
    );
  }
}
