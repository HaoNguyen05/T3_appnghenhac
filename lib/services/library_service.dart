import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/song.dart';
import '../models/genre.dart';

class LibraryService extends ChangeNotifier {
  final _client = Supabase.instance.client;

  List<Song> songs = [];
  List<Genre> genres = [];

  Future<void> fetchGenres() async {
    try {
      final res =
          await _client.from('genres').select().order('name', ascending: true);
      genres = (res as List)
          .map((e) => Genre.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('fetchGenres error: $e');
      rethrow;
    }
  }

  Future<void> fetchSongs({String? genreId}) async {
    try {
      var query = _client.from('songs').select();
      if (genreId != null && genreId.isNotEmpty) {
        query = query.eq('genre_id', genreId);
      }
      final res = await query.order('title').limit(1000);
      songs = (res as List)
          .map((e) => Song.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('fetchSongs error: $e');
      rethrow;
    }
  }

  Future<void> addSong(Song song) async {
    try {
      final res = await _client.from('songs').insert({
        'title': song.title,
        'artist': song.artist,
        'genre_id': song.genreId,
        'audio_url': song.audioUrl,
        'cover_url': song.coverUrl,
      }).select();
      if ((res as List).isNotEmpty) {
        songs.add(Song.fromMap(Map<String, dynamic>.from(res.first)));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('addSong error: $e');
      rethrow;
    }
  }

  Future<void> updateSong(Song song) async {
    try {
      await _client.from('songs').update({
        'title': song.title,
        'artist': song.artist,
        'genre_id': song.genreId,
        'cover_url': song.coverUrl,
      }).eq('id', song.id);
      await fetchSongs();
    } catch (e) {
      debugPrint('updateSong error: $e');
      rethrow;
    }
  }

  Future<void> deleteSong(String songId) async {
    try {
      await _client.from('songs').delete().eq('id', songId);
      await fetchSongs();
    } catch (e) {
      debugPrint('deleteSong error: $e');
      rethrow;
    }
  }
}
