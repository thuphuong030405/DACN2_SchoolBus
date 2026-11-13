import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/parent_repository_impl.dart';
import '../../data/models/parent_models.dart';
import '../../domain/repositories/parent_repository.dart';
import 'package:mobile_app/features/alerts/data/models/absence_request_model.dart';

final parentRepositoryProvider = Provider<ParentRepository>(
  (ref) => ParentRepositoryImpl(Supabase.instance.client),
);

final childrenProvider = FutureProvider.autoDispose<List<ChildInfo>>(
  (ref) => ref.watch(parentRepositoryProvider).getMyChildren(),
);

class SelectedChildId extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String id) => state = id;
}

final selectedChildIdProvider =
    NotifierProvider<SelectedChildId, String?>(SelectedChildId.new);

/// Đứa con đang chọn (chỉ tính các con đã được duyệt)
final selectedChildProvider = Provider.autoDispose<ChildInfo?>((ref) {
  final all = ref.watch(childrenProvider).asData?.value ?? const <ChildInfo>[];
  final approved = all.where((c) => c.isApproved).toList();
  if (approved.isEmpty) return null;
  final id = ref.watch(selectedChildIdProvider);
  return approved.firstWhere((c) => c.studentId == id,
      orElse: () => approved.first);
});

final todayTripsProvider =
    StreamProvider.autoDispose.family<List<TodayTrip>, String>(
  (ref, studentId) =>
      ref.watch(parentRepositoryProvider).watchChildToday(studentId),
);

final busLocationProvider =
    StreamProvider.autoDispose.family<GpsPoint?, String>(
  (ref, tripId) => ref.watch(parentRepositoryProvider).watchBusLocation(tripId),
);

/// Tab đang mở của ParentShell (để nút ở Trang chủ chuyển sang tab Bản đồ)
class ParentTab extends Notifier<int> {
  @override
  int build() => 0;
  void go(int i) => state = i;
}

final parentTabProvider = NotifierProvider<ParentTab, int>(ParentTab.new);

final myProfileProvider = FutureProvider.autoDispose<ParentProfile>(
  (ref) => ref.watch(parentRepositoryProvider).getMyProfile(),
);

final faceConsentProvider =
    FutureProvider.autoDispose.family<FaceConsent, String>(
  (ref, studentId) => ref.watch(parentRepositoryProvider).getFaceConsent(studentId),
);

final absenceRequestsProvider = FutureProvider.autoDispose.family<List<AbsenceRequestModel>, String>(
  (ref, studentId) async {
    return await ref.read(parentRepositoryProvider).getAbsenceRequests(studentId);
  },
);

final childProfileInfoProvider =
    FutureProvider.autoDispose.family<ChildProfileInfo, String>(
  (ref, studentId) =>
      ref.watch(parentRepositoryProvider).getChildProfileInfo(studentId),
);

/// Cài đặt trên máy này: có phát âm báo khi có cảnh báo khẩn hay không (mặc định BẬT).
/// Màn hình/dịch vụ phát cảnh báo đọc: ref.read(emergencySoundProvider).value ?? true
class EmergencySoundNotifier extends AsyncNotifier<bool> {
  static const _key = 'parent_emergency_sound';

  @override
  Future<bool> build() async =>
      (await SharedPreferences.getInstance()).getBool(_key) ?? true;

  Future<void> set(bool value) async {
    state = AsyncData(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}

final emergencySoundProvider =
    AsyncNotifierProvider<EmergencySoundNotifier, bool>(EmergencySoundNotifier.new);
