import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:mobile_app/features/alerts/domain/entities/incident_report.dart';
import 'package:mobile_app/features/alerts/presentation/providers/incident_provider.dart';
import 'package:mobile_app/features/trips/presentation/providers/trip_provider.dart';
import 'package:mobile_app/features/trips/presentation/widgets/route_palette.dart';

/// Màn "Báo cáo sự cố" của giáo viên.
/// - Biển số, tuyến, trip_id lấy từ chuyến hiện tại (teacherRouteDetailProvider)
/// - Gửi: tải ảnh lên Storage, lưu vào bảng alerts kèm GPS mới nhất của xe,
///   trigger trong DB tự gửi thông báo cho phụ huynh nếu bật công tắc.
class TeacherAlertsPage extends ConsumerStatefulWidget {
  const TeacherAlertsPage({super.key});

  @override
  ConsumerState<TeacherAlertsPage> createState() => _TeacherAlertsPageState();
}

class _TeacherAlertsPageState extends ConsumerState<TeacherAlertsPage> {
  // Màu theo Figma
  static const Color _bg = Color(0xFFEEF5FF);
  static const Color _header = Color(0xFF1D4ED8);
  static const Color _headerIcon = Color(0xFF1E40AF);
  static const Color _headerSub = Color(0xFFDBE8FF);
  static const Color _primary = Color(0xFF2563EB);
  static const Color _primarySoft = Color(0xFFE0ECFF);
  static const Color _navy = Color(0xFF10224A);
  static const Color _muted = Color(0xFF52628A);
  static const Color _cardBorder = Color(0xFFDDE6F5);
  static const Color _inputBorder = Color(0xFFC5D2EA);
  static const Color _addBorder = Color(0xFFB3C2E0);

  final TextEditingController _descController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<String> _photos = [];

  IncidentType _type = IncidentType.breakdown;
  IncidentSeverity _severity = IncidentSeverity.medium;
  bool _notifyParents = true;
  bool _submitting = false;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  // =========================================================
  // GIAO DIỆN THEO TỪNG LOẠI / MỨC ĐỘ
  // =========================================================

  IconData _iconOf(IncidentType t) => switch (t) {
        IncidentType.breakdown => Icons.build_outlined,
        IncidentType.traffic => Icons.traffic_outlined,
        IncidentType.accident => Icons.car_crash_outlined,
        IncidentType.studentSick => Icons.medical_services_outlined,
        IncidentType.lostItem => Icons.backpack_outlined,
        IncidentType.other => Icons.more_horiz,
      };

  Color _colorOf(IncidentSeverity s) => switch (s) {
        IncidentSeverity.low => const Color(0xFF16A34A),
        IncidentSeverity.medium => const Color(0xFFFFC93C),
        IncidentSeverity.high => const Color(0xFFF97316),
        IncidentSeverity.urgent => const Color(0xFFC8382F),
      };

  Color _onColorOf(IncidentSeverity s) =>
      s == IncidentSeverity.medium ? _navy : Colors.white;

  String _hm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // =========================================================
  // ẢNH ĐÍNH KÈM
  // =========================================================

  Future<void> _addPhoto() async {
    if (_photos.length >= IncidentReport.maxPhotos) {
      _snack('Chỉ được đính kèm tối đa ${IncidentReport.maxPhotos} ảnh.');
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Chụp ảnh'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final remaining = IncidentReport.maxPhotos - _photos.length;

    try {
      final List<String> picked;

      if (source == ImageSource.gallery && remaining > 1) {
        // Thư viện: cho chọn nhiều ảnh cùng lúc.
        final files = await _picker.pickMultiImage(
          imageQuality: 75,
          maxWidth: 1600,
        );
        picked = files.map((f) => f.path).toList();
      } else {
        // Camera, hoặc thư viện khi chỉ còn 1 chỗ trống.
        final file = await _picker.pickImage(
          source: source,
          imageQuality: 75,
          maxWidth: 1600,
        );
        picked = file == null ? <String>[] : [file.path];
      }

      if (picked.isEmpty || !mounted) return;

      // Bỏ ảnh trùng và không vượt quá số ảnh tối đa.
      final toAdd = picked
          .where((p) => !_photos.contains(p))
          .take(remaining)
          .toList();

      setState(() => _photos.addAll(toAdd));

      if (picked.length > remaining) {
        _snack('Chỉ thêm được $remaining ảnh (tối đa ${IncidentReport.maxPhotos} ảnh).');
      }
    } catch (_) {
      _snack('Không mở được camera hoặc thư viện ảnh.');
    }
  }

  // =========================================================
  // GỬI BÁO CÁO
  // =========================================================

  Future<void> _submit() async {
    if (_submitting) return;

    final detail = ref.read(teacherRouteDetailProvider).value;
    if (detail == null) {
      _snack('Hôm nay bạn chưa có chuyến xe nào.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);

    try {
      await ref.read(submitIncidentReportProvider)(
        IncidentReport(
          tripId: detail.tripId,
          type: _type,
          severity: _severity,
          description: _descController.text,
          notifyParents: _notifyParents,
          localPhotoPaths: List<String>.from(_photos),
        ),
      );

      if (!mounted) return;
      _snack('Đã gửi báo cáo sự cố');

      setState(() {
        _descController.clear();
        _photos.clear();
        _type = IncidentType.breakdown;
        _severity = IncidentSeverity.medium;
      });
    } on IncidentException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(teacherRouteDetailProvider).value;

    final subtitleParts = <String>[
      if (detail != null && detail.licensePlate.isNotEmpty)
        'Xe ${detail.licensePlate}',
      if (detail != null && detail.routeName.isNotEmpty) detail.routeName,
    ];
    final subtitle = subtitleParts.isEmpty
        ? 'Chưa có chuyến hôm nay'
        : subtitleParts.join(' · ');

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHeader(subtitle),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Loại sự cố'),
                    const SizedBox(height: 8),
                    _buildTypeGrid(),
                    const SizedBox(height: 12),
                    _label('Mức độ'),
                    const SizedBox(height: 8),
                    _buildSeverityRow(),
                    const SizedBox(height: 12),
                    _label('Mô tả'),
                    const SizedBox(height: 6),
                    _buildDescription(),
                    const SizedBox(height: 12),
                    _label('Ảnh đính kèm'),
                    const SizedBox(height: 8),
                    _buildPhotos(),
                    const SizedBox(height: 12),
                    _buildAutoInfoCard(),
                  ],
                ),
              ),
            ),
          ),
          _buildSubmitBar(canSubmit: detail != null),
        ],
      ),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildHeader(String subtitle) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: _header,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -8,
            child: Icon(
              Icons.directions_bus_rounded,
              size: 130,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: _headerIcon,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.report_problem_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Báo cáo sự cố',
                          style: RoutePalette.text(
                            20,
                            FontWeight.w700,
                            Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: RoutePalette.text(
                            13,
                            FontWeight.w400,
                            _headerSub,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(text, style: RoutePalette.text(13, FontWeight.w700, _navy));
  }

  // =========================================================
  // LOẠI SỰ CỐ
  // =========================================================

  Widget _buildTypeGrid() {
    const types = IncidentType.values;

    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: types.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: 76,
      ),
      itemBuilder: (_, i) {
        final type = types[i];
        final selected = type == _type;

        return GestureDetector(
          onTap: () => setState(() => _type = type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: selected ? _primarySoft : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? _primary : _cardBorder,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _iconOf(type),
                  size: 24,
                  color: selected ? _header : _muted,
                ),
                const SizedBox(height: 6),
                Text(
                  type.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: RoutePalette.text(
                    12,
                    FontWeight.w600,
                    selected ? _header : _navy,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // MỨC ĐỘ
  // =========================================================

  Widget _buildSeverityRow() {
    const values = IncidentSeverity.values;

    return Row(
      children: [
        for (var i = 0; i < values.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _buildSeverityChip(values[i])),
        ],
      ],
    );
  }

  Widget _buildSeverityChip(IncidentSeverity s) {
    final selected = s == _severity;

    return GestureDetector(
      onTap: () => setState(() => _severity = s),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 40,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? _colorOf(s) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: selected ? null : Border.all(color: _inputBorder),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            s.label,
            maxLines: 1,
            style: RoutePalette.text(
              13,
              FontWeight.w600,
              selected ? _onColorOf(s) : _navy,
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // MÔ TẢ
  // =========================================================

  Widget _buildDescription() {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );

    return TextField(
      controller: _descController,
      minLines: 2,
      maxLines: 4,
      maxLength: 500,
      textInputAction: TextInputAction.newline,
      style: RoutePalette.text(14, FontWeight.w400, _navy),
      decoration: InputDecoration(
        hintText: 'Mô tả ngắn gọn sự cố, vị trí, tình trạng...',
        hintStyle: RoutePalette.text(14, FontWeight.w400, _muted),
        counterText: '',
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        enabledBorder: border(_inputBorder),
        focusedBorder: border(_primary, 1.5),
      ),
    );
  }

  // =========================================================
  // ẢNH ĐÍNH KÈM
  // =========================================================

  Widget _buildPhotos() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < _photos.length; i++) _buildPhotoThumb(i),
        if (_photos.length < IncidentReport.maxPhotos)
          GestureDetector(
            onTap: _addPhoto,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _addBorder),
              ),
              child: const Icon(
                Icons.add_a_photo_outlined,
                size: 24,
                color: _muted,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPhotoThumb(int index) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                File(_photos[index]),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: Color(0xFFBFDDF7),
                  child: Icon(Icons.image_outlined, color: _muted),
                ),
              ),
            ),
          ),
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: () => setState(() => _photos.removeAt(index)),
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: _navy,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 13, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // THẺ TỰ ĐỘNG: GPS + THÔNG BÁO PHỤ HUYNH
  // =========================================================

  Widget _buildAutoInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.my_location, size: 18, color: _primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Vị trí GPS và giờ ${_hm(DateTime.now())} được đính kèm tự động',
                  style: RoutePalette.text(13, FontWeight.w400, _muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Switch(
                value: _notifyParents,
                onChanged: (v) => setState(() => _notifyParents = v),
                activeColor: Colors.white,
                activeTrackColor: _primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Thông báo cho phụ huynh trên chuyến',
                  style: RoutePalette.text(13, FontWeight.w400, _navy),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // NÚT GỬI BÁO CÁO
  // =========================================================

  Widget _buildSubmitBar({required bool canSubmit}) {
    final enabled = canSubmit && !_submitting;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Material(
        color: enabled ? _primary : _primary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled ? _submit : null,
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_submitting)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                else
                  const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  _submitting ? 'Đang gửi...' : 'Gửi báo cáo',
                  style: RoutePalette.text(16, FontWeight.w700, Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}