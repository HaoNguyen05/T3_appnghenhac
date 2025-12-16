import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';

class PlayerService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  Song? _current;
  bool _playing = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  double volume = 1.0;

  PlayerService() {
    _player.playerStateStream.listen((state) {
      _playing = state.playing;
      notifyListeners();
    });

    _player.positionStream.listen((p) {
      position = p;
      notifyListeners();
    });

    _player.durationStream.listen((d) {
      duration = d ?? Duration.zero;
      notifyListeners();
    });
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _playing = false;
        position = duration;
        notifyListeners();
      }
    });
  }

  Song? get current => _current;
  bool get isPlayingNow => _playing;

  Future<void> play(Song s) async {
    try {
      if (s.audioUrl == null || s.audioUrl!.isEmpty) {
        if (kDebugMode) print('Invalid audio URL for song: ${s.title}');
        return;
      }

      if (_current?.id != s.id) {
        _current = s;
        await _player.setUrl(s.audioUrl!);
      }

      await _player.play();
      _playing = true;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Player play error: $e');
    }
  }

  Future<void> pause() async {
    await _player.pause();
    _playing = false;
    notifyListeners();
  }

  Future<void> playOrPause(Song s) async {
    if (_current?.id == s.id && _playing) {
      await pause();
    } else {
      await play(s);
    }
  }

  Future<void> seek(Duration pos) async {
    await _player.seek(pos);
  }

  Future<void> setVolume(double v) async {
    volume = v;
    await _player.setVolume(v);
    notifyListeners();
  }

  bool isPlaying(Song s) => _current?.id == s.id && _playing;

  Future<void> stop() async {
    await _player.stop();
    _playing = false;
    _current = null;
    position = Duration.zero;
    duration = Duration.zero;
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
