import 'package:mobile_app/features/alerts/domain/entities/incident_report.dart';
import 'package:mobile_app/features/alerts/domain/repositories/incident_repository.dart';

class SubmitIncidentReport {
  final IncidentRepository repository;

  const SubmitIncidentReport(this.repository);

  Future<String> call(IncidentReport report) {
    if (report.tripId.isEmpty) {
      throw const IncidentException('Hôm nay bạn chưa có chuyến xe nào.');
    }

    if (report.description.trim().isEmpty) {
      throw const IncidentException('Vui lòng nhập mô tả sự cố.');
    }

    if (report.localPhotoPaths.length > IncidentReport.maxPhotos) {
      throw const IncidentException(
        'Chỉ được đính kèm tối đa ${IncidentReport.maxPhotos} ảnh.',
      );
    }

    return repository.submitIncident(report);
  }
}