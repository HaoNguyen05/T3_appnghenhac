import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/library_service.dart';
import '../services/notification_service.dart'; // Thêm import
import '../models/song.dart';
import '../models/genre.dart';

class ManageSongsScreen extends StatefulWidget {
  const ManageSongsScreen({super.key});

  @override
  State<ManageSongsScreen> createState() => _ManageSongsScreenState();
}

class _ManageSongsScreenState extends State<ManageSongsScreen> {
  final _client = Supabase.instance.client;

  String? selectedAudio;

  Future<List<String>> _fetchMp3Files() async {
    final res = await _client.storage.from('audio').list(path: '');
    return res
        .where((e) => e.name.toLowerCase().endsWith('.mp3'))
        .map((e) => e.name)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final library = Provider.of<LibraryService>(context);
    final songs = library.songs;
    final genres = library.genres;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý bài hát'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showSongDialog(context, library, genres),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return ListTile(
            title: Text(song.title),
            subtitle: Text(song.artist ?? ''),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () =>
                      _showSongDialog(context, library, genres, song: song),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteSong(context, library, song.id),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSongDialog(
      BuildContext context, LibraryService library, List<Genre> genres,
      {Song? song}) {
    final titleCtrl = TextEditingController(text: song?.title ?? '');
    final artistCtrl = TextEditingController(text: song?.artist ?? '');
    String? selectedGenreId = song?.genreId;
    selectedAudio = null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(song == null ? 'Thêm bài hát' : 'Sửa bài hát'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Tiêu đề'),
              ),
              TextField(
                controller: artistCtrl,
                decoration: const InputDecoration(labelText: 'Tác giả'),
              ),
              DropdownButtonFormField<String>(
                initialValue: selectedGenreId,
                items: genres
                    .map((g) => DropdownMenuItem(
                          value: g.id,
                          child: Text(g.name),
                        ))
                    .toList(),
                onChanged: (v) => selectedGenreId = v,
                decoration: const InputDecoration(labelText: 'Thể loại'),
              ),
              const SizedBox(height: 16),
              if (song == null)
                FutureBuilder<List<String>>(
                  future: _fetchMp3Files(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text('Bucket audio chưa có file mp3');
                    }
                    return DropdownButtonFormField<String>(
                      initialValue: selectedAudio,
                      items: snapshot.data!
                          .map((f) => DropdownMenuItem(
                                value: f,
                                child: Text(f),
                              ))
                          .toList(),
                      onChanged: (v) => selectedAudio = v,
                      decoration: const InputDecoration(
                        labelText: 'File nhạc (.mp3)',
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              if (song == null && selectedAudio == null) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Vui lòng chọn file nhạc'),
                  ));
                }
                return;
              }

              final audioUrl = song == null
                  ? _client.storage.from('audio').getPublicUrl(selectedAudio!)
                  : song.audioUrl;

              final newSong = Song(
                id: song?.id ?? '',
                title: titleCtrl.text,
                artist: artistCtrl.text,
                genreId: selectedGenreId,
                audioUrl: audioUrl,
                coverUrl: song?.coverUrl,
              );

              if (song == null) {
                await library.addSong(newSong);

                if (mounted) {
                  final notifService = context.read<NotificationService>();
                  await notifService.sendNotification(
                    title: 'Bài hát mới: ${newSong.title}',
                    message: 'Tác giả: ${newSong.artist ?? 'Unknown'}',
                  );
                }
              } else {
                await library.updateSong(newSong);
              }

              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _deleteSong(
      BuildContext context, LibraryService library, String songId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bài hát'),
        content: const Text('Bạn có chắc muốn xóa bài hát này?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          TextButton(
              onPressed: () async {
                await library.deleteSong(songId);
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Xóa')),
        ],
      ),
    );
  }
}
