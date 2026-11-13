import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'register_face_page.dart';
import 'emergency_alert_modal.dart';
import 'trip_success_modal.dart';

enum _ToastType { success, error, info }

class TeacherAttendancePage extends StatefulWidget {
  final ValueNotifier<bool>? reloadNotifier;
  final ValueNotifier<String>? directionNotifier;

  const TeacherAttendancePage({
    super.key,
    this.reloadNotifier, 
    this.directionNotifier,

  });
  
  @override
  State<TeacherAttendancePage> createState() => _TeacherAttendancePageState();
}

class _TeacherAttendancePageState extends State<TeacherAttendancePage> {
  static const Color primaryColor = Color(0xFF1E52E8);

  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  List _attendanceList = [];
  int _selectedFilterIndex = 0;

  String? _activeTripId;
  String _routeName = 'Tuyến 05';
  String _licensePlate = '43B-123.45';
  String _tripType = 'Đón sáng';

  // Mode điểm danh: 'PICKUP' (Lên xe tại nhà) | 'DROPOFF' (Xuống xe tại trường)
  String _directionMode = 'PICKUP';

  @override
  void initState() {
    super.initState();
    _directionMode = widget.directionNotifier?.value ?? 'PICKUP';
    _fetchAttendanceData();
    widget.reloadNotifier?.addListener(_onReloadTriggered);
    widget.directionNotifier?.addListener(_onDirectionChanged);
  }
  @override
  void dispose() {
    widget.reloadNotifier?.removeListener(_onReloadTriggered);
    widget.directionNotifier?.removeListener(_onDirectionChanged);
    super.dispose();
  }
  void _onDirectionChanged() {
    final v = widget.directionNotifier!.value;
    if (mounted && v != _directionMode) setState(() => _directionMode = v);
  }

  void _setDirection(String mode) {
    setState(() => _directionMode = mode);
    widget.directionNotifier?.value = mode;
  }
  void _onReloadTriggered() {
    if (mounted) {
      _fetchAttendanceData(); 
    }
  }

  void _showToast({
    required _ToastType type,
    required String title,
    String? subtitle,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!mounted) return;

    // (nền, viền, màu nhấn, màu tiêu đề, màu dòng phụ, biểu tượng)
    final (Color bg, Color border, Color accent, Color titleC, Color subC, IconData icon) =
        switch (type) {
      _ToastType.success => (
          const Color(0xFFDCFCE7),
          const Color(0xFF16A34A),
          const Color(0xFF16A34A),
          const Color(0xFF14532D),
          const Color(0xFF166534),
          Icons.check_circle_rounded,
        ),
      _ToastType.error => (
          const Color(0xFFFEE2E2),
          const Color(0xFFDC2626),
          const Color(0xFFDC2626),
          const Color(0xFF7F1D1D),
          const Color(0xFF991B1B),
          Icons.cancel_rounded,
        ),
      _ToastType.info => (
          const Color(0xFFDBEAFE),
          const Color(0xFF2563EB),
          const Color(0xFF2563EB),
          const Color(0xFF1E3A8A),
          const Color(0xFF1D4ED8),
          Icons.info_rounded,
        ),
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          duration: duration,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border, width: 2),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.35),
                  blurRadius: 18,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: titleC,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: subC,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  String _friendlyDbError(PostgrestException e) {
    switch (e.code) {
      case '42501':
        return 'Bạn không có quyền cập nhật điểm danh của học sinh này';
      case '23514':
        return 'Không hợp lệ với quy tắc điểm danh (ví dụ: xuống xe khi chưa lên xe)';
      default:
        return e.message;
    }
  }
  // 1. LẤY DỮ LIỆU ĐIỂM DANH THỰC TẾ TỪ SUPABASE
  Future<void> _fetchAttendanceData() async {
    setState(() => _isLoading = true);
    try {
      // Lấy chuyến xe đang chạy (IN_PROGRESS)
      final tripRes = await _supabase
          .from('trips')
          .select('trip_id, status, trip_type, routes(route_name), buses(license_plate)')
          .eq('status', 'IN_PROGRESS')
          .maybeSingle();

      if (tripRes == null) {
        debugPrint('Không tìm thấy chuyến xe nào đang hoạt động!');
        if (mounted) {
          setState(() {
            _attendanceList = [];
            _activeTripId = null;
            _isLoading = false;
          });
        }
        return;
      }

      final String tripId = tripRes['trip_id'];
      final routeObj = tripRes['routes'] as Map<String, dynamic>?;
      final busObj = tripRes['buses'] as Map<String, dynamic>?;

      _activeTripId = tripId;
      _routeName = routeObj?['route_name'] ?? 'Tuyến 05';
      _licensePlate = busObj?['license_plate'] ?? '43B-123.45';
      _tripType = tripRes['trip_type'] == 'MORNING' ? 'Đón sáng' : 'Trả chiều';

      // Truy vấn danh sách điểm danh học sinh
      final response = await _supabase
          .from('attendance')
          .select('''
            attendance_id,
            status,
            detection_method,
            ai_confidence,
            check_in_time,
            check_in_stop_id,
            route_stops!attendance_check_in_stop_id_fkey ( stop_name, address ),
            students!inner (
              student_id,
              full_name,
              class_name
            )
          ''')
          .eq('trip_id', tripId);

      final List loadedData = [];

      for (var item in response) {
        final student = item['students'] as Map<String, dynamic>?;
        final stopObj = item['route_stops!attendance_check_in_stop_id_fkey'] as Map<String, dynamic>?
            ?? item['route_stops'] as Map<String, dynamic>?;

        final String name = student?['full_name']?.toString() ?? 'Chưa rõ';
        final String status = item['status']?.toString() ?? 'PENDING';
        final String method = item['detection_method']?.toString() ?? 'MANUAL';
        final double? confidence = item['ai_confidence'] != null
            ? (item['ai_confidence'] as num).toDouble()
            : null;

        String stopLocation = stopObj?['stop_name'] ?? stopObj?['address'] ?? '';
        if (stopLocation.isEmpty) {
          stopLocation = _getDefaultStopName(name);
        }

        String infoText = stopLocation;
        if (status == 'ABSENT') {
          infoText += ' · nghỉ phép';
        } else if (status == 'ALIGHTED') {
          infoText += ' · đã vào lớp';
        } else {
          if (item['check_in_time'] != null) {
            final time = DateTime.parse(item['check_in_time'].toString()).toLocal();
            final formattedTime =
                "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
            infoText += " · $formattedTime";
          }
          if (method == 'AI' && confidence != null) {
            infoText += " · AI ${(confidence * 100).toInt()}%";
          } else if (method == 'MANUAL' && status == 'BOARDED') {
            infoText += " · Thủ công";
          } else if (status == 'PENDING') {
            infoText += " · chưa lên xe";
          }
        }

        loadedData.add({
          'attendance_id': item['attendance_id'],
          'student_id': student?['student_id'],
          'name': name,
          'class': infoText,
          'raw_status': status,
          'avatarBg': _getAvatarBg(name),
          'avatarTextColor': _getAvatarTextColor(name),
        });
      }

      // Sắp xếp thứ tự danh sách hiển thị
      loadedData.sort((a, b) {
        if (a['raw_status'] == b['raw_status']) return a['name'].compareTo(b['name']);
        if (a['raw_status'] == 'PENDING') return -1;
        if (b['raw_status'] == 'PENDING') return 1;
        if (a['raw_status'] == 'BOARDED') return -1;
        return 1;
      });

      if (mounted) {
        setState(() {
          _attendanceList = loadedData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải dữ liệu: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. ĐIỂM DANH THỦ CÔNG THEO NỔI LỢT (PICKUP / DROPOFF)
  Future<void> _markAttendanceManual(Map<String, dynamic> item) async {
    final attendanceId = item['attendance_id'];
    final bool pickup = _directionMode == 'PICKUP';
    final String name = '${item['name']}';
    final String now = DateTime.now().toIso8601String();

    try {
      final updated = await _supabase
          .from('attendance')
          .update({
            'status': pickup ? 'BOARDED' : 'ALIGHTED',
            'detection_method': 'MANUAL',
            'ai_confidence': null, // bắt buộc null khi điểm danh tay
            if (pickup) 'check_in_time': now else 'check_out_time': now,
            'recorded_by': _supabase.auth.currentUser?.id,
          })
          .eq('attendance_id', attendanceId)
          .select('attendance_id');

      if (updated.isEmpty) {
        _showToast(
          type: _ToastType.error,
          title: 'Không cập nhật được',
          subtitle: 'Bạn không có quyền sửa dòng này hoặc trạng thái đã thay đổi',
        );
        return;
      }

      await _fetchAttendanceData();

      _showToast(
        type: _ToastType.success,
        title: name,
        subtitle: pickup
            ? 'Đã điểm danh LÊN XE'
            : 'Đã điểm danh XUỐNG XE (vào trường)',
      );
    } on PostgrestException catch (e) {
      _showToast(
        type: _ToastType.error,
        title: 'Cập nhật thất bại',
        subtitle: _friendlyDbError(e),
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      _showToast(
        type: _ToastType.error,
        title: 'Cập nhật thất bại',
        subtitle: '$e',
        duration: const Duration(seconds: 4),
      );
    }
  }

  // 3. HÀM ĐỐI SOÁT & CHỐT CHUYẾN XE (SAFE CROSS-CHECK)
  Future<void> _checkAndFinishTrip() async {
    if (_activeTripId == null) return;

    try {
      final remainingStudents = _attendanceList
          .where((item) => item['raw_status'] == 'BOARDED')
          .toList()
          .cast();

      final alightedCount = _attendanceList.where((e) => e['raw_status'] == 'ALIGHTED').length;
      final absentCount = _attendanceList.where((e) => e['raw_status'] == 'ABSENT').length;

      if (remainingStudents.isNotEmpty) {
        // NẾU CÒN TRẺ TRÊN XE -> HIỂN THỊ CẢNH BÁO ĐỎ
        showGeneralDialog(
          context: context,
          barrierDismissible: false,
          pageBuilder: (context, animation, secondaryAnimation) {
            return EmergencyAlertModal(
              remainingStudents: remainingStudents,
              onManualCheck: () {
                Navigator.pop(context);
                _setDirection('DROPOFF');
              },
              onConfirmClear: () async {
                Navigator.pop(context);
                await _completeTripAndShowSuccess(alightedCount, absentCount);
              },
            );
          },
        );
      } else {
        // AN TOÀN 100% -> HOÀN THÀNH VÀ HIỂN THỊ MÀN HÌNH THÀNH CÔNG
        await _completeTripAndShowSuccess(alightedCount, absentCount);
      }
    } catch (e) {
      debugPrint('Lỗi chốt chuyến: $e');
    }
  }

  // Hàm phụ hỗ trợ cập nhật Supabase & Mở màn hình báo Thành Công
  Future<void> _completeTripAndShowSuccess(int alightedCount, int absentCount) async {
    final nowTime = DateTime.now();
    final formattedEndTime = "${nowTime.hour}:${nowTime.minute.toString().padLeft(2, '0')}";

    await _supabase
        .from('trips')
        .update({'status': 'COMPLETED'})
        .eq('trip_id', _activeTripId!);

    if (mounted) {
      showGeneralDialog(
        context: context,
        barrierDismissible: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return TripSuccessModal(
            alightedCount: alightedCount,
            absentCount: absentCount,
            endTime: formattedEndTime,
            onGoHome: () {
              Navigator.pop(context); // Đóng màn hình thành công
              _fetchAttendanceData(); // Làm mới dữ liệu
            },
          );
        },
      );
    }
  }

  Color _getAvatarBg(String name) {
    final hash = name.hashCode.abs() % 4;
    switch (hash) {
      case 0:
        return const Color(0xFFDBEAFE);
      case 1:
        return const Color(0xFFFEF08A);
      case 2:
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFDCFCE7);
    }
  }

  Color _getAvatarTextColor(String name) {
    final hash = name.hashCode.abs() % 4;
    switch (hash) {
      case 0:
        return const Color(0xFF1D4ED8);
      case 1:
        return const Color(0xFFA16207);
      case 2:
        return const Color(0xFFB91C1C);
      default:
        return const Color(0xFF15803D);
    }
  }

  String _getDefaultStopName(String name) {
    final hash = name.hashCode.abs() % 5;
    const stops = [
      '12 Lê Duẩn',
      '88 Hàm Nghi',
      '23 Ông Ích Khiêm',
      '61 Điện Biên Phủ',
      '102 Hoàng Diệu'
    ];
    return stops[hash];
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _attendanceList.where((item) {
      final status = item['raw_status'];
      if (_selectedFilterIndex == 1) return status == 'BOARDED' || status == 'ALIGHTED';
      if (_selectedFilterIndex == 2) return status == 'PENDING';
      if (_selectedFilterIndex == 3) return status == 'ABSENT';
      return true;
    }).toList();

    final boardedCount = _attendanceList.where((e) => e['raw_status'] == 'BOARDED').length;
    final alightedCount = _attendanceList.where((e) => e['raw_status'] == 'ALIGHTED').length;
    final pendingCount = _attendanceList.where((e) => e['raw_status'] == 'PENDING').length;
    final absentCount = _attendanceList.where((e) => e['raw_status'] == 'ABSENT').length;
    final totalCount = _attendanceList.length;

    final currentCompleted = _directionMode == 'PICKUP' ? (boardedCount + alightedCount) : alightedCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      body: Column(
        children: [
          _buildHeaderWithBubbles(),

          // THANH CHUYỂN ĐỔI 2 CHIỀU: LÊN XE (TẠI NHÀ) <-> XUỐNG XE (TẠI TRƯỜNG)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _setDirection('PICKUP'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _directionMode == 'PICKUP' ? const Color(0xFF2563EB) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '🟢 LÊN XE (Tại nhà)',
                        style: TextStyle(
                          color: _directionMode == 'PICKUP' ? Colors.white : Colors.black54,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _setDirection('DROPOFF'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _directionMode == 'DROPOFF' ? const Color(0xFFDC2626) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '🔴 XUỐNG XE (Tại trường)',
                        style: TextStyle(
                          color: _directionMode == 'DROPOFF' ? Colors.white : Colors.black54,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // CHIP LỌC TRẠNG THÁI & PROGRESS BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Tất cả $totalCount', 0),
                      _buildFilterChip(_directionMode == 'PICKUP' ? 'Đã lên ${boardedCount + alightedCount}' : 'Đã vào lớp $alightedCount', 1),
                      _buildFilterChip('Chưa lên $pendingCount', 2),
                      _buildFilterChip('Nghỉ $absentCount', 3),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: totalCount == 0 ? 0 : currentCompleted / totalCount,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFDBEAFE),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _directionMode == 'PICKUP' ? primaryColor : const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$currentCompleted/$totalCount',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // DANH SÁCH HỌC SINH
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchAttendanceData,
                    child: filteredList.isEmpty
                        ? const Center(
                            child: Text(
                              'Không có học sinh trong danh mục này',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              return _buildStudentCard(filteredList[index]);
                            },
                          ),
                  ),
          ),

        ],
      ),
    );
  }

  Widget _buildHeaderWithBubbles() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(28),
        bottomRight: Radius.circular(28),
      ),
      child: Container(
        height: 130,
        color: primaryColor,
        child: Stack(
          children: [
            // Bong bóng trang trí góc phải
            Positioned(
              right: -25,
              top: -25,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.shade900.withOpacity(0.35),
                ),
              ),
            ),
            
            // Hàng hiển thị Tiêu đề + Nút Chốt chuyến
            Positioned(
              left: 20,
              right: 16,
              bottom: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Cột thông tin chuyến đi bên trái
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Điểm danh học sinh',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_tripType · $_routeName · $_licensePlate',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 🔴 NÚT CHỐT CHUYẾN GÓC TRÊN BÊN PHẢI (NGANG HÀNG TIÊU ĐỀ)
                  Container(
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(19),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _checkAndFinishTrip,
                      icon: const Icon(Icons.verified_rounded, color: Colors.white, size: 16),
                      label: const Text(
                        'CHỐT CHUYẾN',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.3,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(19),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _selectedFilterIndex == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => setState(() => _selectedFilterIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? primaryColor : const Color(0xFFE5E7EB),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final String name = student['name'];
    final String initials = _getInitials(name);
    final String rawStatus = student['raw_status'];
    final Color avatarBg = student['avatarBg'];
    final Color avatarTextColor = student['avatarTextColor'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: avatarBg,
            child: Text(
              initials,
              style: TextStyle(
                color: avatarTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  student['class'],
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // =========================================================
          // NÚT ĐĂNG KÝ KHUÔN MẶT AI (THÊM VÀO ĐÂY)
          // =========================================================
          IconButton(
            icon: const Icon(Icons.face_retouching_natural, color: Color(0xFF1E52E8), size: 22),
            tooltip: 'Đăng ký khuôn mặt',
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            onPressed: () async {
              final bool? isSuccess = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RegisterFacePage(
                    studentId: student['student_id'],
                    studentName: student['name'],
                  ),
                ),
              );

              // Sau khi đăng ký xong -> Làm mới danh sách
              if (isSuccess == true && mounted) {
                _fetchAttendanceData();
              }
            },
          ),

          const SizedBox(width: 4),

          // Nút trạng thái điểm danh hiện tại của bạn
          _buildStatusBadge(student, rawStatus),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(Map<String, dynamic> student, String rawStatus) {
    // 1. Trường hợp cần điểm danh tay (Chưa lên xe khi đang ở tab PICKUP, hoặc Đã lên xe nhưng chưa xuống khi ở tab DROPOFF)
    bool needAction = (_directionMode == 'PICKUP' && rawStatus == 'PENDING') ||
        (_directionMode == 'DROPOFF' && rawStatus == 'BOARDED');

    if (needAction) {
      return OutlinedButton.icon(
        onPressed: () => _markAttendanceManual(student),
        icon: const Icon(Icons.touch_app, size: 14, color: Color(0xFFDC2626)),
        label: Text(
          _directionMode == 'PICKUP' ? 'Lên xe' : 'Xuống xe',
          style: const TextStyle(
            color: Color(0xFFDC2626),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFEF4444)),
          backgroundColor: const Color(0xFFFEF2F2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    Color bgColor;
    Color textColor;
    String statusText;

    if (rawStatus == 'ALIGHTED') {
      bgColor = const Color(0xFFDCFCE7);
      textColor = const Color(0xFF15803D);
      statusText = 'Đã vào lớp';
    } else if (rawStatus == 'BOARDED') {
      bgColor = const Color(0xFFFEF08A);
      textColor = const Color(0xFF854D0E);
      statusText = 'Đã lên xe';
    } else if (rawStatus == 'ABSENT') {
      bgColor = const Color(0xFFF3F4F6);
      textColor = const Color(0xFF4B5563);
      statusText = 'Nghỉ phép';
    } else {
      bgColor = const Color(0xFFF1F5F9);
      textColor = const Color(0xFF64748B);
      statusText = 'Chưa lên xe';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[parts.length - 2][0]}${parts.last[0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '';
  }

  
}

