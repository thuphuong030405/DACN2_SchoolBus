import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../../domain/entities/app_user.dart';

import 'login_page.dart';

import 'package:mobile_app/features/authentication/presentation/pages/admin_home_page.dart';
import 'package:mobile_app/features/authentication/presentation/pages/driver_home_page.dart';
import 'package:mobile_app/features/authentication/presentation/pages/parent_home_page.dart';

// Gọi TeacherShell thay vì TeacherHomePage trực tiếp
import 'package:mobile_app/features/home/presentation/teacher/layouts/teacher_shell.dart';
import 'package:mobile_app/features/chatbot/presentation/widgets/chatbot_fab.dart';


class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  /// Đặt nút chatbot nổi lên trên màn hình chính của từng vai trò.
  Widget _withChatbot(Widget page, String roleLabel) {
    return Stack(
      fit: StackFit.expand,
      children: [
        page,
        ChatbotFab(userRole: roleLabel),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      error: (error, stack) {
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Không thể tải thông tin tài khoản',
                  ),
                  const SizedBox(height: 8),
                  Text('$error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(currentUserProvider);
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      data: (user) {
        // Chưa đăng nhập
        if (user == null) {
          return const LoginPage();
        }

        // Đã đăng nhập: điều hướng theo phân quyền (role)
        // switch (user.role) {
        //   case UserRole.admin:
        //     return AdminHomePage(user: user);

        //   case UserRole.schoolManager:
        //     return AdminHomePage(user: user);

        //   case UserRole.teacher:
        //     return TeacherShell(user: user); // Mở khung 5 tab của Giáo viên

        //   case UserRole.driver:
        //     return DriverHomePage(user: user);

        //   case UserRole.parent:
        //     return ParentHomePage(user: user);
        // }
        switch (user.role) {
  case UserRole.admin:
    return _withChatbot(AdminHomePage(user: user), 'quản trị viên');

  case UserRole.schoolManager:
    return _withChatbot(AdminHomePage(user: user), 'quản lý nhà trường');

  case UserRole.teacher:
    return _withChatbot(TeacherShell(user: user), 'giáo viên');

  case UserRole.driver:
    return _withChatbot(DriverHomePage(user: user), 'tài xế');

  case UserRole.parent:
    return _withChatbot(ParentHomePage(user: user), 'phụ huynh');
}
      },
    );
  }
}