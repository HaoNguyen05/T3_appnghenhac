import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/library_service.dart';
import '../services/notification_service.dart';
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
  String? selectedImageFile;

  // Lấy danh sách file nhạc trong bucket "audio"
  Future<List<String>> _fetchMp3Files() async {
    try {
      final allFiles = await _client.storage.from('audio').list(path: '');
      final mp3Files = allFiles
          .where((f) => f.name.toLowerCase().endsWith('.mp3'))
          .map((f) => f.name)
          .toList();
      return mp3Files;
    } catch (e) {
      return [];
    }
  }

  // Lấy danh sách file ảnh trong bucket "image"
  Future<List<String>> _fetchImageFiles() async {
    try {
      final allFiles = await _client.storage.from('image').list(path: '');
      final imageFiles = allFiles
          .where((f) =>
              f.name.toLowerCase().endsWith('.jpg') ||
              f.name.toLowerCase().endsWith('.png') ||
              f.name.toLowerCase().endsWith('.jpeg'))
          .map((f) => f.name)
          .toList();
      return imageFiles;
    } catch (e) {
      return [];
    }
  }

  // Hàm trích xuất path file từ public URL
  String? _extractFilePathFromUrl(String url, String bucket) {
    final prefix = '/storage/v1/object/public/$bucket/';
    final index = url.indexOf(prefix);
    if (index != -1) {
      return url.substring(index + prefix.length);
    }
    return null;
  }

  // Hàm kiểm tra nếu URL là từ Supabase
  bool _isSupabaseUrl(String url) {
    return url.contains('/storage/v1/object/public/');
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
            leading: song.coverUrl != null
                ? CircleAvatar(
                    backgroundImage: NetworkImage(song.coverUrl!),
                    radius: 20,
                  )
                : const Icon(Icons.music_note),
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
    final imageUrlCtrl = TextEditingController();
    String? selectedGenreId = song?.genreId;
    selectedAudio = null;
    selectedImageFile = null;

    // Kiểm tra nếu coverUrl là URL bên ngoài
    if (song?.coverUrl != null && !_isSupabaseUrl(song!.coverUrl!)) {
      imageUrlCtrl.text = song.coverUrl!;
    } else {
      selectedImageFile = song?.coverUrl != null
          ? _extractFilePathFromUrl(song!.coverUrl!, 'image')
          : null;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
                  onChanged: (v) => setState(() => selectedGenreId = v),
                  decoration: const InputDecoration(labelText: 'Thể loại'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: imageUrlCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Link ảnh bìa (URL)'),
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 16),
                if (imageUrlCtrl.text.isNotEmpty)
                  Column(
                    children: [
                      const Text('Ảnh bìa từ URL:'),
                      Image.network(imageUrlCtrl.text,
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Text('Không thể tải ảnh')),
                      const SizedBox(height: 8),
                    ],
                  )
                else if (song != null &&
                    song.coverUrl != null &&
                    _isSupabaseUrl(song.coverUrl!))
                  Column(
                    children: [
                      const Text('Ảnh bìa hiện tại:'),
                      Image.network(song.coverUrl!,
                          height: 100, width: 100, fit: BoxFit.cover),
                      const SizedBox(height: 8),
                    ],
                  ),
                FutureBuilder<List<String>>(
                  future: _fetchImageFiles(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text(
                          'Bucket image chưa có file ảnh (hoặc dán URL ở trên)');
                    }
                    return DropdownButtonFormField<String>(
                      initialValue: selectedImageFile,
                      items: snapshot.data!
                          .map((f) => DropdownMenuItem(
                                value: f,
                                child: Text(f),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => selectedImageFile = v),
                      decoration: const InputDecoration(
                        labelText: 'File ảnh bìa từ bucket (.jpg, .png, .jpeg)',
                      ),
                    );
                  },
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
                        onChanged: (v) => setState(() => selectedAudio = v),
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

                // URL nhạc
                final audioUrl = song == null
                    ? _client.storage.from('audio').getPublicUrl(selectedAudio!)
                    : song.audioUrl;

                // URL cover
                String? coverUrl;
                if (imageUrlCtrl.text.isNotEmpty) {
                  coverUrl = imageUrlCtrl.text;
                } else if (selectedImageFile != null) {
                  coverUrl = _client.storage
                      .from('image')
                      .getPublicUrl(selectedImageFile!);
                }

                final newSong = Song(
                  id: song?.id ?? '',
                  title: titleCtrl.text,
                  artist: artistCtrl.text,
                  genreId: selectedGenreId,
                  audioUrl: audioUrl,
                  coverUrl: coverUrl,
                );

                if (song == null) {
                  await library.addSong(newSong);

                  if (!context.mounted) return;

                  final notifService = context.read<NotificationService>();
                  await notifService.sendNotification(
                    title: 'Bài hát mới: ${newSong.title}',
                    message: 'Tác giả: ${newSong.artist ?? 'Unknown'}',
                  );

                  if (!context.mounted) return;
                  Navigator.pop(context);
                } else {
                  await library.updateSong(newSong);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
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
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: const Text('Xóa')),
        ],
      ),
    );
  }
}
