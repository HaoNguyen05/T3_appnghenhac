import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_service.dart';
import '../screens/player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerService>(context);
    final song = player.current;
    if (song == null) return const SizedBox.shrink();

    return Material(
      elevation: 6,
      color: Colors.black,
      child: InkWell(
        onTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => PlayerScreen(song: song)));
        },
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: song.coverUrl != null
                    ? Image.network(song.coverUrl!,
                        width: 56, height: 56, fit: BoxFit.cover)
                    : Container(width: 56, height: 56, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(song.title,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(song.artist ?? '',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(player.isPlayingNow ? Icons.pause : Icons.play_arrow,
                    color: Colors.white),
                onPressed: () {
                  if (player.isPlayingNow) {
                    player.pause();
                  } else {
                    player.play(song);
                  }
                },
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}
