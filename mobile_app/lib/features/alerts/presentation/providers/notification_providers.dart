import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(Supabase.instance.client);
});

/// Danh sách thông báo của người dùng hiện tại, cập nhật realtime.
final notificationsProvider = StreamProvider.autoDispose<List<AppNotification>>((ref) {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return Stream.value(const <AppNotification>[]);
  return ref.watch(notificationRepositoryProvider).watchNotifications(user.id);
});

/// Số thông báo chưa đọc (dùng cho huy hiệu trên thanh menu / chuông ở Trang chủ).
final unreadNotificationCountProvider = Provider.autoDispose<int>((ref) {
  final list = ref.watch(notificationsProvider).asData?.value ?? const <AppNotification>[];
  return list.where((n) => !n.isRead).length;
});