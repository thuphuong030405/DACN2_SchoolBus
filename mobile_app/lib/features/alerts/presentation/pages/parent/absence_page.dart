import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/features/alerts/data/models/absence_request_model.dart';
import 'package:mobile_app/features/home/presentation/providers/parent_providers.dart';

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

  static const _quickReasons = [
    'Bé bị ốm, sốt',
    'Việc gia đình',
    'Đi khám sức khỏe',
  ];

  // Bảng màu đồng bộ với HomeColors
  static const _bg = Color(0xFFEEF5FF);
  static const _primary = Color(0xFF102A63);
  static const _primaryMid = Color(0xFF1D4ED8);
  static const _primaryLight = Color(0xFF3B82F6);
  static const _ink = Color(0xFF10224A);
  static const _muted = Color(0xFF52628A);
  static const _border = Color(0xFFE2E8F0);
  static const _blueSoft = Color(0xFFE0ECFF);

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
    FocusScope.of(context).unfocus();
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng nhập lý do xin nghỉ học'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final count = await ref.read(parentRepositoryProvider).createAbsenceRequest(
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
          backgroundColor: const Color(0xFF15803D),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      _reasonController.clear();
      setState(() {});
      ref.invalidate(absenceRequestsProvider(studentId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorText(e)),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  int get _totalDays => _endDate.difference(_startDate).inDays + 1;

  @override
  Widget build(BuildContext context) {
    final selectedChild = ref.watch(selectedChildProvider);
    final allChildren = ref.watch(childrenProvider).asData?.value ?? [];
    final approvedChildren = allChildren.where((c) => c.isApproved).toList();

    if (selectedChild == null) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: Text(
            'Chưa có học sinh được liên kết',
            style: TextStyle(color: _muted, fontSize: 15, fontFamily: 'Be Vietnam Pro'),
          ),
        ),
      );
    }

    final absencesAsync = ref.watch(absenceRequestsProvider(selectedChild.studentId));
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _bg,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(absenceRequestsProvider(selectedChild.studentId));
        },
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // 1. Header Gradient đồng bộ với Trang chủ
            Container(
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_primary, _primaryMid, _primaryLight],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -45,
                    top: -45,
                    child: Container(
                      width: 170,
                      height: 170,
                      decoration: const BoxDecoration(
                        color: Color(0x14FFFFFF),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    left: -35,
                    bottom: -25,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: Color(0x10FFFFFF),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0x26FFFFFF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.event_note_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Xin nghỉ học',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontFamily: 'Be Vietnam Pro',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Gửi đơn trực tuyến, nhà trường duyệt nhanh',
                                    style: TextStyle(
                                      color: Color(0xFFDBE8FF),
                                      fontSize: 13,
                                      fontFamily: 'Be Vietnam Pro',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // Thanh chọn nhanh bé nếu có từ 2 con trở lên
                        if (approvedChildren.length > 1) ...[
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final c in approvedChildren)
                                _buildChildPill(
                                  label: c.fullName,
                                  selected: c.studentId == selectedChild.studentId,
                                  onTap: () => ref
                                      .read(selectedChildIdProvider.notifier)
                                      .select(c.studentId),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Thân trang
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thẻ thông tin học sinh đang chọn
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A10224A),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: _blueSoft,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _initials(selectedChild.fullName),
                            style: const TextStyle(
                              color: _primaryMid,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              fontFamily: 'Be Vietnam Pro',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Học sinh xin nghỉ',
                                style: TextStyle(
                                  color: _muted,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Be Vietnam Pro',
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                selectedChild.fullName,
                                style: const TextStyle(
                                  color: _ink,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Be Vietnam Pro',
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (selectedChild.className != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _blueSoft,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Lớp ${selectedChild.className}',
                              style: const TextStyle(
                                color: _primaryMid,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Be Vietnam Pro',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Thẻ Form điền đơn
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A10224A),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tiêu đề khu vực chọn ngày + badge tổng số ngày
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Thời gian nghỉ',
                              style: TextStyle(
                                color: _ink,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Be Vietnam Pro',
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: _blueSoft,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$_totalDays ngày',
                                style: const TextStyle(
                                  color: _primaryMid,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Be Vietnam Pro',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Từ ngày - Đến ngày
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateBox(
                                label: 'Từ ngày',
                                date: _startDate,
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _startDate,
                                    firstDate: _dateOnly(DateTime.now()),
                                    lastDate: DateTime.now().add(const Duration(days: 30)),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _startDate = _dateOnly(picked);
                                      if (_endDate.isBefore(_startDate)) {
                                        _endDate = _startDate;
                                      }
                                    });
                                  }
                                },
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(Icons.arrow_forward_rounded, size: 18, color: _muted),
                            ),
                            Expanded(
                              child: _buildDateBox(
                                label: 'Đến ngày',
                                date: _endDate,
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _endDate,
                                    firstDate: _startDate,
                                    lastDate: DateTime.now().add(const Duration(days: 30)),
                                  );
                                  if (picked != null) {
                                    setState(() => _endDate = _dateOnly(picked));
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Buổi nghỉ
                        const Text(
                          'Buổi nghỉ',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Be Vietnam Pro',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTripTypeChip(
                                label: 'Đón sáng',
                                value: 'MORNING',
                                icon: Icons.wb_sunny_outlined,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildTripTypeChip(
                                label: 'Trả chiều',
                                value: 'AFTERNOON',
                                icon: Icons.wb_twilight_rounded,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildTripTypeChip(
                                label: 'Cả ngày',
                                value: 'BOTH',
                                icon: Icons.all_inclusive_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Lý do + Gợi ý nhanh
                        const Text(
                          'Lý do xin nghỉ',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Be Vietnam Pro',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final r in _quickReasons)
                              InkWell(
                                onTap: () {
                                  _reasonController.text = r;
                                  setState(() {});
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: _border),
                                  ),
                                  child: Text(
                                    r,
                                    style: const TextStyle(
                                      color: _muted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Be Vietnam Pro',
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _reasonController,
                          maxLines: 3,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 14,
                            fontFamily: 'Be Vietnam Pro',
                          ),
                          decoration: InputDecoration(
                            hintText: 'Nhập chi tiết lý do xin phép cho bé nghỉ học...',
                            hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13.5,
                              fontFamily: 'Be Vietnam Pro',
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.all(14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: _border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: _border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: _primaryMid, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Ghi chú chú thích có icon
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _blueSoft.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline_rounded, size: 18, color: _primaryMid),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Khi đơn được duyệt, điểm dừng của bé sẽ tự động bỏ khỏi lộ trình xe ngày hôm đó.',
                                  style: TextStyle(
                                    color: _primaryMid,
                                    fontSize: 12,
                                    fontFamily: 'Be Vietnam Pro',
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Nút Gửi đơn
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: FilledButton.icon(
                            onPressed: _isSubmitting
                                ? null
                                : () => _submitAbsence(selectedChild.studentId),
                            style: FilledButton.styleFrom(
                              backgroundColor: _primaryMid,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: _isSubmitting
                                ? const SizedBox.shrink()
                                : const Icon(Icons.send_rounded, size: 18),
                            label: _isSubmitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. Lịch sử đơn xin nghỉ
                  Row(
                    children: [
                      const Text(
                        'Lịch sử đơn đã gửi',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Be Vietnam Pro',
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (absencesAsync.asData?.value != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_groupAbsences(absencesAsync.asData!.value).length}',
                            style: const TextStyle(
                              color: _primaryMid,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Be Vietnam Pro',
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  absencesAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDE4E1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Không tải được lịch sử đơn: $e',
                        style: const TextStyle(color: Color(0xFFC8382F), fontSize: 13),
                      ),
                    ),
                    data: (list) {
                      if (list.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.inbox_outlined, size: 36, color: Color(0xFF94A3B8)),
                              SizedBox(height: 8),
                              Text(
                                'Chưa có đơn xin nghỉ nào',
                                style: TextStyle(
                                  color: _muted,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Be Vietnam Pro',
                                ),
                              ),
                            ],
                          ),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildPill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? Colors.white : const Color(0x26FFFFFF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? _primaryMid : Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'Be Vietnam Pro',
          ),
        ),
      ),
    );
  }

  Widget _buildDateBox({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 16, color: _primaryMid),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 11,
                      fontFamily: 'Be Vietnam Pro',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd/MM/yyyy').format(date),
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Be Vietnam Pro',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripTypeChip({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _tripType == value;
    return InkWell(
      onTap: () => setState(() => _tripType = value),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? _primaryMid : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _primaryMid : _border,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : _muted,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : _ink,
                fontSize: 12.5,
                fontFamily: 'Be Vietnam Pro',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbsenceCard(_AbsenceGroup g) {
    final item = g.first;
    final (label, bg, fg, icon) = switch (item.status) {
      'APPROVED' => (
          'Đã duyệt',
          const Color(0xFFDCF1E3),
          const Color(0xFF1E6B3A),
          Icons.check_circle_rounded,
        ),
      'REJECTED' => (
          'Từ chối',
          const Color(0xFFFDE4E1),
          const Color(0xFF9B2C22),
          Icons.cancel_rounded,
        ),
      _ => (
          'Đang chờ',
          const Color(0xFFFEF3C7),
          const Color(0xFFD97706),
          Icons.schedule_rounded,
        ),
    };
    final note = item.rejectionNote;
    final subtitle = item.status == 'REJECTED' && note != null && note.isNotEmpty
        ? 'Lý do từ chối: $note'
        : 'Gửi lúc ${DateFormat('HH:mm, dd/MM').format(item.createdAt)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x0A10224A), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: fg, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nghỉ ngày ${DateFormat('dd/MM').format(item.absenceDate)} · ${g.label}',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Be Vietnam Pro',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: item.status == 'REJECTED' ? const Color(0xFF9B2C22) : _muted,
                    fontSize: 12,
                    fontFamily: 'Be Vietnam Pro',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
            child: Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 11.5,
                fontFamily: 'Be Vietnam Pro',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return '';
  if (parts.length == 1) return parts.first.characters.take(2).toString().toUpperCase();
  return '${parts.first.characters.first}${parts.last.characters.first}'.toUpperCase();
}

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