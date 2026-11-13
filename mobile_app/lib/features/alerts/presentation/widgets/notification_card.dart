import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/notification_model.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final AppNotification item;
  final VoidCallback onTap;

  // Icon + màu theo LOẠI thông báo (notification_type), không dựa vào chữ trong tiêu đề
  ({IconData icon, Color bg, Color fg}) _style() {
    switch (item.kind) {
      case NotificationKind.attendance:
        return (icon: Icons.check, bg: const Color(0xFFDCF1E3), fg: const Color(0xFF166534));
      case NotificationKind.trip:
        return (icon: Icons.directions_bus, bg: const Color(0xFFFFF0BD), fg: const Color(0xFFD97706));
      case NotificationKind.alert:
        return (icon: Icons.warning_amber_rounded, bg: const Color(0xFFFCE4E1), fg: const Color(0xFFC8382F));
      case NotificationKind.absence:
        return (icon: Icons.event_available, bg: const Color(0xFFDCF1E3), fg: const Color(0xFF166534));
      case NotificationKind.general:
        return (icon: Icons.notifications_outlined, bg: const Color(0xFFE0ECFF), fg: const Color(0xFF1D4ED8));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _style();
    final timeStr = DateFormat('HH:mm - dd/MM').format(item.createdAt);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: s.bg, shape: BoxShape.circle),
                  child: Icon(s.icon, color: s.fg, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                color: const Color(0xFF10224A),
                                fontSize: 14,
                                fontFamily: 'Be Vietnam Pro',
                                fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeStr,
                            style: const TextStyle(
                              color: Color(0xFF52628A),
                              fontSize: 11,
                              fontFamily: 'Be Vietnam Pro',
                            ),
                          ),
                          if (!item.isRead) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 3),
                              decoration: const BoxDecoration(
                                color: Color(0xFFC8382F),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.message,
                        style: const TextStyle(
                          color: Color(0xFF52628A),
                          fontSize: 13,
                          fontFamily: 'Be Vietnam Pro',
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}