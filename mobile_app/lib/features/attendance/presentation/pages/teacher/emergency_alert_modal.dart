import 'package:flutter/material.dart';

class EmergencyAlertModal extends StatelessWidget {
  final List remainingStudents;
  final VoidCallback onManualCheck;
  final VoidCallback onConfirmClear;

  const EmergencyAlertModal({
    super.key,
    required this.remainingStudents,
    required this.onManualCheck,
    required this.onConfirmClear,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB91C1C), // Màu đỏ cảnh báo chủ đạo
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              
              // 🔴 Icon cảnh báo nổi bật
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
                child: Center(
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFB91C1C),
                      size: 45,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 📢 Tiêu đề báo động
              const Text(
                'BÁO ĐỘNG KHẨN CẤP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Còn ${remainingStudents.length} bé trên xe!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Không thể kết thúc chuyến. Hãy kiểm tra kỹ từng hàng ghế.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),

              // 📋 Danh sách học sinh còn trên xe
              Expanded(
                child: ListView.builder(
                  itemCount: remainingStudents.length,
                  itemBuilder: (context, index) {
                    final student = remainingStudents[index];
                    final name = student['name'] ?? 'Chưa rõ';
                    final initials = _getInitials(name);
                    final String info = student['class'] ?? 'Đã lên xe · chưa xuống xe';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: const Color(0xFFFACC15), // Avatar vàng
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Color(0xFF854D0E),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  info,
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ⚡ Nút thao tác nhanh (Còi, Rung, Nháy đèn)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickActionButton('Còi tối đa'),
                  _buildQuickActionButton('Rung'),
                  _buildQuickActionButton('Nháy đèn'),
                ],
              ),
              const SizedBox(height: 20),

              // 🔘 Nút 1: Điểm danh bổ sung (Xuống xe)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: onManualCheck,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: const Text(
                    'Điểm danh bổ sung (xuống xe)',
                    style: TextStyle(
                      color: Color(0xFF991B1B),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 🔘 Nút 2: Xác nhận đã kiểm tra an toàn sàn xe
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: onConfirmClear,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: const Text(
                    'Đã kiểm tra, không còn trẻ trên xe',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Còi chỉ tắt khi xác nhận · hệ thống ghi lại người xử lý',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF991B1B),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  static String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[parts.length - 2][0]}${parts.last[0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '';
  }
}