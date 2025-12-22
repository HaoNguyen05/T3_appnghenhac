import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/library_service.dart';
import '../services/favorites_service.dart';
import '../services/history_service.dart';
import '../models/song.dart';
import '../widgets/song_tile.dart';
import 'player_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late AuthService auth;
  late FavoritesService fav;
  late LibraryService lib;
  late HistoryService hist;

  List<Song> favoriteSongs = [];
  List<Song> historySongs = [];
  bool loading = false;
  bool showFavorites = false;

  @override
  void initState() {
    super.initState();

    auth = Provider.of<AuthService>(context, listen: false);
    fav = Provider.of<FavoritesService>(context, listen: false);
    lib = Provider.of<LibraryService>(context, listen: false);
    hist = Provider.of<HistoryService>(context, listen: false);

    final user = auth.user;
    if (user != null) {
      fav.setUser(user.id);
      hist.setUser(user.id);

      _loadAllData();
    }
  }

  Future<void> _loadAllData() async {
    setState(() => loading = true);

    await lib.fetchSongs();
    await hist.loadHistory();

    if (!mounted) return;

    final historySongIds = hist.history.map((h) => h.songId).toSet();
    final user = auth.user!;
    final favIds = await fav.getFavoriteSongIds(user.id);

    setState(() {
      historySongs =
          lib.songs.where((s) => historySongIds.contains(s.id)).toList();
      favoriteSongs = lib.songs.where((s) => favIds.contains(s.id)).toList();
      loading = false;
    });
  }

  Future<void> refreshFavorites() async {
    if (auth.user == null) return;
    final favIds = await fav.getFavoriteSongIds(auth.user!.id);
    setState(() {
      favoriteSongs = lib.songs.where((s) => favIds.contains(s.id)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = auth.user;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Tài khoản'),
        backgroundColor: Colors.black,
      ),
      body: user == null
          ? const Center(
              child:
                  Text('Chưa đăng nhập', style: TextStyle(color: Colors.white)))
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email: ${user.email}',
                      style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('ID: ${user.id}',
                      style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),

                  // Bài hát nghe gần đây
                  const Text(
                    'Bài hát nghe gần đây',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 180,
                    child: loading
                        ? const Center(child: CircularProgressIndicator())
                        : historySongs.isEmpty
                            ? const Center(
                                child: Text('Chưa có lịch sử nghe',
                                    style: TextStyle(color: Colors.white)))
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: historySongs.length,
                                itemBuilder: (context, index) {
                                  final song = historySongs[index];
                                  return _buildSongCard(song);
                                },
                              ),
                  ),
                  const SizedBox(height: 16),

                  // Nút quản lý bài hát
                  ElevatedButton.icon(
                    icon: const Icon(Icons.library_music, color: Colors.green),
                    label: const Text('Quản lý bài hát'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white10,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () =>
                        Navigator.pushNamed(context, '/manage_songs'),
                  ),
                  const SizedBox(height: 16),

                  // Nút xem bài hát yêu thích
                  ElevatedButton.icon(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    label: const Text('Xem bài yêu thích'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white10,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      if (!showFavorites) await refreshFavorites();
                      setState(() => showFavorites = !showFavorites);
                    },
                  ),

                  if (showFavorites)
                    Expanded(
                      child: loading
                          ? const Center(child: CircularProgressIndicator())
                          : favoriteSongs.isEmpty
                              ? const Center(
                                  child: Text('Không có bài yêu thích',
                                      style: TextStyle(color: Colors.white)))
                              : ListView.builder(
                                  itemCount: favoriteSongs.length,
                                  itemBuilder: (c, i) {
                                    final s = favoriteSongs[i];
                                    return SongTile(
                                      song: s,
                                      isFavorite: true,
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PlayerScreen(song: s),
                                        ),
                                      ),
                                      onFavoriteTap: () async {
                                        await fav.toggle(s.id);
                                        await refreshFavorites();
                                      },
                                    );
                                  },
                                ),
                    ),
                ],
              ),
            ),
      floatingActionButton: user != null
          ? FloatingActionButton(
              onPressed: () async {
                await auth.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              child: const Icon(Icons.logout),
            )
          : null,
    );
  }

  Widget _buildSongCard(Song song) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PlayerScreen(song: song)),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: song.coverUrl != null
                  ? Image.network(
                      song.coverUrl!,
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 140,
                      height: 140,
                      color: Colors.grey,
                      child: const Icon(
                        Icons.music_note,
                        color: Colors.white,
                      ),
                    ),
            ),
            const SizedBox(height: 4),
            Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            Text(
              song.artist ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
