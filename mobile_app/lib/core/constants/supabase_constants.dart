class SupabaseConstants {
  // Ưu tiên lấy từ --dart-define, nếu không có thì dùng giá trị mặc định (dev)
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://zimlasyxfrgtsmftadjy.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_pCeypEOyk1lPUwVrRfGSdA_wk-3gJ5S',
  );

  // Tên bảng
  static const String attendanceTable = 'attendance';
    static const String profilesTable = 'profiles';
}