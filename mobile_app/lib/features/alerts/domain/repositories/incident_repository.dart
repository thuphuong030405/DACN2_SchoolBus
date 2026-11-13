import 'package:mobile_app/features/alerts/domain/entities/incident_report.dart';

abstract class IncidentRepository {
  /// Gửi báo cáo sự cố, trả về alert_id vừa tạo.
  /// Ném [IncidentException] nếu thất bại.
  Future<String> submitIncident(IncidentReport report);
}