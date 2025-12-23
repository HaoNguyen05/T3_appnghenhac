import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../services/library_service.dart';
import '../services/player_service.dart';
import '../services/history_service.dart';
import '../services/favorites_service.dart';
import '../widgets/song_tile.dart';
import 'player_screen.dart';

class SearchScreen extends StatefulWidget {
  final bool isDarkMode;
  const SearchScreen({super.key, required this.isDarkMode});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final searchCtrl = TextEditingController();

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lib = Provider.of<LibraryService>(context);
    final player = Provider.of<PlayerService>(context);
    final history = Provider.of<HistoryService>(context);
    final fav = Provider.of<FavoritesService>(context);

    if (lib.songs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    List<Song> results;
    if (searchCtrl.text.isNotEmpty) {
      final q = searchCtrl.text.toLowerCase();
      results = lib.songs
          .where((s) =>
              s.title.toLowerCase().contains(q) ||
              (s.artist?.toLowerCase().contains(q) ?? false))
          .toList();
    } else {
      results = lib.songs.take(20).toList();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tìm kiếm',
              style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : Colors.black,
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Tìm bài hát, nghệ sĩ...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: results.length,
            itemBuilder: (_, i) {
              final song = results[i];
              final isFav = fav.contains(song.id);

              return SongTile(
                song: song,
                isFavorite: isFav,
                onTap: () async {
                  await player.play(song);
                  await history.addToHistory(song.id);
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => PlayerScreen(song: song)),
                    );
                  }
                },
                onFavoriteTap: () async {
                  await fav.toggle(song.id);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
