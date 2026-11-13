import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mobile_app/features/alerts/data/datasources/incident_remote_data_source.dart';
import 'package:mobile_app/features/alerts/data/models/incident_report_model.dart';
import 'package:mobile_app/features/alerts/domain/entities/incident_report.dart';
import 'package:mobile_app/features/alerts/domain/repositories/incident_repository.dart';

class IncidentRepositoryImpl implements IncidentRepository {
  final IncidentRemoteDataSource remote;

  const IncidentRepositoryImpl(this.remote);

  @override
  Future<String> submitIncident(IncidentReport report) async {
    try {
      return await remote.submitIncident(
        IncidentReportModel.fromEntity(report),
      );
    } on IncidentException {
      rethrow;
    } on StorageException catch (e) {
      debugPrint('Incident upload error: ${e.message}');
      throw const IncidentException(
        'Không tải được ảnh lên. Kiểm tra mạng rồi thử lại.',
      );
    } on PostgrestException catch (e) {
      debugPrint('Incident insert error: ${e.message}');
      throw const IncidentException(
        'Không lưu được báo cáo. Vui lòng thử lại.',
      );
    } catch (e) {
      debugPrint('Incident unknown error: $e');
      throw const IncidentException(
        'Có lỗi xảy ra, vui lòng kiểm tra kết nối và thử lại.',
      );
    }
  }
}