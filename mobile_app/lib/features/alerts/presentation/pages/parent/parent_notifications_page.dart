import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_app/features/alerts/data/models/notification_model.dart';
import 'package:mobile_app/features/alerts/presentation/providers/notification_providers.dart';
import 'package:mobile_app/features/alerts/presentation/widgets/notification_card.dart';
import 'package:mobile_app/features/home/presentation/providers/parent_providers.dart';

class ParentNotificationsPage extends ConsumerStatefulWidget {
  const ParentNotificationsPage({super.key});

  @override
  ConsumerState<ParentNotificationsPage> createState() => _ParentNotificationsPageState();
}

class _ParentNotificationsPageState extends ConsumerState<ParentNotificationsPage> {
  String _filter = 'ALL'; // 'ALL', 'ATTENDANCE', 'ALERT'

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  /// Lọc theo LOẠI thông báo. "Cảnh báo" gồm cảnh báo + thông báo xe sắp tới (giữ như thiết kế cũ).
  bool _matches(AppNotification n) {
    switch (_filter) {
      case 'ATTENDANCE':
        return n.kind == NotificationKind.attendance;
      case 'ALERT':
        return n.kind == NotificationKind.alert || n.kind == NotificationKind.trip;
      default:
        return true;
    }
  }

  String _group(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(DateTime(d.year, d.month, d.day)).inDays;
    if (diff <= 0) return 'Hôm nay';
    if (diff == 1) return 'Hôm qua';
    return 'Trước đó';
  }

  Future<void> _markAll() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await ref.read(notificationRepositoryProvider).markAllAsRead(user.id);
      ref.invalidate(notificationsProvider);
    } catch (e) {
      if (mounted) _snack('Không đánh dấu được: $e');
    }
  }

  /// Bấm vào thông báo: đánh dấu đã đọc, rồi chuyển tới màn hình liên quan
  /// (dùng các khóa ngoại related_student_id / related_trip_id của bảng notifications).
  Future<void> _onTap(AppNotification n) async {
    if (!n.isRead) {
      try {
        await ref.read(notificationRepositoryProvider).markAsRead(n.notificationId);
        ref.invalidate(notificationsProvider);
      } catch (e) {
        if (mounted) _snack('Không đánh dấu được: $e');
      }
    }
    if (!mounted) return;

    final sid = n.relatedStudentId;
    if (sid != null) ref.read(selectedChildIdProvider.notifier).select(sid);

    final tab = ref.read(parentTabProvider.notifier);
    switch (n.kind) {
      case NotificationKind.alert:
      case NotificationKind.trip:
        tab.go(1); // Theo dõi
      case NotificationKind.attendance:
        tab.go(0); // Trang chủ
      case NotificationKind.absence:
        tab.go(3); // Xin nghỉ
      case NotificationKind.general:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFEEF5FF),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(notificationsProvider),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.only(top: 54, left: 20, right: 20, bottom: 24),
              decoration: const BoxDecoration(
                color: Color(0xFF1D4ED8),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Thông báo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontFamily: 'Be Vietnam Pro',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (unread > 0)
                            Text(
                              '$unread chưa đọc',
                              style: const TextStyle(
                                color: Color(0xFFDBE8FF),
                                fontSize: 13,
                                fontFamily: 'Be Vietnam Pro',
                              ),
                            ),
                        ],
                      ),
                      TextButton(
                        onPressed: unread > 0 ? _markAll : null,
                        child: Text(
                          'Đọc tất cả',
                          style: TextStyle(
                            color: unread > 0 ? Colors.white : const Color(0x99DBE8FF),
                            fontSize: 14,
                            fontFamily: 'Be Vietnam Pro',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Tất cả', value: 'ALL'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Điểm danh', value: 'ATTENDANCE'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Cảnh báo', value: 'ALERT'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Danh sách thông báo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: notificationsAsync.when(
                skipLoadingOnReload: true,
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Text('Không tải được thông báo: $e',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFFC8382F))),
                      TextButton(
                        onPressed: () => ref.invalidate(notificationsProvider),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
                data: (list) {
                  final filtered = list.where(_matches).toList();

                  if (filtered.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.notifications_none, size: 48, color: Color(0xFF94A3B8)),
                            SizedBox(height: 8),
                            Text(
                              'Chưa có thông báo nào',
                              style: TextStyle(color: Color(0xFF52628A), fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Nhóm theo ngày: Hôm nay / Hôm qua / Trước đó (danh sách đã sắp mới -> cũ)
                  final children = <Widget>[];
                  String? lastGroup;
                  for (final item in filtered) {
                    final g = _group(item.createdAt);
                    if (g != lastGroup) {
                      lastGroup = g;
                      children.add(Padding(
                        padding: const EdgeInsets.only(left: 2, top: 6, bottom: 10),
                        child: Text(
                          g,
                          style: const TextStyle(
                            color: Color(0xFF52628A),
                            fontSize: 13,
                            fontFamily: 'Be Vietnam Pro',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ));
                    }
                    children.add(NotificationCard(item: item, onTap: () => _onTap(item)));
                    children.add(const SizedBox(height: 12));
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: children,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, {required String value}) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color.fromRGBO(255, 255, 255, 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF1D4ED8) : Colors.white,
            fontSize: 13,
            fontFamily: 'Be Vietnam Pro',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}