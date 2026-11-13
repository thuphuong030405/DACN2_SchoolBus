import 'package:flutter/material.dart';
import '../../../authentication/domain/entities/app_user.dart';

class DriverHomePage extends StatelessWidget {
  final AppUser user;

  const DriverHomePage({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.directions_bus,
              size: 72,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            const Text('Xin chào Tài xế'),
            Text(user.fullName),
            Text(user.email),
            const Text('ROLE: DRIVER'),
          ],
        ),
      ),
    );
  }
}