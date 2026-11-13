import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:mobile_app/features/trips/domain/entities/trip_history_item.dart';
import 'package:mobile_app/features/trips/presentation/providers/trip_history_provider.dart';

// =========================================================
// MÀU SẮC & KIỂU CHỮ THEO THIẾT KẾ FIGMA
// =========================================================

class _C {
  const _C._();

  static const Color background = Color(0xFFEEF5FF);
  static const Color header = Color(0xFF1D4ED8);
  static const Color headerButton = Color(0xFF1E40AF);
  static const Color headerSubtitle = Color(0xFFDBE8FF);
  static const Color navy = Color(0xFF10224A);
  static const Color grey = Color(0xFF52628A);
  static const Color blue = Color(0xFF2563EB);
  static const Color blueText = Color(0xFF1D4ED8);
  static const Color blueLight = Color(0xFFE0ECFF);
  static const Color chipBorder = Color(0xFFC5D2EA);
  static const Color amberBadge = Color(0xFFFFF0BD);
  static const Color amberText = Color(0xFF7A4A00);
  static const Color greenBadge = Color(0xFFDCF1E3);
  static const Color greenText = Color(0xFF1E6B3A);
  static const Color redBadge = Color(0xFFFBE0DD);
  static const Color redText = Color(0xFF9B2C22);

  static const String font = 'Be Vietnam Pro';
}

TextStyle _text(double size, FontWeight weight, Color color) {
  return TextStyle(
    fontFamily: _C.font,
    fontSize: size,
    fontWeight: weight,
    color: color,
  );
}

class TeacherTripHistoryPage extends ConsumerStatefulWidget {
  const TeacherTripHistoryPage({super.key});

  @override
  ConsumerState<TeacherTripHistoryPage> createState() =>
      _TeacherTripHistoryPageState();
}

class _TeacherTripHistoryPageState
    extends ConsumerState<TeacherTripHistoryPage> {
  static const List<String> _weekdays = [
    'Thứ Hai',
    'Thứ Ba',
    'Thứ Tư',
    'Thứ Năm',
    'Thứ Sáu',
    'Thứ Bảy',
    'Chủ Nhật',
  ];

  TripHistoryPeriod _period = TripHistoryPeriod.week;

  /// Ngày hiện tại theo giờ Việt Nam.
  DateTime get _today {
    final vn = DateTime.now().toUtc().add(const Duration(hours: 7));
    return DateTime(vn.year, vn.month, vn.day);
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(tripHistoryProvider(_period));
    final items = historyAsync.hasValue ? historyAsync.value : null;

    final profileAsync = ref.watch(userProfileProvider);
    final name = profileAsync.hasValue ? profileAsync.value?.fullName : null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.background,
        body: Column(
          children: [
            _buildHeader(context, name: name, items: items),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.refresh(tripHistoryProvider(_period).future),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  children: [
                    _buildFilterChips(),
                    const SizedBox(height: 8),
                    _buildSummary(items, loading: historyAsync.isLoading),
                    const SizedBox(height: 8),
                    ..._buildContent(historyAsync),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // HEADER XANH
  // =====================================================

  Widget _buildHeader(
    BuildContext context, {
    required String? name,
    required List<TripHistoryItem>? items,
  }) {
    final topPadding = MediaQuery.of(context).padding.top;

    // Hiện tên tuyến nếu toàn bộ chuyến cùng một tuyến
    final routes = {for (final i in items ?? <TripHistoryItem>[]) i.routeName};
    final subtitle = [
      if (name != null && name.trim().isNotEmpty) name.trim(),
      if (routes.length == 1 && routes.first.isNotEmpty) routes.first,
    ].join(' · ');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 20),
      decoration: const BoxDecoration(
        color: _C.header,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Material(
            color: _C.headerButton,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).maybePop(),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.arrow_back, color: Colors.white, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lịch sử đưa đón',
                  style: _text(20, FontWeight.w700, Colors.white),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _text(13, FontWeight.w400, _C.headerSubtitle),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // BỘ LỌC
  // =====================================================

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final period in TripHistoryPeriod.values)
          _buildChip(period, selected: period == _period),
      ],
    );
  }

  Widget _buildChip(TripHistoryPeriod period, {required bool selected}) {
    return Material(
      color: selected ? _C.blue : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? _C.blue : _C.chipBorder),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () {
          if (!selected) setState(() => _period = period);
        },
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          child: Text(
            period.label,
            style: _text(
              13,
              FontWeight.w600,
              selected ? Colors.white : _C.navy,
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // SỐ LIỆU TỔNG HỢP
  // =====================================================

  Widget _buildSummary(List<TripHistoryItem>? items, {required bool loading}) {
    String value(int? number) => items == null || loading ? '…' : '$number';

    final completed = items?.where((i) => i.isCompleted).length;
    final delayed = items?.where((i) => i.isDelayed).length;
    final incidents = items?.where((i) => i.hasIncident).length;

    return Row(
      children: [
        Expanded(
          child: _buildStat(value(completed), 'Chuyến', _C.navy),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStat(value(delayed), 'Trễ giờ', _C.navy),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStat(
            value(incidents),
            'Sự cố',
            (incidents ?? 0) > 0 ? _C.redText : _C.navy,
          ),
        ),
      ],
    );
  }

  Widget _buildStat(String value, String label, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: _text(20, FontWeight.w700, valueColor),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: _text(11, FontWeight.w400, _C.grey),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // DANH SÁCH CHUYẾN, NHÓM THEO NGÀY
  // =====================================================

  List<Widget> _buildContent(AsyncValue<List<TripHistoryItem>> async) {
    // Đang tải lần đầu
    if (async.isLoading && !async.hasValue) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    // Lỗi và chưa có dữ liệu cũ
    if (async.hasError && !async.hasValue) {
      return [_buildMessageCard(isError: true)];
    }

    final items = async.value ?? const <TripHistoryItem>[];

    if (items.isEmpty) {
      return [_buildMessageCard(isError: false)];
    }

    // Nhóm theo ngày, giữ nguyên thứ tự mới nhất trước
    final groups = <DateTime, List<TripHistoryItem>>{};
    for (final item in items) {
      groups.putIfAbsent(item.tripDate, () => []).add(item);
    }

    final widgets = <Widget>[];
    groups.forEach((date, trips) {
      widgets.add(_buildDayHeader(date));
      for (final trip in trips) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildTripCard(trip),
        ));
      }
    });

    return widgets;
  }

  Widget _buildDayHeader(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');

    final today = _today;
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;

    final label = isToday ? 'Hôm nay' : _weekdays[date.weekday - 1];

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Text(
        '$label · $dd/$mm',
        style: _text(13, FontWeight.w700, _C.grey),
      ),
    );
  }

  Widget _buildTripCard(TripHistoryItem trip) {
    final morning = trip.isMorning;

    final subtitle = [
      trip.timeRange,
      if (trip.attendanceText.isNotEmpty) trip.attendanceText,
    ].join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: morning ? _C.amberBadge : _C.blueLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              morning ? Icons.wb_sunny_outlined : Icons.wb_twilight,
              size: 24,
              color: morning ? _C.amberText : _C.blueText,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.title,
                  style: _text(14, FontWeight.w700, _C.navy),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _text(12, FontWeight.w400, _C.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildStatusBadge(trip),
        ],
      ),
    );
  }

  /// Ưu tiên: Đã huỷ > Có sự cố > Trễ giờ > Hoàn tất
  Widget _buildStatusBadge(TripHistoryItem trip) {
    final (String label, Color background, Color foreground) = trip.isCancelled
        ? ('Đã huỷ', _C.redBadge, _C.redText)
        : trip.hasIncident
            ? ('Có sự cố', _C.amberBadge, _C.amberText)
            : trip.isDelayed
                ? ('Trễ giờ', _C.amberBadge, _C.amberText)
                : ('Hoàn tất', _C.greenBadge, _C.greenText);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: _text(12, FontWeight.w600, foreground),
      ),
    );
  }

  Widget _buildMessageCard({required bool isError}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            isError ? Icons.wifi_off : Icons.history,
            size: 44,
            color: isError ? _C.redText : _C.chipBorder,
          ),
          const SizedBox(height: 12),
          Text(
            isError
                ? 'Không tải được lịch sử đưa đón'
                : 'Chưa có chuyến nào trong khoảng thời gian này',
            textAlign: TextAlign.center,
            style: _text(14, FontWeight.w700, _C.navy),
          ),
          if (isError) ...[
            const SizedBox(height: 4),
            Text(
              'Kiểm tra kết nối mạng và thử lại.',
              textAlign: TextAlign.center,
              style: _text(12, FontWeight.w400, _C.grey),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(tripHistoryProvider(_period)),
              child: const Text('Thử lại'),
            ),
          ],
        ],
      ),
    );
  }
}