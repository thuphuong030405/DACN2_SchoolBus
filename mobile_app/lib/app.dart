
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/authentication/presentation/pages/auth_gate.dart';

class SchoolBusApp extends ConsumerWidget {
  const SchoolBusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'School Bus AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Kiểm tra đăng nhập và phân quyền
      home: const AuthGate(),
    );
  }
}
