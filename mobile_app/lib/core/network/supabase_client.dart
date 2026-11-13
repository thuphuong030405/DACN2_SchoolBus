import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/supabase_constants.dart';

class SupabaseService {
  static Future<void> init() async {
    if (SupabaseConstants.url.isEmpty || SupabaseConstants.anonKey.isEmpty) {
      throw Exception('Thiếu SUPABASE_URL hoặc SUPABASE_ANON_KEY');
    }
    await Supabase.initialize(
      url: SupabaseConstants.url,
      anonKey: SupabaseConstants.anonKey,
    );
  }
}

/// Biến dùng chung toàn app
SupabaseClient get supabase => Supabase.instance.client;