import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final SupabaseClient _client;

  NotificationRepository(this._client);

  // Chỉ lấy các cột cần dùng (không lấy fcm_token)
  static const _columns = 'notification_id, title, message, notification_type, '
      'is_read, created_at, related_trip_id, related_student_id';

  /// Lấy 1 lần (giữ lại để code cũ còn dùng được)
  Future<List<AppNotification>> getNotifications(String userId) async {
    final response = await _client
        .from('notifications')
        .select(_columns)
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(100);

    return (response as List)
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Theo dõi realtime: có thông báo mới / đổi trạng thái đã đọc là danh sách tự cập nhật.
  /// (Cần bảng notifications nằm trong publication supabase_realtime - xem 013_notifications.sql)
  Stream<List<AppNotification>> watchNotifications(String userId) {
    return _client
        .from('notifications')
        .stream(primaryKey: ['notification_id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(100)
        .map((rows) => rows.map(AppNotification.fromJson).toList());
  }

  /// Đánh dấu 1 thông báo là đã đọc.
  /// Dùng giờ UTC (.toUtc()): nếu gửi giờ máy không kèm múi giờ, DB hiểu là UTC và lệch 7 tiếng.
  Future<void> markAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({
          'is_read': true,
          'read_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('notification_id', notificationId)
        .eq('is_read', false);
  }

  /// Đánh dấu tất cả thông báo của user là đã đọc
  Future<void> markAllAsRead(String userId) async {
    await _client
        .from('notifications')
        .update({
          'is_read': true,
          'read_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('user_id', userId)
        .eq('is_read', false);
  }
}