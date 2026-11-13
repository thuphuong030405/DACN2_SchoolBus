import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../authentication/domain/entities/app_user.dart';
// Nhớ import trang Login của bạn vào đây (kiểm tra lại đường dẫn tương ứng nếu cần)
import '../pages/login_page.dart'; 

class ParentHomePage extends StatelessWidget {
  final AppUser user;

  const ParentHomePage({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Dashboard'),
        actions: [
          // Nút đăng xuất trên góc phải AppBar
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () async {
              // 1. Thực hiện đăng xuất khỏi Supabase
              await Supabase.instance.client.auth.signOut();

              // 2. Kiểm tra context và điều hướng về trang Login, xóa sạch lịch sử stack
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginPage(),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.family_restroom,
                size: 72,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              const Text('Xin chào Phụ huynh'),
              Text(
                user.fullName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(user.email),
              const Text('ROLE: PARENT'),
              const SizedBox(height: 32),
              
              // Nút đăng xuất dạng màu đỏ bên dưới
              ElevatedButton.icon(
                onPressed: () async {
                  // 1. Thực hiện đăng xuất khỏi Supabase
                  await Supabase.instance.client.auth.signOut();

                  // 2. Kiểm tra context và điều hướng về trang Login, xóa sạch lịch sử stack
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginPage(),
                    ),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('Đăng xuất tài khoản'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}