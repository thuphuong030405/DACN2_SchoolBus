import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  StorageService._();
  static SupabaseClient get _db => Supabase.instance.client;

  static Future<String> uploadAvatar({
    required File file,
    required String folder, // 'parents' hoặc 'students'
    required String id,     // userId hoặc studentId
  }) async {
    final fileExt = file.path.split('.').last;
    final fileName = '$folder/$id/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    await _db.storage.from('avatars').upload(
          fileName,
          file,
          fileOptions: const FileOptions(upsert: true),
        );

    return _db.storage.from('avatars').getPublicUrl(fileName);
  }
}