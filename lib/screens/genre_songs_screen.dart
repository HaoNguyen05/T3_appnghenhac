import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/library_service.dart';
import '../services/player_service.dart';
import '../models/song.dart';
import 'player_screen.dart';

class GenreSongsScreen extends StatefulWidget {
  final String genreId;
  final String genreName;
  const GenreSongsScreen(
      {super.key, required this.genreId, required this.genreName});

  @override
  State<GenreSongsScreen> createState() => _GenreSongsScreenState();
}

class _GenreSongsScreenState extends State<GenreSongsScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<LibraryService>(context, listen: false)
        .fetchSongs(genreId: widget.genreId);
  }

  @override
  Widget build(BuildContext context) {
    final library = Provider.of<LibraryService>(context);
    final player = Provider.of<PlayerService>(context);
    final songs = library.songs;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text(widget.genreName)),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: songs.length,
        itemBuilder: (_, i) {
          Song s = songs[i];
          return Card(
            color: Colors.grey.shade900,
            child: ListTile(
              title: Text(s.title, style: const TextStyle(color: Colors.white)),
              subtitle: Text(s.artist ?? '',
                  style: const TextStyle(color: Colors.white70)),
              trailing: IconButton(
                icon: Icon(player.isPlaying(s) ? Icons.pause : Icons.play_arrow,
                    color: Colors.white),
                onPressed: () => player.playOrPause(s),
              ),
              onTap: () {
                player.play(s);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => PlayerScreen(song: s)));
              },
            ),
          );
        },
      ),
    );
  }
}
