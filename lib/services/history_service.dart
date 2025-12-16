import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/song_history.dart';

class HistoryService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  String? _userId;
  List<SongHistory> _history = [];

  void setUser(String? userId) {
    if (_userId == userId) return;

    _userId = userId;
    _history.clear();

    if (_userId != null) {
      loadHistory();
    }

    notifyListeners();
  }

  List<SongHistory> get history => _history;

  Future<void> loadHistory() async {
    if (_userId == null) return;

    try {
      final res = await _supabase
          .from('listening_history')
          .select()
          .eq('user_id', _userId!)
          .order('timestamp', ascending: false)
          .limit(100);

      _history = (res as List)
          .map((e) => SongHistory.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('loadHistory error: $e');
      }
    }
  }

  Future<void> addToHistory(String songId) async {
    if (_userId == null) return;

    try {
      final newHistory = {
        'user_id': _userId!,
        'song_id': songId,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final res = await _supabase
          .from('listening_history')
          .insert(newHistory)
          .select()
          .single();

      final historyItem = SongHistory.fromMap(res);
      _history.insert(0, historyItem);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('addToHistory error: $e');
      }
    }
  }
}
