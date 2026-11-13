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

  // Bảng màu đồng bộ toàn app
  static const _bg = Color(0xFFEEF5FF);
  static const _primary = Color(0xFF102A63);
  static const _primaryMid = Color(0xFF1D4ED8);
  static const _primaryLight = Color(0xFF3B82F6);
  static const _ink = Color(0xFF10224A);
  static const _muted = Color(0xFF52628A);
  static const _blueSoft = Color(0xFFE0ECFF);

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Lọc theo LOẠI thông báo. "Cảnh báo" gồm cảnh báo + thông báo xe sắp tới.
  bool _matches(AppNotification n, String filter) {
    switch (filter) {
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
      if (mounted) _snack('Đã đánh dấu tất cả thông báo là đã đọc');
    } catch (e) {
      if (mounted) _snack('Không đánh dấu được: $e');
    }
  }

  /// Bấm vào thông báo: đánh dấu đã đọc, rồi chuyển tới màn hình liên quan.
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
    final allList = notificationsAsync.asData?.value ?? const <AppNotification>[];
    final topPadding = MediaQuery.of(context).padding.top;

    final attendanceCount = allList.where((n) => _matches(n, 'ATTENDANCE')).length;
    final alertCount = allList.where((n) => _matches(n, 'ALERT')).length;

    return Scaffold(
      backgroundColor: _bg,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(notificationsProvider),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            // 1. Header Gradient đồng bộ
            Container(
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_primary, _primaryMid, _primaryLight],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -45,
                    top: -45,
                    child: Container(
                      width: 170,
                      height: 170,
                      decoration: const BoxDecoration(
                        color: Color(0x14FFFFFF),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    left: -35,
                    bottom: -25,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: Color(0x10FFFFFF),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0x26FFFFFF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.notifications_active_outlined,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Thông báo',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontFamily: 'Be Vietnam Pro',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    unread > 0
                                        ? 'Bạn có $unread thông báo mới chưa đọc'
                                        : 'Bạn đã xem hết tất cả thông báo',
                                    style: const TextStyle(
                                      color: Color(0xFFDBE8FF),
                                      fontSize: 12.5,
                                      fontFamily: 'Be Vietnam Pro',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Nút Đọc tất cả dạng pill gọn gàng
                            InkWell(
                              onTap: unread > 0 ? _markAll : null,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: unread > 0
                                      ? const Color(0x2EFFFFFF)
                                      : const Color(0x12FFFFFF),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.done_all_rounded,
                                      size: 16,
                                      color: unread > 0
                                          ? Colors.white
                                          : const Color(0x80DBE8FF),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Đọc tất cả',
                                      style: TextStyle(
                                        color: unread > 0
                                            ? Colors.white
                                            : const Color(0x80DBE8FF),
                                        fontSize: 12.5,
                                        fontFamily: 'Be Vietnam Pro',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Thanh lọc kèm icon và số lượng
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip(
                                'Tất cả',
                                value: 'ALL',
                                icon: Icons.apps_rounded,
                                count: allList.length,
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                'Điểm danh',
                                value: 'ATTENDANCE',
                                icon: Icons.how_to_reg_rounded,
                                count: attendanceCount,
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                'Cảnh báo',
                                value: 'ALERT',
                                icon: Icons.directions_bus_filled_outlined,
                                count: alertCount,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. Danh sách thông báo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: notificationsAsync.when(
                skipLoadingOnReload: true,
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 36, color: Color(0xFFC8382F)),
                      const SizedBox(height: 8),
                      Text(
                        'Không tải được thông báo: $e',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFC8382F),
                          fontSize: 13.5,
                          fontFamily: 'Be Vietnam Pro',
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: () => ref.invalidate(notificationsProvider),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
                data: (list) {
                  final filtered = list.where((n) => _matches(n, _filter)).toList();

                  if (filtered.isEmpty) {
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0810224A),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: _blueSoft,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              size: 32,
                              color: _primaryMid,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Chưa có thông báo nào',
                            style: TextStyle(
                              color: _ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Be Vietnam Pro',
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Các cập nhật đón trả và thông báo từ nhà trường sẽ hiển thị tại đây.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _muted,
                              fontSize: 12.5,
                              height: 1.4,
                              fontFamily: 'Be Vietnam Pro',
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Nhóm theo ngày: Hôm nay / Hôm qua / Trước đó
                  final children = <Widget>[];
                  String? lastGroup;
                  for (final item in filtered) {
                    final g = _group(item.createdAt);
                    if (g != lastGroup) {
                      lastGroup = g;
                      children.add(
                        Padding(
                          padding: EdgeInsets.only(
                            top: children.isEmpty ? 4 : 12,
                            bottom: 10,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: _primaryMid,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                g,
                                style: const TextStyle(
                                  color: _ink,
                                  fontSize: 13.5,
                                  fontFamily: 'Be Vietnam Pro',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Divider(color: Color(0xFFD6E4FF), thickness: 1),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    children.add(NotificationCard(item: item, onTap: () => _onTap(item)));
                    children.add(const SizedBox(height: 10));
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: children,
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label, {
    required String value,
    required IconData icon,
    required int count,
  }) {
    final isSelected = _filter == value;
    return InkWell(
      onTap: () => setState(() => _filter = value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0x24FFFFFF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? _primaryMid : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? _primaryMid : Colors.white,
                fontSize: 13,
                fontFamily: 'Be Vietnam Pro',
                fontWeight: FontWeight.w600,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? _blueSoft : const Color(0x2EFFFFFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected ? _primaryMid : Colors.white,
                    fontSize: 11,
                    fontFamily: 'Be Vietnam Pro',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}