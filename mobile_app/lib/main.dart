import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/network/supabase_client.dart';
import 'core/offline/offline_store.dart'; // THÊM: chứa SyncService

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Supabase thông qua SupabaseService (đã tích hợp sẵn kiểm tra rỗng và --dart-define)
  await SupabaseService.init();

  // THÊM: bật đồng bộ nền (cứ 20 giây đẩy các điểm danh đang chờ lên server)
  SyncService.start();

  runApp(
    const ProviderScope(
      child: SchoolBusApp(),
    ),
  );
}