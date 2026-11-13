import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/features/home/presentation/providers/parent_providers.dart';
import 'package:mobile_app/features/alerts/data/models/absence_request_model.dart';

class AbsencePage extends ConsumerStatefulWidget {
  const AbsencePage({super.key});

  @override
  ConsumerState<AbsencePage> createState() => _AbsencePageState();
}

class _AbsencePageState extends ConsumerState<AbsencePage> {
  final _reasonController = TextEditingController();
  DateTime _startDate = _dateOnly(DateTime.now());
  DateTime _endDate = _dateOnly(DateTime.now());
  String _tripType = 'BOTH'; // MORNING, AFTERNOON, BOTH
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  String _errorText(Object e) {
    final s = e.toString();
    if (s.contains('DATE_IN_PAST')) return 'Không thể xin nghỉ cho ngày đã qua';
    if (s.contains('INVALID_RANGE')) return 'Ngày kết thúc phải sau ngày bắt đầu';
    if (s.contains('RANGE_TOO_LONG')) return 'Mỗi đơn chỉ được xin nghỉ tối đa 31 ngày';
    if (s.contains('ALREADY_REQUESTED')) return 'Bạn đã gửi đơn cho các buổi này rồi';
    if (s.contains('NOT_AUTHORIZED')) return 'Bạn chưa được liên kết với học sinh này';
    if (s.contains('REASON_REQUIRED')) return 'Vui lòng nhập lý do xin nghỉ học';
    return 'Không gửi được đơn: $e';
  }

  Future<void> _submitAbsence(String studentId) async {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập lý do xin nghỉ học')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final count =
          await ref.read(parentRepositoryProvider).createAbsenceRequest(
                studentId: studentId,
                startDate: _startDate,
                endDate: _endDate,
                reason: _reasonController.text.trim(),
                tripType: _tripType,
              );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã gửi đơn xin nghỉ ($count buổi), vui lòng chờ nhà trường duyệt'),
        ),
      );
      _reasonController.clear();
      ref.invalidate(absenceRequestsProvider(studentId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorText(e)), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedChild = ref.watch(selectedChildProvider);

    if (selectedChild == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFEEF5FF),
        body: const Center(child: Text('Chưa có học sinh được liên kết')),
      );
    }

    final absencesAsync = ref.watch(absenceRequestsProvider(selectedChild.studentId));

    return Scaffold(
      backgroundColor: const Color(0xFFEEF5FF),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header xanh đậm
          Container(
            padding: const EdgeInsets.only(top: 54, left: 20, right: 20, bottom: 24),
            decoration: const BoxDecoration(
              color: Color(0xFF1D4ED8),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Xin nghỉ học',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontFamily: 'Be Vietnam Pro',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Gửi đơn trực tuyến, nhà trường sẽ duyệt và báo lại.',
                  style: TextStyle(
                    color: Color(0xFFDBE8FF),
                    fontSize: 13,
                    fontFamily: 'Be Vietnam Pro',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Nội dung form
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Học sinh
                const Text('Học sinh', style: TextStyle(color: Color(0xFF52628A), fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Be Vietnam Pro')),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    selectedChild.className == null
                        ? selectedChild.fullName
                        : '${selectedChild.fullName} · Lớp ${selectedChild.className}',
                    style: const TextStyle(color: Color(0xFF10224A), fontSize: 14, fontFamily: 'Be Vietnam Pro', fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 14),

                // Từ ngày - Đến ngày
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Từ ngày', style: TextStyle(color: Color(0xFF52628A), fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Be Vietnam Pro')),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _startDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 30)),
                              );
                              if (picked != null) {
                                setState(() {
                                  _startDate = picked;
                                  if (_endDate.isBefore(_startDate)) _endDate = _startDate;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Text(
                                DateFormat('dd/MM/yyyy').format(_startDate),
                                style: const TextStyle(color: Color(0xFF10224A), fontSize: 14, fontFamily: 'Be Vietnam Pro'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Đến ngày', style: TextStyle(color: Color(0xFF52628A), fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Be Vietnam Pro')),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _endDate,
                                firstDate: _startDate,
                                lastDate: DateTime.now().add(const Duration(days: 30)),
                              );
                              if (picked != null) setState(() => _endDate = picked);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Text(
                                DateFormat('dd/MM/yyyy').format(_endDate),
                                style: const TextStyle(color: Color(0xFF10224A), fontSize: 14, fontFamily: 'Be Vietnam Pro'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Buổi nghỉ (Buổi sáng, Buổi chiều, Cả ngày)
                const Text('Buổi nghỉ', style: TextStyle(color: Color(0xFF52628A), fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Be Vietnam Pro')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildTripTypeChip('Đón sáng', 'MORNING')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildTripTypeChip('Trả chiều', 'AFTERNOON')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildTripTypeChip('Cả ngày', 'BOTH')),
                  ],
                ),
                const SizedBox(height: 14),

                // Lý do
                const Text('Lý do', style: TextStyle(color: Color(0xFF52628A), fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Be Vietnam Pro')),
                const SizedBox(height: 6),
                TextField(
                  controller: _reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Bé bị ốm, xin phép cho bé nghỉ học.',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Ghi chú chú thích
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0ECFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Nếu đơn được duyệt, điểm dừng của bé sẽ được tự động bỏ khỏi lộ trình ngày hôm đó.',
                    style: TextStyle(
                      color: Color(0xFF1D4ED8),
                      fontSize: 12,
                      fontFamily: 'Be Vietnam Pro',
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Nút Gửi đơn xin nghỉ
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : () => _submitAbsence(selectedChild.studentId),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Gửi đơn xin nghỉ',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Be Vietnam Pro',
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Lịch sử đơn xin nghỉ (bảng absences trong DB)
                const Text(
                  'Đơn đã gửi',
                  style: TextStyle(color: Color(0xFF52628A), fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Be Vietnam Pro'),
                ),
                const SizedBox(height: 8),
                absencesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text(
                    'Không tải được lịch sử đơn: $e',
                    style: const TextStyle(color: Color(0xFFC8382F), fontSize: 13),
                  ),
                  data: (list) {
                    if (list.isEmpty) {
                      return const Text(
                        'Chưa có đơn xin nghỉ nào.',
                        style: TextStyle(color: Color(0xFF52628A), fontSize: 13, fontFamily: 'Be Vietnam Pro'),
                      );
                    }
                    return Column(
                      children: [
                        for (final g in _groupAbsences(list)) ...[
                          _buildAbsenceCard(g),
                          const SizedBox(height: 10),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripTypeChip(String label, String value) {
    final isSelected = _tripType == value;
    return InkWell(
      onTap: () => setState(() => _tripType = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1D4ED8) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF10224A),
              fontSize: 13,
              fontFamily: 'Be Vietnam Pro',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAbsenceCard(_AbsenceGroup g) {
    final item = g.first;
    final (label, bg, fg) = switch (item.status) {
      'APPROVED' => ('Đã duyệt', const Color(0xFFDCF1E3), const Color(0xFF1E6B3A)),
      'REJECTED' => ('Từ chối', const Color(0xFFFDE4E1), const Color(0xFF9B2C22)),
      _ => ('Đang chờ', const Color(0xFFFEF3C7), const Color(0xFFD97706)),
    };
    final note = item.rejectionNote;
    final subtitle = item.status == 'REJECTED' && note != null && note.isNotEmpty
        ? 'Lý do từ chối: $note'
        : 'Gửi lúc ${DateFormat('HH:mm, dd/MM').format(item.createdAt)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nghỉ ngày ${DateFormat('dd/MM').format(item.absenceDate)} · ${g.label}',
                  style: const TextStyle(
                    color: Color(0xFF10224A),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Be Vietnam Pro',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF52628A),
                    fontSize: 12,
                    fontFamily: 'Be Vietnam Pro',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            child: Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontFamily: 'Be Vietnam Pro',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Gộp 2 buổi (sáng + chiều) cùng ngày, cùng trạng thái thành một dòng "Cả ngày".
class _AbsenceGroup {
  _AbsenceGroup(this.first);
  final AbsenceRequestModel first;
  final Set<String> sessions = {};

  String get label {
    if (sessions.length > 1) return 'Cả ngày';
    return first.session == 'MORNING' ? 'Đón sáng' : 'Trả chiều';
  }
}

List<_AbsenceGroup> _groupAbsences(List<AbsenceRequestModel> list) {
  final map = <String, _AbsenceGroup>{};
  for (final a in list) {
    final key = '${a.absenceDate.toIso8601String()}|${a.status}';
    map.putIfAbsent(key, () => _AbsenceGroup(a)).sessions.add(a.session);
  }
  return map.values.toList();
}