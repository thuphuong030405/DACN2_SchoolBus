import 'package:supabase_flutter/supabase_flutter.dart';

/// Nguồn DUY NHẤT để lấy "chuyến đang chạy" của giáo viên đang đăng nhập.
/// Trang chủ, tab Điểm danh và nút camera đều dùng hàm này nên luôn khớp nhau.
class ActiveTripQuery {
  static Future<Map<String, dynamic>?> forCurrentTeacher(
    SupabaseClient client, {
    String columns =
        'trip_id, status, trip_type, routes(route_name), buses(license_plate)',
  }) async {
    final uid = client.auth.currentUser?.id;
    if (uid == null) return null;

    // Trả về null nếu giáo viên chưa được phân công chuyến
    // hoặc có chuyến nhưng chưa bấm "Bắt đầu chuyến".
    return client
        .from('trips')
        .select('$columns, teachers!inner(user_id)')
        .eq('status', 'IN_PROGRESS')
        .eq('teachers.user_id', uid)
        .order('start_at')
        .limit(1)
        .maybeSingle();
  }
}