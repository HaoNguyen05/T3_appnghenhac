import 'package:flutter/material.dart';
import '../models/song.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;
  final bool isFavorite;

  const SongTile({
    super.key,
    required this.song,
    required this.onTap,
    required this.onFavoriteTap,
    required this.isFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: song.coverUrl != null && song.coverUrl!.isNotEmpty
            ? Image.network(song.coverUrl!,
                width: 60, height: 60, fit: BoxFit.cover)
            : Container(width: 60, height: 60, color: Colors.grey),
      ),
      title: Text(song.title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(song.artist ?? '',
          style: const TextStyle(color: Colors.white70)),
      trailing: IconButton(
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: Colors.redAccent,
        ),
        onPressed: onFavoriteTap,
      ),
      onTap: onTap,
    );
  }
}
