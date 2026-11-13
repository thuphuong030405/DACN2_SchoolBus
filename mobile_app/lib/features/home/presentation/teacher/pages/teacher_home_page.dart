import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mobile_app/features/authentication/domain/entities/app_user.dart';
import 'package:mobile_app/features/authentication/presentation/providers/auth_providers.dart';
import 'package:mobile_app/features/authentication/presentation/pages/login_page.dart';
import 'package:mobile_app/features/trips/domain/entities/teacher_trip.dart';
import 'package:mobile_app/features/trips/presentation/providers/trip_provider.dart';

class TeacherHomePage extends ConsumerStatefulWidget {
  final AppUser user;
  final ValueNotifier<int>? refreshNotifier;
  final VoidCallback? onTripStarted;

  const TeacherHomePage({
    super.key,
    required this.user,
    this.refreshNotifier,
    this.onTripStarted,
  });

  static const Color primaryColor = Color(0xFF2563EB);

  @override
  ConsumerState<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends ConsumerState<TeacherHomePage> {
  bool isLoggingOut = false;
  String? _startingTripId; // chuyến đang được bấm "Bắt đầu"

  @override
  void initState() {
    super.initState();
    widget.refreshNotifier?.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.refreshNotifier?.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => ref.invalidate(teacherTodayTripsProvider);

  // =========================================================
  // BẮT ĐẦU CHUYẾN
  // =========================================================

  Future<void> _startTrip(TeacherTrip trip) async {
    if (_startingTripId != null) return;
    setState(() => _startingTripId = trip.tripId);

    try {
      final updated = await Supabase.instance.client
          .from('trips')
          .update({'status': 'IN_PROGRESS'})
          .eq('trip_id', trip.tripId)
          .eq('status', 'SCHEDULED') // chỉ bắt đầu được chuyến chưa chạy
          .select('trip_id');

      if (updated.isEmpty) {
        throw Exception(
          'Không bắt đầu được chuyến (không có quyền hoặc chuyến đã thay đổi).',
        );
      }

      ref.invalidate(teacherTodayTripsProvider);
      widget.onTripStarted?.call();

      _showMessage('Đã bắt đầu chuyến ${trip.title} • ${trip.routeName}',
          isError: false);
    } on PostgrestException catch (e) {
      _showMessage('Bắt đầu chuyến thất bại: ${e.message}', isError: true);
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''),
          isError: true);
    } finally {
      if (mounted) setState(() => _startingTripId = null);
    }
  }

  void _showMessage(String text, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor:
              isError ? Colors.red.shade600 : Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // =========================================================
  // ĐĂNG XUẤT
  // =========================================================

  Future<void> logout() async {
    if (isLoggingOut) return;

    setState(() => isLoggingOut = true);

    try {
      await Supabase.instance.client.auth.signOut();

      if (!mounted) return;

      ref.invalidate(currentUserProvider);

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đăng xuất thất bại: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoggingOut = false);
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    
    final tripsAsync = ref.watch(teacherTodayTripsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(teacherTodayTripsProvider.future),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                tripsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => _buildErrorBanner(),
                  data: _buildTripsContent,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTripsContent(List<TeacherTrip> trips) {
    final current = trips.where((t) => t.isInProgress).toList();
    final scheduled = trips.where((t) => t.isScheduled).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));

    // Chưa có chuyến nào đang chạy -> chuyến sắp tới gần nhất hiện ở khối
    // "hiện tại" ở dạng CHƯA BẮT ĐẦU (có nút Bắt đầu, không có tiến độ).
    final TeacherTrip? pendingStart =
        current.isEmpty && scheduled.isNotEmpty ? scheduled.first : null;
    final upcoming =
        pendingStart == null ? scheduled : scheduled.skip(1).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Chuyến xe hiện tại'),
        const SizedBox(height: 12),
        if (current.isNotEmpty)
          ...current.map(_buildCurrentTripCard)
        else if (pendingStart != null)
          _buildPendingTripCard(pendingStart)
        else
        _buildEmptyCard('Hôm nay bạn chưa được phân công chuyến xe nào.'),
        const SizedBox(height: 24),
        _buildSectionTitle('Chuyến xe sắp tới'),
        const SizedBox(height: 12),
        if (upcoming.isEmpty)
          _buildEmptyCard('Không còn chuyến xe nào hôm nay.')
        else
          ...upcoming.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildUpcomingTripCard(t),
            ),
          ),
      ],
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TeacherHomePage.primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Icon(Icons.person,
                size: 32, color: TeacherHomePage.primaryColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Xin chào,',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  widget.user.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text('Giáo viên',
                    style: TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ),
          const Icon(Icons.notifications_none, color: Colors.white, size: 28),
        ],
      ),
    );
  }

  // =========================================================
  // ERROR / OFFLINE BANNER
  // =========================================================

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.orange.shade800),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Không tải được dữ liệu',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black87)),
                SizedBox(height: 3),
                Text('Kiểm tra kết nối mạng rồi kéo xuống để tải lại.',
                    style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => ref.invalidate(teacherTodayTripsProvider),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(message, style: TextStyle(color: Colors.grey.shade600)),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  // =========================================================
  // CHUYẾN CHƯA BẮT ĐẦU (có nút Bắt đầu, KHÔNG có tiến độ)
  // =========================================================

  Widget _buildPendingTripCard(TeacherTrip trip) {
    final starting = _startingTripId == trip.tripId;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_bus,
                  color: TeacherHomePage.primaryColor, size: 26),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${trip.title} • ${trip.routeName}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Chưa bắt đầu',
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.directions_bus_outlined, 'Biển số xe',
              trip.licensePlate),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.access_time, 'Thời gian', trip.timeRange),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: starting ? null : () => _startTrip(trip),
              icon: starting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.play_arrow_rounded, size: 24),
              label: Text(
                starting ? 'Đang bắt đầu...' : 'Bắt đầu chuyến',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: TeacherHomePage.primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    TeacherHomePage.primaryColor.withValues(alpha: 0.5),
                disabledForegroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bấm "Bắt đầu chuyến" để hiển thị danh sách điểm danh.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // CHUYẾN ĐANG CHẠY
  // =========================================================

  Widget _buildCurrentTripCard(TeacherTrip trip) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_bus,
                  color: TeacherHomePage.primaryColor, size: 26),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${trip.title} • ${trip.routeName}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Đang chạy',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.directions_bus_outlined, 'Biển số xe',
              trip.licensePlate),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.access_time, 'Thời gian', trip.timeRange),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tiến độ điểm danh',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Text(
                '${trip.attendedStudents}/${trip.totalStudents} học sinh',
                style: const TextStyle(
                  color: TeacherHomePage.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: trip.progress,
              minHeight: 9,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation(
                  TeacherHomePage.primaryColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            trip.remainingStudents == 0
                ? 'Đã điểm danh đủ học sinh.'
                : 'Còn ${trip.remainingStudents} học sinh chưa được điểm danh.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 19, color: Colors.grey.shade600),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  // =========================================================
  // UPCOMING TRIP CARD
  // =========================================================

  Widget _buildUpcomingTripCard(TeacherTrip trip) {
    final icon = trip.tripType == 'MORNING'
        ? Icons.directions_bus_outlined
        : Icons.home_outlined;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: TeacherHomePage.primaryColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trip.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 5),
                Text(trip.routeName,
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 3),
                Text(trip.timeRange,
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade500),
        ],
      ),
    );
  }
}