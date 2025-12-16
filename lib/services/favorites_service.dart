import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  String? _userId;
  final Set<String> _favoriteSongIds = {};

  void setUser(String? userId) async {
    if (_userId == userId) return;

    _userId = userId;
    _favoriteSongIds.clear();

    if (_userId != null) {
      await loadFavorites();
    }

    notifyListeners();
  }

  bool contains(String songId) => _favoriteSongIds.contains(songId);

  Future<void> loadFavorites() async {
    if (_userId == null) return;

    try {
      final res = await _supabase
          .from('user_favorites')
          .select('song_id')
          .eq('user_id', _userId!);

      _favoriteSongIds
        ..clear()
        ..addAll((res as List).map((e) => e['song_id'].toString()));

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('loadFavorites error: $e');
      }
    }
  }

  Future<void> toggle(String songId) async {
    if (_userId == null) return;

    try {
      if (contains(songId)) {
        await _supabase
            .from('user_favorites')
            .delete()
            .eq('user_id', _userId!)
            .eq('song_id', songId);

        _favoriteSongIds.remove(songId);
      } else {
        await _supabase.from('user_favorites').insert({
          'user_id': _userId!,
          'song_id': songId,
        });

        _favoriteSongIds.add(songId);
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('toggle favorite error: $e');
      }
    }
  }

  Future<List<String>> getFavoriteSongIds(String userId) async {
    try {
      final res = await _supabase
          .from('user_favorites')
          .select('song_id')
          .eq('user_id', userId);

      return (res as List).map((e) => e['song_id'].toString()).toList();
    } catch (e) {
      if (kDebugMode) {
        print('getFavoriteSongIds error: $e');
      }
      return [];
    }
  }
}
