import 'package:mobile_app/features/alerts/domain/entities/incident_report.dart';

class IncidentReportModel extends IncidentReport {
  const IncidentReportModel({
    required super.tripId,
    required super.type,
    required super.severity,
    required super.description,
    required super.notifyParents,
    super.localPhotoPaths,
  });

  factory IncidentReportModel.fromEntity(IncidentReport r) {
    return IncidentReportModel(
      tripId: r.tripId,
      type: r.type,
      severity: r.severity,
      description: r.description,
      notifyParents: r.notifyParents,
      localPhotoPaths: r.localPhotoPaths,
    );
  }

  /// Dòng INSERT vào bảng public.alerts.
  Map<String, dynamic> toInsertJson({
    required String reportedBy,
    double? latitude,
    double? longitude,
    List<String> uploadedPhotoPaths = const [],
  }) {
    final hasLocation = latitude != null && longitude != null;

    return {
      'trip_id': tripId,
      'alert_type': 'INCIDENT',
      'incident_type': type.code,
      'severity': severity.code,
      'title': 'Sự cố: ${type.label}',
      'message': description.trim(),
      'reported_by': reportedBy,
      'incident_location': hasLocation
          ? '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}'
          : null,
      'latitude': latitude,
      'longitude': longitude,
      'notify_parents': notifyParents,
      'photo_paths': uploadedPhotoPaths,
      'status': 'OPEN',
    };
  }
}