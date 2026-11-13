import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// TODO: thay bằng thông tin thật của nhà trường.
const _schoolHotline = '02363000000';
const _schoolHotlineText = '0236 3 000 000';
const _schoolEmail = 'lienhe@truonghoc.edu.vn';

const _faqs = [
  (
    'Làm sao để liên kết với con?',
    'Vào Hồ sơ → "Liên kết thêm con", nhập mã học sinh do nhà trường cấp. '
        'Nhà trường sẽ duyệt yêu cầu, sau khi được duyệt con sẽ hiện trong ứng dụng.'
  ),
  (
    'Tôi có phải đăng ký khuôn mặt cho con không?',
    'Không. Nhà trường là bên đăng ký khuôn mặt. Bạn chỉ cần đồng ý (hoặc thu hồi '
        'đồng ý) trong Hồ sơ → chọn con → "Dữ liệu khuôn mặt".'
  ),
  (
    'Nếu thu hồi đồng ý thì sao?',
    'Dữ liệu khuôn mặt của con bị xóa khỏi hệ thống và việc điểm danh chuyển sang '
        'thủ công. Bạn có thể đồng ý lại bất cứ lúc nào.'
  ),
  (
    'Thông tin của con sai thì sửa ở đâu?',
    'Thông tin học sinh do nhà trường quản lý. Vui lòng liên hệ nhà trường để được '
        'chỉnh sửa.'
  ),
  (
    'Tôi có thể tắt cảnh báo khi con bị bỏ quên không?',
    'Bạn chỉ tắt được thông báo thường và âm báo. Cảnh báo khẩn vẫn luôn được gửi '
        'để đảm bảo an toàn cho con.'
  ),
];

class HelpContactPage extends StatelessWidget {
  const HelpContactPage({super.key});

  Future<void> _open(BuildContext context, Uri uri) async {
    var ok = false;
    try {
      ok = await launchUrl(uri);
    } catch (_) {}
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được ứng dụng tương ứng')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF5FF),
      appBar: AppBar(
        title: const Text('Trợ giúp & liên hệ nhà trường'),
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.phone_outlined, color: Color(0xFF1D4ED8)),
                  title: const Text('Gọi nhà trường'),
                  subtitle: const Text(_schoolHotlineText),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(context, Uri(scheme: 'tel', path: _schoolHotline)),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.mail_outline, color: Color(0xFF1D4ED8)),
                  title: const Text('Gửi email'),
                  subtitle: const Text(_schoolEmail),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(
                    context,
                    Uri(scheme: 'mailto', path: _schoolEmail, query: 'subject=Hỗ trợ ứng dụng đưa đón'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Câu hỏi thường gặp',
                style: TextStyle(
                    color: Color(0xFF52628A), fontSize: 13, fontWeight: FontWeight.w700)),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final f in _faqs)
                  ExpansionTile(
                    title: Text(f.$1,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.$2,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF3A4D75), height: 1.4)),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
