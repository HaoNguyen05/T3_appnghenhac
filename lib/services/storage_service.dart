import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final _client = Supabase.instance.client;

  Future<String> uploadFile({
    required File file,
    required String bucket,
    required String path,
  }) async {
    final bytes = await file.readAsBytes();

    await _client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: _getContentType(path),
          ),
        );

    return _client.storage.from(bucket).getPublicUrl(path);
  }

  String _getContentType(String path) {
    if (path.endsWith('.mp3')) return 'audio/mpeg';
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return 'image/jpeg';
    if (path.endsWith('.png')) return 'image/png';
    return 'application/octet-stream';
  }
}
