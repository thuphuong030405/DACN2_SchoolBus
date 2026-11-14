import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/parent_models.dart';
import '../../domain/repositories/parent_repository.dart';
import 'package:mobile_app/features/alerts/data/models/absence_request_model.dart';

class ParentRepositoryImpl implements ParentRepository {
  ParentRepositoryImpl(this._db);
  final SupabaseClient _db;

    @override
  Future<List<ChildInfo>> getMyChildren() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw AuthException('Chưa đăng nhập');

    final rows = await _db.rpc('get_my_children');
    return (rows as List).map((e) {
      final m = e as Map<String, dynamic>;
      return ChildInfo(
        studentId: m['student_id'] as String,
        studentCode: m['student_code'] as String?,
        fullName: (m['full_name'] as String?) ?? '',
        className: m['class_name'] as String?,
        avatarUrl: m['avatar_url'] as String?,
        relationship: m['relationship'] as String,
        verificationStatus: m['verification_status'] as String,
        notificationsEnabled: (m['can_receive_notifications'] as bool?) ?? true,
      );
    }).toList();
  }

  @override
  Future<void> requestLinkStudent({
    required String studentCode,
    required String relationship,
  }) async {
    await _db.rpc('request_link_student', params: {
      'p_student_code': studentCode.trim(),
      'p_relationship': relationship,
    });
  }

    @override
  Future<void> registerChild({
    required String fullName,
    required DateTime dateOfBirth,
    String? gender,
    String? className,
    required String relationship,
  }) async {
    String two(int n) => n.toString().padLeft(2, '0');
    await _db.rpc('submit_child_registration', params: {
      'p_full_name': fullName.trim(),
      'p_date_of_birth':
          '${dateOfBirth.year.toString().padLeft(4, '0')}-${two(dateOfBirth.month)}-${two(dateOfBirth.day)}',
      'p_gender': gender,
      'p_class_name':
          (className == null || className.trim().isEmpty) ? null : className.trim(),
      'p_relationship': relationship,
    });
  }
  Future<List<TodayTrip>> _fetchToday(String studentId) async {
    final rows =
        await _db.rpc('get_child_today', params: {'p_student_id': studentId});
    return (rows as List)
        .map((e) => TodayTrip.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Stream<List<TodayTrip>> watchChildToday(String studentId) async* {
    var hasData = false;
    while (true) {
      try {
        yield await _fetchToday(studentId);
        hasData = true;
      } catch (_) {
        if (!hasData) rethrow;
      }
      await Future<void>.delayed(const Duration(seconds: 10));
    }
  }

  @override
  Stream<GpsPoint?> watchBusLocation(String tripId) {
    return _db
        .from('gps_locations')
        .stream(primaryKey: ['gps_id'])
        .eq('trip_id', tripId)
        .order('recorded_at', ascending: false)
        .limit(1)
        .map((rows) => rows.isEmpty ? null : GpsPoint.fromMap(rows.first));
  }

  static const _consentVersion = 'v1.0';

  @override
  Future<ParentProfile> getMyProfile() async {
    final uid = _db.auth.currentUser!.id;
    final row = await _db
        .from('users')
        .select('user_id, full_name, email, phone, avatar_url, parents(address, occupation)')
        .eq('user_id', uid)
        .single();
    return ParentProfile.fromMap(row);
  }

  @override
  Future<void> updateMyProfile({
    required String fullName,
    String? phone,
    String? address,
    String? occupation,
  }) async {
    await _db.rpc('update_my_profile', params: {
      'p_full_name': fullName.trim(),
      'p_phone': phone?.trim() ?? '',
      'p_address': address?.trim(),
      'p_occupation': occupation?.trim(),
    });
  }

  @override
  Future<FaceConsent> getFaceConsent(String studentId) async {
    final rows =
        await _db.rpc('get_face_consent', params: {'p_student_id': studentId});
    final list = rows as List;
    return FaceConsent.fromMap(
        list.isEmpty ? null : list.first as Map<String, dynamic>);
  }

  @override
  Future<void> setFaceConsent({
    required String studentId,
    required bool granted,
  }) async {
    await _db.rpc('set_face_consent', params: {
      'p_student_id': studentId,
      'p_granted': granted,
      'p_version': _consentVersion,
    });
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = _db.auth.currentUser?.email;
    if (email == null) throw AuthException('Chưa đăng nhập');

    await _db.auth.signInWithPassword(email: email, password: currentPassword);
    await _db.auth.updateUser(UserAttributes(password: newPassword));

    try {
      await _db.auth.signOut(scope: SignOutScope.others);
    } catch (_) {}
  }

  // ----------------------------------------------------------- Xin nghỉ học
  // Dùng bảng `absences` có sẵn của nhóm, qua RPC (RPC tự kiểm tra quyền phụ huynh).

  @override
  Future<List<AbsenceRequestModel>> getAbsenceRequests(String studentId) async {
    final rows =
        await _db.rpc('get_child_absences', params: {'p_student_id': studentId});
    return (rows as List)
        .map((e) => AbsenceRequestModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Future<int> createAbsenceRequest({
    required String studentId,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    required String tripType,
  }) async {
    // Giao diện dùng BOTH, DB dùng FULL
    final session = tripType == 'BOTH' ? 'FULL' : tripType;
    final res = await _db.rpc('submit_absence', params: {
      'p_student_id': studentId,
      'p_from': _ymd(startDate),
      'p_to': _ymd(endDate),
      'p_session': session,
      'p_reason': reason.trim(),
    });
    return (res as num).toInt();
  }

  // ------------------------------------------------- Hồ sơ con / cài đặt

  @override
  Future<ChildProfileInfo> getChildProfileInfo(String studentId) async {
    final rows = await _db
        .rpc('get_child_profile_info', params: {'p_student_id': studentId});
    final list = rows as List;
    final Map<String, dynamic> mapData = list.isEmpty 
        ? {} 
        : (list.first as Map).cast<String, dynamic>();
    return ChildProfileInfo.fromMap(mapData);
  }

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _db.rpc('set_notifications_enabled', params: {'p_enabled': enabled});
  }

  @override
  Future<void> cancelLinkRequest(String studentId) async {
    await _db.rpc('cancel_link_request', params: {'p_student_id': studentId});
  }
}
