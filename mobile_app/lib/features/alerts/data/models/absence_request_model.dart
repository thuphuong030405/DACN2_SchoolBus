/// Một dòng trong bảng `absences` (mỗi ngày/buổi một dòng).
/// Dữ liệu lấy từ RPC get_child_absences.
class AbsenceRequestModel {
  final String id;
  final DateTime absenceDate;
  final String session; // MORNING / AFTERNOON
  final String reason;
  final String status; // PENDING / APPROVED / REJECTED
  final String? rejectionNote;
  final DateTime createdAt;

  const AbsenceRequestModel({
    required this.id,
    required this.absenceDate,
    required this.session,
    required this.reason,
    required this.status,
    required this.rejectionNote,
    required this.createdAt,
  });

  factory AbsenceRequestModel.fromMap(Map<String, dynamic> m) =>
      AbsenceRequestModel(
        id: m['absence_id'] as String,
        absenceDate: DateTime.parse(m['absence_date'] as String),
        session: m['session'] as String,
        reason: m['reason'] as String,
        status: m['status'] as String,
        rejectionNote: m['rejection_note'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
      );
}