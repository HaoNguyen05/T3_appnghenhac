import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../services/player_service.dart';
import '../services/favorites_service.dart';
import '../services/auth_service.dart';

class PlayerScreen extends StatefulWidget {
  final Song song;
  const PlayerScreen({super.key, required this.song});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  double _volume = 1.0;

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerService>(context);
    final fav = Provider.of<FavoritesService>(context);
    final auth = Provider.of<AuthService>(context);
    final song = widget.song;
    final isPlaying = player.isPlaying(song);
    final isFavorite = fav.contains(song.id);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(song.title),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.white,
            ),
            onPressed: () async {
              final user = auth.user;
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng đăng nhập trước')),
                );
                return;
              }

              await fav.toggle(song.id);
              await fav.loadFavorites();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: song.coverUrl != null
                  ? Image.network(song.coverUrl!,
                      width: 280, height: 280, fit: BoxFit.cover)
                  : Container(width: 280, height: 280, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Text(song.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(song.artist ?? '',
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),

            // Thanh tiến trình
            Slider(
              activeColor: Colors.purpleAccent,
              thumbColor: Colors.purpleAccent,
              value: player.position.inSeconds
                  .toDouble()
                  .clamp(0, player.duration.inSeconds.toDouble()),
              max: (player.duration.inSeconds > 0)
                  ? player.duration.inSeconds.toDouble()
                  : 1.0,
              onChanged: (v) => player.seek(Duration(seconds: v.toInt())),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_format(player.position),
                        style: const TextStyle(color: Colors.white70)),
                    Text(_format(player.duration),
                        style: const TextStyle(color: Colors.white70)),
                  ]),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.volume_down, color: Colors.white, size: 20),
                  SizedBox(
                    width: 120,
                    child: Slider(
                      value: _volume,
                      min: 0,
                      max: 1,
                      activeColor: Colors.white,
                      inactiveColor: Colors.white30,
                      onChanged: (v) {
                        setState(() => _volume = v);
                        player.setVolume(v);
                      },
                    ),
                  ),
                  const Icon(Icons.volume_up, color: Colors.white, size: 18),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(
                  icon: const Icon(Icons.shuffle, color: Colors.white),
                  onPressed: () {}),
              IconButton(
                  icon: const Icon(Icons.skip_previous, color: Colors.white),
                  onPressed: () {}),
              Container(
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Colors.white),
                child: IconButton(
                  iconSize: 42,
                  onPressed: () => player.playOrPause(song),
                  icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.black),
                ),
              ),
              IconButton(
                  icon: const Icon(Icons.skip_next, color: Colors.white),
                  onPressed: () {}),
              IconButton(
                  icon: const Icon(Icons.repeat, color: Colors.white),
                  onPressed: () {}),
            ]),
          ],
        ),
      ),
    );
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
