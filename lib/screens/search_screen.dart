import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../services/library_service.dart';
import '../services/player_service.dart';
import '../services/history_service.dart';
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
    // final fav = Provider.of<FavoritesService>(context);
    final history = Provider.of<HistoryService>(context);

    final textColor = widget.isDarkMode ? Colors.white : Colors.black87;
    final subText = widget.isDarkMode ? Colors.white70 : Colors.black54;
    final cardBg =
        widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[200];

    // Lọc kết quả tìm kiếm
    List<Song> results = [];
    if (searchCtrl.text.isNotEmpty) {
      String query = searchCtrl.text.toLowerCase();
      results = lib.songs
          .where((s) =>
              s.title.toLowerCase().contains(query) ||
              (s.artist?.toLowerCase().contains(query) ?? false))
          .toList();
    } else {
      // Hiển thị bài hát phổ biến nếu không tìm kiếm
      results = lib.songs.take(20).toList();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề
          Text(
            'Tìm kiếm',
            style: TextStyle(
              color: textColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Search bar
          TextField(
            controller: searchCtrl,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: 'Tìm bài hát, nghệ sĩ, thể loại...',
              hintStyle: TextStyle(color: subText),
              prefixIcon: Icon(Icons.search, color: subText),
              suffixIcon: searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: subText),
                      onPressed: () => setState(() => searchCtrl.clear()),
                    )
                  : null,
              filled: true,
              fillColor: cardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),

          // Kết quả hoặc danh sách phổ biến
          if (searchCtrl.text.isEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bài hát phổ biến',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),

          if (results.isEmpty && searchCtrl.text.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'Không tìm thấy kết quả',
                  style: TextStyle(color: subText, fontSize: 16),
                ),
              ),
            )
          else
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: results.length,
              itemBuilder: (c, i) {
                final song = results[i];
                // final isFav = fav.contains(song.id);
                return SongTile(
                  song: song,
                  isFavorite: false,
                  onTap: () async {
                    await player.play(song);
                    await history.addToHistory(song.id);
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlayerScreen(song: song),
                        ),
                      );
                    }
                  },
                  onFavoriteTap: () {},
                );
              },
            ),
        ],
      ),
    );
  }
}
