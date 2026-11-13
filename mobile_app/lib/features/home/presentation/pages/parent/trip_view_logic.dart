import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/features/home/data/models/parent_models.dart';
import 'package:mobile_app/features/home/presentation/pages/parent/home_theme.dart';

// =============================================================================
// Logic thuần (không dựng giao diện): dùng lại được cho trang Theo dõi và viết test.
// =============================================================================

// ---------------------------------------------------------------- tên / lời chào

List<String> _words(String s) =>
    s.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();

/// "Nguyễn Minh Anh" -> "MA" (an toàn với tên rỗng hoặc chỉ 1 chữ)
String nameInitials(String fullName) {
  final w = _words(fullName);
  if (w.isEmpty) return '?';
  if (w.length == 1) return w.first.characters.first.toUpperCase();
  return (w[w.length - 2].characters.first + w.last.characters.first).toUpperCase();
}

/// "Nguyễn Minh Anh" -> "Minh Anh"
String shortChildName(String fullName) {
  final w = _words(fullName);
  if (w.length <= 2) return fullName.trim();
  return '${w[w.length - 2]} ${w.last}';
}

String timeGreeting({DateTime? now}) {
  final h = (now ?? DateTime.now()).hour;
  if (h < 11) return 'Chào buổi sáng';
  if (h < 14) return 'Chào buổi trưa';
  if (h < 18) return 'Chào buổi chiều';
  return 'Chào buổi tối';
}

// ------------------------------------------------------- ước lượng thời gian tới

double distanceMeters(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371000.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return 2 * r * math.asin(math.sqrt(a));
}

class BusEta {
  const BusEta(this.minutes, this.arrived);
  final int minutes;
  final bool arrived;
}

/// Ước lượng thô: khoảng cách đường chim bay x 1.3 chia cho tốc độ hiện tại
/// (xe đứng yên hoặc chưa có tốc độ thì tính 25 km/h).
BusEta? estimateEta(GpsPoint? gps, double? lat, double? lng) {
  if (gps == null || lat == null || lng == null) return null;
  final meters = distanceMeters(gps.lat, gps.lng, lat, lng) * 1.3;
  if (meters < 150) return const BusEta(0, true);
  final kmh = (gps.speed != null && gps.speed! * 3.6 > 8) ? gps.speed! * 3.6 : 25.0;
  final minutes = (meters / 1000 / kmh * 60).ceil();
  return BusEta(minutes < 1 ? 1 : minutes, false);
}

// ----------------------------------------------------------- tóm tắt trạng thái

class TripSummary {
  const TripSummary(
    this.chip,
    this.chipBg,
    this.chipFg,
    this.big,
    this.bigColor,
    this.caption,
  );
  final String chip;
  final Color chipBg;
  final Color chipFg;
  final String big;
  final Color bigColor;
  final String caption;
}

TripSummary summarizeTrip(TodayTrip t, GpsPoint? gps, bool stale, String childName) {
  final hm = DateFormat('HH:mm');
  final name = shortChildName(childName);

  TripSummary s(String chip, Color bg, Color fg, String big, String caption,
          {Color? bigColor}) =>
      TripSummary(chip, bg, fg, big, bigColor ?? HomeColors.ink, caption);

  switch (t.attendanceStatus) {
    case 'ABSENT':
      return s('Nghỉ học', HomeColors.greySoft, HomeColors.muted, 'Vắng',
          'Điểm dừng của bé $name đã được bỏ khỏi lộ trình');
    case 'ALIGHTED':
      return s(
        'Đã xuống xe',
        HomeColors.greenSoft,
        HomeColors.greenText,
        t.checkOutTime == null ? 'An toàn' : hm.format(t.checkOutTime!),
        'Bé $name đã xuống xe an toàn',
      );
    case 'BOARDED':
      if (t.tripStatus == 'COMPLETED') {
        return s(
          'Chưa ghi nhận xuống xe',
          HomeColors.redSoft,
          HomeColors.redText,
          'Chưa xuống xe',
          'Chuyến đã kết thúc nhưng chưa ghi nhận bé $name xuống xe. Hãy liên hệ cô giáo ngay.',
          bigColor: HomeColors.red,
        );
      }
      if (stale) {
        return s('Mất tín hiệu GPS', HomeColors.redSoft, HomeColors.redText, '--',
            'Bé $name đang trên xe nhưng xe mất tín hiệu GPS');
      }
      final etaDrop = estimateEta(gps, t.dropoffLat, t.dropoffLng);
      return s(
        'Đang trên xe',
        HomeColors.blueSoft,
        HomeColors.primary,
        etaDrop == null ? 'Trên xe' : (etaDrop.arrived ? 'Sắp tới' : '${etaDrop.minutes} phút'),
        etaDrop == null
            ? 'Bé $name đang trên xe'
            : (etaDrop.arrived
                ? 'xe sắp tới điểm trả của bé $name'
                : 'nữa xe tới điểm trả của bé $name'),
      );
  }

  if (t.tripStatus == 'COMPLETED') {
    return s('Đã kết thúc', HomeColors.greySoft, HomeColors.muted, '—',
        'Bé $name chưa được điểm danh lên xe');
  }
  if (t.tripStatus == 'SCHEDULED') {
    return s('Chưa khởi hành', HomeColors.yellowSoft, HomeColors.yellowText,
        hm.format(t.startAt), 'giờ xe xuất phát');
  }

  // Xe đang chạy, bé chưa lên xe
  if (gps == null) {
    final plan = t.pickupEstimatedTime;
    if (plan != null) {
      return s('Xe đang chạy', HomeColors.yellowSoft, HomeColors.yellowText, plan,
          'giờ đón dự kiến · đang chờ tín hiệu GPS từ xe');
    }
    return s('Xe đang chạy', HomeColors.yellowSoft, HomeColors.yellowText, '--',
        'Đang chờ tín hiệu GPS từ xe');
  }
  if (stale) {
    return s('Mất tín hiệu GPS', HomeColors.redSoft, HomeColors.redText, '--',
        'Chưa nhận được vị trí xe trong hơn 1 phút');
  }
  final etaPickup = estimateEta(gps, t.pickupLat, t.pickupLng);
  if (etaPickup == null) {
    return s('Xe đang chạy', HomeColors.yellowSoft, HomeColors.yellowText, 'Đang chạy',
        'xe đang di chuyển trên tuyến');
  }
  if (etaPickup.arrived) {
    return s('Xe đã tới điểm đón', HomeColors.yellowSoft, HomeColors.yellowText, 'Đã tới',
        'xe đã tới điểm đón của bé $name');
  }
  return s(
    etaPickup.minutes <= 10 ? 'Sắp tới điểm đón' : 'Xe đang chạy',
    HomeColors.yellowSoft,
    HomeColors.yellowText,
    '${etaPickup.minutes} phút',
    'nữa xe tới điểm đón của bé $name',
  );
}

/// Tiến độ chuyến theo thời gian (0..1), dùng cho thanh xe chạy.
double tripProgress(TodayTrip t, {DateTime? now}) {
  if (t.tripStatus == 'COMPLETED') return 1;
  if (t.tripStatus == 'SCHEDULED') return 0;
  final total = t.endAt.difference(t.startAt).inSeconds;
  if (total <= 0) return 0.5;
  final f = (now ?? DateTime.now()).difference(t.startAt).inSeconds / total;
  return f.clamp(0.04, 0.96).toDouble();
}

// --------------------------------------------------------------- hành trình

enum TimelineStepState { done, current, pending }

class TimelineStep {
  const TimelineStep(this.title, this.time, this.state);
  final String title;
  final String? time;
  final TimelineStepState state;
}

List<TimelineStep> buildTripSteps(TodayTrip t) {
  final hm = DateFormat('HH:mm');
  final absent = t.attendanceStatus == 'ABSENT';
  final started = !absent && t.tripStatus != 'SCHEDULED';
  final boarded = !absent &&
      (t.attendanceStatus == 'BOARDED' ||
          t.attendanceStatus == 'ALIGHTED' ||
          t.checkInTime != null);
  final alighted = !absent && t.attendanceStatus == 'ALIGHTED';

  String? planned(String? hhmm) => hhmm == null ? null : 'dự kiến $hhmm';

  final steps = <TimelineStep>[
    TimelineStep('Xe xuất phát từ bãi', hm.format(t.startAt),
        started ? TimelineStepState.done : TimelineStepState.pending),
    TimelineStep(
      'Đón bé tại ${t.pickupStopName}',
      t.checkInTime != null ? 'lúc ${hm.format(t.checkInTime!)}' : planned(t.pickupEstimatedTime),
      boarded ? TimelineStepState.done : TimelineStepState.pending,
    ),
    TimelineStep(
      'Trả bé tại ${t.dropoffStopName}',
      t.checkOutTime != null ? 'lúc ${hm.format(t.checkOutTime!)}' : planned(t.dropoffEstimatedTime),
      alighted ? TimelineStepState.done : TimelineStepState.pending,
    ),
  ];

  // Bước đầu tiên chưa xong là bước đang diễn ra khi xe đang chạy.
  if (t.isActive && !absent) {
    final i = steps.indexWhere((s) => s.state != TimelineStepState.done);
    if (i >= 0) {
      steps[i] = TimelineStep(steps[i].title, steps[i].time, TimelineStepState.current);
    }
  }
  return steps;
}

/// Chuyến hiển thị mặc định: đang chạy > sắp chạy > chuyến cuối trong ngày.
TodayTrip pickFeaturedTrip(List<TodayTrip> trips) => trips.firstWhere(
      (t) => t.isActive,
      orElse: () => trips.firstWhere(
        (t) => t.tripStatus == 'SCHEDULED',
        orElse: () => trips.last,
      ),
    );

// ------------------------------------------------- dùng chung Trang chủ + Theo dõi

/// Quá số giây này không có điểm GPS mới thì coi là MẤT TÍN HIỆU (dùng 1 ngưỡng cho cả hai màn hình).
const int kGpsStaleSeconds = 60;

bool isGpsStale(GpsPoint? gps, {DateTime? now}) =>
    gps != null && (now ?? DateTime.now()).difference(gps.recordedAt).inSeconds > kGpsStaleSeconds;

/// 30 -> "30 giây trước", 150 -> "2 phút trước"
String agoLabel(int seconds) {
  if (seconds < 60) return '$seconds giây trước';
  if (seconds < 3600) return '${seconds ~/ 60} phút trước';
  return '${seconds ~/ 3600} giờ trước';
}

/// "Tuyến 05" (không bị lặp chữ "Tuyến" nếu tên tuyến đã có sẵn). null nếu chưa có tên/mã tuyến.
String? tripRouteLabel(TodayTrip t) {
  final name = (t.routeName != null && t.routeName!.trim().isNotEmpty) ? t.routeName!.trim() : t.routeCode;
  if (name == null || name.isEmpty) return null;
  return name.toLowerCase().startsWith('tuyến') ? name : 'Tuyến $name';
}
