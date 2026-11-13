import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/features/home/data/models/parent_models.dart';
import 'package:mobile_app/features/home/presentation/providers/parent_providers.dart';
import 'package:mobile_app/features/students/presentation/widgets/info_row.dart';
import 'package:mobile_app/features/students/data/datasources/student_api.dart';
import 'package:mobile_app/features/students/data/models/student_model.dart';
import 'package:mobile_app/features/students/presentation/pages/parent/edit_child_page.dart';
import 'package:mobile_app/features/students/presentation/pages/parent/register_face_page.dart';
import 'package:mobile_app/features/students/presentation/providers/student_providers.dart';
import 'package:mobile_app/features/students/presentation/widgets/face_state_style.dart';

const _consentText =
    'Nhà trường sử dụng vector đặc trưng khuôn mặt của con (không lưu ảnh gốc) '
    'chỉ để điểm danh lên/xuống xe buýt và cảnh báo khi trẻ bị bỏ quên. '
    'Bạn có thể thu hồi sự đồng ý bất cứ lúc nào; khi đó dữ liệu khuôn mặt '
    'của con sẽ bị xóa khỏi hệ thống và việc điểm danh chuyển sang thủ công.';

const _relationLabels = {
  'FATHER': 'Bố',
  'MOTHER': 'Mẹ',
  'GUARDIAN': 'Người giám hộ',
  'OTHER': 'Khác',
};

class ChildProfilePage extends ConsumerStatefulWidget {
  const ChildProfilePage({super.key, required this.child});
  final ChildInfo child;

  @override
  ConsumerState<ChildProfilePage> createState() => _ChildProfilePageState();
}

class _ChildProfilePageState extends ConsumerState<ChildProfilePage> {
  bool _busy = false;
  ChildInfo get child => widget.child;

  @override
  void initState() {
    super.initState();
    // Tự động làm mới dữ liệu và trạng thái khuôn mặt ngay khi mở trang
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAll();
    });
  }

  void _snack(String msg, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), action: action));
  }

  void _refreshAll() {
    ref.invalidate(childDetailProvider(child.studentId));
    ref.invalidate(childFaceStatusProvider(child.studentId));
    ref.invalidate(childProfileInfoProvider(child.studentId));
    ref.invalidate(faceConsentProvider(child.studentId));
    ref.invalidate(childrenProvider); // thẻ con ở tab Hồ sơ lấy ảnh/tên từ danh sách này
  }

  // ------------------------------------------------------- đồng ý / thu hồi

  Future<void> _toggle(bool grant) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(grant ? 'Đồng ý sử dụng khuôn mặt' : 'Thu hồi đồng ý'),
        content: Text(grant
            ? _consentText
            : 'Toàn bộ dữ liệu khuôn mặt của con sẽ bị xóa khỏi hệ thống và việc '
                'điểm danh tự động sẽ dừng. Bạn chắc chắn thu hồi?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(grant ? 'Đồng ý' : 'Thu hồi'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await StudentManageApi.setConsent(child.studentId, grant);
      _refreshAll();
      if (!mounted) return;
      if (grant) {
        _snack(
          'Đã ghi nhận sự đồng ý của bạn',
          action: SnackBarAction(label: 'Đăng ký ngay', onPressed: _openRegister),
        );
      } else {
        _snack('Đã thu hồi đồng ý và xóa dữ liệu khuôn mặt của con');
      }
    } catch (e) {
      if (!mounted) return;
      _snack(friendlyStudentError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // --------------------------------------------------------- mở các màn con

  Future<void> _openRegister() async {
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => RegisterFacePage(child: child)),
    );
    if (done == true) _refreshAll();
  }

  Future<void> _openEdit(ChildDetail d) async {
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EditChildPage(detail: d)),
    );
    if (done == true) _refreshAll();
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(childDetailProvider(child.studentId));
    final infoAsync = ref.watch(childProfileInfoProvider(child.studentId));
    final faceAsync = ref.watch(childFaceStatusProvider(child.studentId));

    final detail = detailAsync.asData?.value;
    final info = infoAsync.asData?.value;
    final name = detail?.fullName ?? child.fullName;
    final cls = detail?.className ?? child.className;
    final initial = name.trim().isEmpty
        ? '?'
        : String.fromCharCode(name.trim().runes.first).toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFEEF5FF),
      appBar: AppBar(
        title: const Text('Hồ sơ của con'),
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshAll(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            // ---- Thông tin học sinh
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  _Avatar(url: detail?.avatarUrl ?? child.avatarUrl, initial: initial),
                  const SizedBox(height: 12),
                  InfoRow(label: 'Họ tên', value: name),
                  InfoRow(label: 'Mã học sinh', value: detail?.studentCode ?? child.studentCode),
                  InfoRow(
                    label: 'Ngày sinh',
                    value: detail == null ? null : DateFormat('dd/MM/yyyy').format(detail.dateOfBirth),
                  ),
                  InfoRow(label: 'Giới tính', value: detail?.genderLabel),
                  InfoRow(label: 'Lớp', value: cls),
                  InfoRow(label: 'Quan hệ', value: _relationLabels[child.relationship]),
                  InfoRow(label: 'Tuyến xe', value: info?.routeName ?? 'Chưa được xếp tuyến'),
                  InfoRow(label: 'Điểm đón', value: info?.pickupAddress ?? info?.pickupStopName),
                  InfoRow(label: 'Điểm trả', value: info?.dropoffStopName),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: detail == null ? null : () => _openEdit(detail),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Sửa thông tin'),
                    ),
                  ),
                  if (detailAsync.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: InkWell(
                        onTap: () => ref.invalidate(childDetailProvider(child.studentId)),
                        child: const Text(
                          'Không tải được chi tiết · Bấm để thử lại',
                          style: TextStyle(color: Color(0xFFC8382F), fontSize: 12),
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  const Text(
                    'Bạn có thể sửa họ tên, ngày sinh, giới tính và lớp. Mã học sinh, '
                    'tuyến xe và điểm đón do nhà trường quản lý. Mọi thay đổi đều được ghi lại.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 16),

            // ---- Dữ liệu khuôn mặt
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: faceAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Không tải được trạng thái: $e'),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(childFaceStatusProvider(child.studentId)),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                  data: _faceCard,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _faceCard(FaceStatus s) {
    final state = faceStateOf(s);
    final style = faceStateStyle(state, samples: s.sampleCount);
    final fmt = DateFormat('dd/MM/yyyy HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(style.icon, color: style.fg),
          const SizedBox(width: 8),
          Text('Dữ liệu khuôn mặt', style: Theme.of(context).textTheme.titleMedium),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration:
              BoxDecoration(color: style.bg, borderRadius: BorderRadius.circular(10)),
          child: Text(style.chip,
              style: TextStyle(color: style.fg, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 12),

        // 3 bước: đồng ý -> phụ huynh chụp ảnh -> điểm danh tự động
        _Step(
          done: s.isGranted,
          text: s.isGranted && s.consentedAt != null
              ? '1. Bạn đồng ý (${DateFormat('dd/MM/yyyy').format(s.consentedAt!)})'
              : '1. Bạn đồng ý sử dụng khuôn mặt',
        ),
        _Step(done: s.hasFace, text: '2. Bạn chụp ảnh khuôn mặt của con'),
        _Step(done: s.hasFace, text: '3. Xe điểm danh tự động khi con lên/xuống xe'),
        const SizedBox(height: 10),
        Text(style.detail, style: const TextStyle(fontSize: 13)),

        if (s.hasFace) ...[
          const SizedBox(height: 8),
          Text(
            [
              if (s.enrolledAt != null) 'Đăng ký lúc ${fmt.format(s.enrolledAt!)}',
              if (s.enrolledBy != null) 'bởi ${s.enrolledBy}',
              '${s.sampleCount} ảnh mẫu',
            ].join(' · '),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
        // if (s.hasFace && s.modelName == 'DEV-FAKE') ...[
        //   const SizedBox(height: 8),
        //   Container(
        //     padding: const EdgeInsets.all(10),
        //     decoration: BoxDecoration(
        //       color: const Color(0xFFFEF3C7),
        //       borderRadius: BorderRadius.circular(10),
        //     ),
        //     child: const Text(
        //       'Đây là vector thử nghiệm (DEV-FAKE) để kiểm tra luồng đăng ký, '
        //       'chưa dùng để điểm danh thật.',
        //       style: TextStyle(fontSize: 12, color: Color(0xFF7A4A00)),
        //     ),
        //   ),
        // ],

        const SizedBox(height: 8),
        const Text(_consentText, style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 12),

        // Nút theo từng trạng thái
        if (state == FaceState.notConsented || state == FaceState.revoked)
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy ? null : () => _toggle(true),
              child: _busy
                  ? const _Spinner()
                  : Text(state == FaceState.revoked ? 'Đồng ý lại' : 'Đồng ý sử dụng'),
            ),
          ),
        if (state == FaceState.needFace) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _busy ? null : _openRegister,
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: const Text('Đăng ký khuôn mặt'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _busy ? null : () => _toggle(false),
              child: _busy ? const _Spinner() : const Text('Thu hồi đồng ý'),
            ),
          ),
        ],
        if (state == FaceState.ready) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _openRegister,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Đăng ký lại khuôn mặt'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFC8382F),
                side: const BorderSide(color: Color(0xFFC8382F)),
              ),
              onPressed: _busy ? null : () => _toggle(false),
              child: _busy ? const _Spinner() : const Text('Thu hồi đồng ý và xóa dữ liệu'),
            ),
          ),
        ],
      ],
    );
  }
}

/// Ảnh đại diện; ảnh không tải được thì hiện chữ cái đầu tên (không để vòng tròn trống).
class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.initial});
  final String? url;
  final String initial;

  @override
  Widget build(BuildContext context) {
    final fallback = CircleAvatar(
      radius: 36,
      backgroundColor: const Color(0xFF1D4ED8),
      child: Text(initial, style: const TextStyle(fontSize: 28, color: Colors.white)),
    );
    final u = url;
    if (u == null || u.isEmpty) return fallback;
    return ClipOval(
      child: Image.network(
        u,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.done, required this.text});
  final bool done;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 18, color: done ? Colors.green : Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 13,
                      color: done ? const Color(0xFF10224A) : Colors.grey.shade600)),
            ),
          ],
        ),
      );
}

class _Spinner extends StatelessWidget {
  const _Spinner();
  @override
  Widget build(BuildContext context) => const SizedBox(
      height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2));
}