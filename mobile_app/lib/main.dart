import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/network/supabase_client.dart'; // Điều chỉnh lại đường dẫn import nếu cần thiết (ví dụ: package:...)

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Supabase thông qua SupabaseService (đã tích hợp sẵn kiểm tra rỗng và --dart-define)
  await SupabaseService.init();

  runApp(
    const ProviderScope(
      child: SchoolBusApp(),
    ),
  );
}