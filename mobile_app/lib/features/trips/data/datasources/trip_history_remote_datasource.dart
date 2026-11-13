import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mobile_app/features/trips/data/models/trip_history_model.dart';

class TripHistoryRemoteDataSource {
  final SupabaseClient client;

  const TripHistoryRemoteDataSource(this.client);

  String _formatDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  /// Gọi hàm SQL get_teacher_trip_history (xem trip_history_setup.sql).
  /// Hàm tự lọc theo giáo viên đang đăng nhập và đã đếm sẵn số học sinh.
  Future<List<TripHistoryModel>> getTeacherTripHistory({
    required DateTime from,
    required DateTime to,
  }) async {
    final response = await client.rpc(
      'get_teacher_trip_history',
      params: {
        'p_from': _formatDate(from),
        'p_to': _formatDate(to),
      },
    );

    return List<Map<String, dynamic>>.from(response as List)
        .map(TripHistoryModel.fromJson)
        .toList();
  }
}