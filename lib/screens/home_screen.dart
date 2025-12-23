import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/library_service.dart';
import '../services/player_service.dart';
import '../services/auth_service.dart';
import '../services/history_service.dart';
import '../services/favorites_service.dart';
import '../widgets/song_tile.dart';
import '../widgets/mini_player.dart';
import '../screens/player_screen.dart';
import '../screens/search_screen.dart';
import '../screens/notifications_screen.dart';
import '../services/notification_service.dart';
import 'profile_screen.dart';
import 'profile_info_screen.dart';
import '../models/user_profile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;
  bool _isDarkMode = true;
  UserProfile? _userProfile;
  late AuthService auth;

  @override
  void initState() {
    super.initState();
    auth = context.read<AuthService>();
    auth.addListener(_onAuthChanged);

    Future.microtask(() async {
      if (!mounted) return;

      final lib = context.read<LibraryService>();
      final history = context.read<HistoryService>();
      final fav = context.read<FavoritesService>();
      final notif = context.read<NotificationService>();

      await lib.fetchGenres();
      await lib.fetchSongs();
      await notif.fetchNotifications();

      if (auth.userId != null) {
        history.setUser(auth.userId!);
        await history.loadHistory();

        fav.setUser(auth.userId!);
        await fav.loadFavorites();

        _userProfile = await auth.getUserProfileAsModel();
        if (mounted) setState(() {});
      }
    });
  }

  void _onAuthChanged() {
    setState(() => _userProfile = auth.userProfile);
  }

  @override
  void dispose() {
    auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lib = context.watch<LibraryService>();
    final player = context.watch<PlayerService>();
    final history = context.watch<HistoryService>();
    final fav = context.watch<FavoritesService>();

    final bgColor = _isDarkMode ? const Color(0xFF121212) : Colors.white;
    final textColor = _isDarkMode ? Colors.white : Colors.black87;
    final subText = _isDarkMode ? Colors.white70 : Colors.black54;

    Widget homeContent = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Xin chào!',
                      style: TextStyle(
                          color: textColor,
                          fontSize: 28,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Khám phá nhạc của bạn',
                      style: TextStyle(color: subText, fontSize: 14)),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: textColor,
                    ),
                    onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProfileInfoScreen()),
                      );
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage: _userProfile?.avatarUrl != null
                          ? NetworkImage(_userProfile!.avatarUrl!)
                          : const NetworkImage(
                              'https://i.pravatar.cc/150?img=3'),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          /// 🔥 BÀI HÁT PHỔ BIẾN (KHÔNG BỊ MẤT)
          if (lib.songs.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bài hát phổ biến',
                  style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: lib.songs.length.clamp(0, 8),
                    itemBuilder: (_, i) {
                      final s = lib.songs[i];
                      final isFav = fav.contains(s.id);

                      return Container(
                        width: 180,
                        margin: const EdgeInsets.only(right: 16),
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                await history.addToHistory(s.id);
                                await player.play(s);
                                if (context.mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PlayerScreen(song: s),
                                    ),
                                  );
                                }
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: s.coverUrl != null
                                    ? Image.network(
                                        s.coverUrl!,
                                        width: 180,
                                        height: 200,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: 180,
                                        height: 200,
                                        color: Colors.grey,
                                      ),
                              ),
                            ),

                            /// ❤️ TIM
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: Icon(
                                  isFav
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isFav ? Colors.red : Colors.white,
                                ),
                                onPressed: () async {
                                  await fav.toggle(s.id);
                                },
                              ),
                            ),

                            Positioned(
                              bottom: 12,
                              left: 12,
                              right: 12,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    s.artist ?? '',
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),

          /// 🎼 THEO THỂ LOẠI
          if (lib.genres.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...lib.genres.map((genre) {
                  final songs =
                      lib.songs.where((s) => s.genreId == genre.id).toList();
                  if (songs.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        genre.name,
                        style: TextStyle(
                            color: textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ...songs.map(
                        (s) => SongTile(
                          song: s,
                          isFavorite: fav.contains(s.id),
                          onTap: () async {
                            await player.play(s);
                            await history.addToHistory(s.id);
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => PlayerScreen(song: s)),
                              );
                            }
                          },
                          onFavoriteTap: () async {
                            await fav.toggle(s.id);
                          },
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                  );
                }),
              ],
            ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: bgColor,
      body: [
        homeContent,
        SearchScreen(isDarkMode: _isDarkMode),
        const ProfileScreen(),
        const NotificationsScreen(),
      ][_currentTab],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          BottomNavigationBar(
            backgroundColor: bgColor,
            selectedItemColor: Colors.deepPurple,
            unselectedItemColor: subText,
            currentIndex: _currentTab,
            onTap: (i) => setState(() => _currentTab = i),
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home), label: 'Trang chủ'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.search), label: 'Tìm kiếm'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person), label: 'Tài khoản'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.notifications), label: 'Thông báo'),
            ],
          ),
        ],
      ),
    );
  }
}
