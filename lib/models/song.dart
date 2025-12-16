class Song {
  final String id;
  final String title;
  final String? artist;
  final String? genreId;
  final String? audioUrl;
  final String? coverUrl;
  bool favorite;

  Song({
    required this.id,
    required this.title,
    this.artist,
    this.genreId,
    this.audioUrl,
    this.coverUrl,
    this.favorite = false,
  });

  factory Song.fromMap(Map<String, dynamic> m) {
    return Song(
      id: m['id'].toString(),
      title: m['title']?.toString() ?? '',
      artist: m['artist']?.toString(),
      genreId: m['genre_id']?.toString(),
      audioUrl: m['audio_url']?.toString(),
      coverUrl: m['cover_url']?.toString(),
      favorite: m['favorite'] == true,
    );
  }
}
