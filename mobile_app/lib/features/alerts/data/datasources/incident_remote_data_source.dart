import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mobile_app/features/alerts/data/models/incident_report_model.dart';
import 'package:mobile_app/features/alerts/domain/entities/incident_report.dart';

class IncidentRemoteDataSource {
  final SupabaseClient client;

  const IncidentRemoteDataSource(this.client);

  static const String _bucket = 'incident-photos';

  /// Gửi báo cáo:
  /// 1) tải ảnh lên Storage
  /// 2) lấy vị trí GPS mới nhất của xe trong chuyến
  /// 3) INSERT vào alerts (trigger trong DB sẽ tự gửi thông báo cho phụ huynh)
  Future<String> submitIncident(IncidentReportModel report) async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw const IncidentException('Bạn chưa đăng nhập.');
    }

    final photoPaths = await _uploadPhotos(
      report.tripId,
      report.localPhotoPaths,
    );

    final location = await _latestBusLocation(report.tripId);

    final row = await client
        .from('alerts')
        .insert(
          report.toInsertJson(
            reportedBy: user.id,
            latitude: location?.$1,
            longitude: location?.$2,
            uploadedPhotoPaths: photoPaths,
          ),
        )
        .select('alert_id')
        .single();

    return row['alert_id'] as String;
  }

  /// Tải từng ảnh lên bucket, trả về danh sách đường dẫn trong Storage.
  Future<List<String>> _uploadPhotos(
    String tripId,
    List<String> localPaths,
  ) async {
    final uploaded = <String>[];
    final stamp = DateTime.now().millisecondsSinceEpoch;

    for (var i = 0; i < localPaths.length; i++) {
      final local = localPaths[i];
      final isPng = local.toLowerCase().endsWith('.png');
      final ext = isPng ? 'png' : 'jpg';
      final storagePath = '$tripId/${stamp}_$i.$ext';

      await client.storage.from(_bucket).upload(
            storagePath,
            File(local),
            fileOptions: FileOptions(
              contentType: isPng ? 'image/png' : 'image/jpeg',
              upsert: false,
            ),
          );

      uploaded.add(storagePath);
    }

    return uploaded;
  }

  /// Vị trí GPS mới nhất của xe trong chuyến (lat, lng), null nếu chưa có.
  Future<(double, double)?> _latestBusLocation(String tripId) async {
    final row = await client
        .from('gps_locations')
        .select('latitude, longitude')
        .eq('trip_id', tripId)
        .order('recorded_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (row == null) return null;

    return (
      (row['latitude'] as num).toDouble(),
      (row['longitude'] as num).toDouble(),
    );
  }
}