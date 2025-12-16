import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/library_service.dart';
import '../services/player_service.dart';
import '../services/auth_service.dart';
import '../services/history_service.dart';
import '../widgets/song_tile.dart';
import '../widgets/mini_player.dart';
import '../screens/player_screen.dart';
import '../screens/search_screen.dart';
import '../screens/notifications_screen.dart';
import '../models/song.dart';
import '../services/notification_service.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;
  final searchCtrl = TextEditingController();
  bool _isDarkMode = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final lib = Provider.of<LibraryService>(context, listen: false);
      final auth = Provider.of<AuthService>(context, listen: false);
      final history = Provider.of<HistoryService>(context, listen: false);
      final notifService =
          Provider.of<NotificationService>(context, listen: false);

      await lib.fetchGenres();
      await lib.fetchSongs();
      await notifService.fetchNotifications();

      if (auth.userId != null) {
        history.setUser(auth.userId!);
        await history.loadHistory();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lib = Provider.of<LibraryService>(context);
    final player = Provider.of<PlayerService>(context);
    final history = Provider.of<HistoryService>(context);

    final bgColor = _isDarkMode ? const Color(0xFF121212) : Colors.white;
    final textColor = _isDarkMode ? Colors.white : Colors.black87;
    final subText = _isDarkMode ? Colors.white70 : Colors.black54;

    Widget homeContent = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    icon: Icon(_isDarkMode ? Icons.dark_mode : Icons.light_mode,
                        color: textColor),
                    onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
                  ),
                  const SizedBox(width: 8),
                  const CircleAvatar(
                    radius: 20,
                    backgroundImage:
                        NetworkImage('https://i.pravatar.cc/150?img=3'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (lib.songs.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bài hát được yêu thích',
                    style: TextStyle(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: lib.songs.length.clamp(0, 8),
                    itemBuilder: (_, i) {
                      final s = lib.songs[i];
                      return GestureDetector(
                        onTap: () {
                          history.addToHistory(s.id);
                          player.play(s);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => PlayerScreen(song: s)));
                        },
                        child: Container(
                          width: 180,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: _isDarkMode
                                ? const Color(0xFF181818)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8)
                            ],
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: s.coverUrl != null
                                    ? Image.network(s.coverUrl!,
                                        width: 180,
                                        height: 200,
                                        fit: BoxFit.cover)
                                    : Container(
                                        width: 180,
                                        height: 200,
                                        color: Colors.grey),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.7)
                                      ]),
                                ),
                              ),
                              Positioned(
                                bottom: 12,
                                left: 12,
                                right: 12,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14)),
                                    Text(s.artist ?? 'Unknown',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          if (lib.genres.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...lib.genres.map((genre) {
                  final genreSongs =
                      lib.songs.where((s) => s.genreId == genre.id).toList();
                  if (genreSongs.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(genre.name,
                          style: TextStyle(
                              color: textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ...genreSongs.map((s) => SongTile(
                            song: s,
                            isFavorite: false,
                            onTap: () async {
                              await player.play(s);
                              await history.addToHistory(s.id);
                              if (context.mounted)
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => PlayerScreen(song: s)));
                            },
                            onFavoriteTap: () {},
                          )),
                      const SizedBox(height: 28),
                    ],
                  );
                }).toList(),
              ],
            ),
        ],
      ),
    );

    final searchContent = SearchScreen(isDarkMode: _isDarkMode);
    final profileContent = const ProfileScreen();
    final notificationContent = const NotificationsScreen();
    final List<Widget> tabContents = [
      homeContent,
      searchContent,
      profileContent,
      notificationContent
    ];

    return Scaffold(
      backgroundColor: bgColor,
      body: tabContents[_currentTab],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          BottomNavigationBar(
            backgroundColor: bgColor,
            selectedItemColor: Colors.deepPurple,
            unselectedItemColor: subText,
            currentIndex: _currentTab,
            onTap: (idx) => setState(() => _currentTab = idx),
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
