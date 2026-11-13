import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mobile_app/features/authentication/domain/entities/app_user.dart';

import '../pages/teacher_home_page.dart';
import '../widgets/teacher_bottom_navigation.dart';

import 'package:mobile_app/features/trips/presentation/pages/teacher/teacher_route_page.dart';
import 'package:mobile_app/features/attendance/presentation/pages/teacher/teacher_attendance_page.dart';
import 'package:mobile_app/features/alerts/presentation/pages/teacher/teacher_alerts_page.dart';
import 'package:mobile_app/features/profile/presentation/pages/teacher/teacher_profile_page.dart';

import 'package:mobile_app/features/attendance/presentation/pages/teacher/face_scan_page.dart';
import 'package:mobile_app/features/trips/data/repositories/active_trip_query.dart';

import 'package:mobile_app/features/trips/data/repositories/active_trip_query.dart';


class TeacherShell extends StatefulWidget {
  final AppUser user;

  
  const TeacherShell({
    super.key,
    required this.user,
  });

  @override
  State<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends State<TeacherShell> {
  final _supabase = Supabase.instance.client;
  int _currentIndex = 0;

  // Biến phát tín hiệu reload dữ liệu cho màn hình Điểm danh
  final ValueNotifier<bool> _attendanceReloadNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String> _directionNotifier = ValueNotifier<String>('PICKUP');
  final ValueNotifier<int> _homeReloadNotifier = ValueNotifier<int>(0);

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      TeacherHomePage(
        user: widget.user,
        refreshNotifier: _homeReloadNotifier,
        // Bấm "Bắt đầu chuyến" xong thì báo tab Điểm danh nạp lại danh sách
        onTripStarted: () =>
            _attendanceReloadNotifier.value = !_attendanceReloadNotifier.value,
      ),
      const TeacherRoutePage(),
      TeacherAttendancePage(
        reloadNotifier: _attendanceReloadNotifier,
        directionNotifier: _directionNotifier,
      ),
      const TeacherAlertsPage(),
      TeacherProfilePage(user: widget.user),
    ];
  }

  @override
  void dispose() {
    _attendanceReloadNotifier.dispose();
    _directionNotifier.dispose();
    _homeReloadNotifier.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (index < 0 || index >= _pages.length) return;

    setState(() {
      _currentIndex = index;
    });

    // Quay về tab Chuyến xe thì tải lại (vd: sau khi chốt chuyến)
    if (index == 0) _homeReloadNotifier.value++;
  }

  // 📷 TRUY VẤN TRIP_ID ĐANG CHẠY VÀ MỞ MÀN HÌNH QUÉT CAMERA
  Future<void> _openCameraScan() async {
    try {
      final tripRes = await ActiveTripQuery.forCurrentTeacher(
        _supabase,
        columns: 'trip_id, routes(route_name)',
      );

      if (tripRes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chưa có chuyến đang chạy. Hãy bấm "Bắt đầu chuyến" ở tab Chuyến xe.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final String activeTripId = tripRes['trip_id'];
      final routeData = tripRes['routes'] as Map<String, dynamic>?;
      final String routeName = routeData?['route_name'] ?? 'Tuyến 05';

      if (!mounted) return;

      // Mở màn hình quét mặt
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FaceScanPage(
            tripId: activeTripId,
            routeName: routeName,
            stopName: '12 Lê Duẩn',
            directionNotifier: _directionNotifier,
          ),
        ),
      );

      // KHI TẮT MÀN HÌNH QUÉT QUAY VỀ:
      if (mounted) {
        // 1. Tự động chuyển view về Tab Điểm danh (index = 2)
        setState(() {
          _currentIndex = 2;
        });

        // 2. Bật tín hiệu yêu cầu TeacherAttendancePage làm mới dữ liệu lập tức!
        _attendanceReloadNotifier.value = !_attendanceReloadNotifier.value;
      }
    } catch (e) {
      debugPrint('Lỗi mở camera quét mặt: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 45.0, right: 2.5),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFDE047), // Vàng sáng phần trên
                Color(0xFFFACC15), // Vàng thân xe buýt chủ đạo
                Color(0xFFEAB308), // Vàng đậm tạo khối
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.9),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEAB308).withOpacity(0.42),
                blurRadius: 14,
                spreadRadius: 1,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _openCameraScan,
              splashColor: Colors.white.withOpacity(0.4),
              highlightColor: Colors.white.withOpacity(0.15),
              child: const Center(
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: Color(0xFF0F172A), // Xanh đen đậm (giống sọc & bánh xe) giúp icon rõ nét
                  size: 26,
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: TeacherBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
      ),
    );
  }
}