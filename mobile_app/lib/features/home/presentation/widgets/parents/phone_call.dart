import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Mở ứng dụng gọi điện; báo lỗi bằng SnackBar nếu không có số hoặc không mở được.
Future<void> callPhone(BuildContext context, String? phone) async {
  final p = phone?.trim() ?? '';
  if (p.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chưa có số điện thoại để gọi')),
    );
    return;
  }
  var ok = false;
  try {
    ok = await launchUrl(Uri(scheme: 'tel', path: p));
  } catch (_) {}
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Không mở được ứng dụng gọi điện')),
    );
  }
}
