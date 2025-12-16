class SongHistory {
  final String id;
  final String userId;
  final String songId;
  final DateTime timestamp;

  SongHistory({
    required this.id,
    required this.userId,
    required this.songId,
    required this.timestamp,
  });

  factory SongHistory.fromMap(Map<String, dynamic> m) {
    return SongHistory(
      id: m['id'].toString(),
      userId: m['user_id'].toString(),
      songId: m['song_id'].toString(),
      timestamp: DateTime.parse(m['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'song_id': songId,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
