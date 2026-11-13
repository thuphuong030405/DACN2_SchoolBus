import 'package:flutter/material.dart';

class TripSuccessModal extends StatelessWidget {
  final int alightedCount;
  final int absentCount;
  final String startTime;
  final String endTime;
  final String distance;
  final String skippedStopsInfo;
  final VoidCallback onGoHome;

  const TripSuccessModal({
    super.key,
    required this.alightedCount,
    required this.absentCount,
    this.startTime = '6:15',
    this.endTime = '7:12',
    this.distance = '18,4 km',
    this.skippedStopsInfo = '1 điểm · tiết kiệm 4 phút',
    required this.onGoHome,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // 🟢 Icon tích xanh hoàn thành
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFDCFCE7), // Xanh lá nhạt
                ),
                child: Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF16A34A), // Xanh lá đậm
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 📢 Tiêu đề thông báo
              const Text(
                'Chuyến đã kết thúc an toàn',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              // 📝 Phụ đề thống kê sĩ số
              Text(
                'Sĩ số khớp: $alightedCount bé đã xuống xe, $absentCount bé nghỉ học.\nKhông còn trẻ trên xe.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // 📊 Khung chi tiết chuyến đi
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildInfoRow('Bắt đầu', startTime),
                    const Divider(height: 20, color: Color(0xFFF1F5F9)),
                    _buildInfoRow('Kết thúc', endTime),
                    const Divider(height: 20, color: Color(0xFFF1F5F9)),
                    _buildInfoRow('Quãng đường', distance),
                    const Divider(height: 20, color: Color(0xFFF1F5F9)),
                    _buildInfoRow('Điểm bỏ qua', skippedStopsInfo),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ☁️ Băng thông báo trạng thái đồng bộ Máy chủ
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Đã đồng bộ lên máy chủ · nhà trường đã nhận báo cáo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF15803D),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // 🔵 Nút Về trang chủ
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: onGoHome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Về trang chủ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}