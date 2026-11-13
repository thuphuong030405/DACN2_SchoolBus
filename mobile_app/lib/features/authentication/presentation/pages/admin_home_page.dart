import 'package:flutter/material.dart';
import '../../../authentication/domain/entities/app_user.dart';

class AdminHomePage extends StatelessWidget {
  final AppUser user;

  const AdminHomePage({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.admin_panel_settings,
              size: 72,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            const Text('Xin chào Quản trị viên'),
            Text(user.fullName),
            Text(user.email),
            const Text('ROLE: ADMIN'),
          ],
        ),
      ),
    );
  }
}