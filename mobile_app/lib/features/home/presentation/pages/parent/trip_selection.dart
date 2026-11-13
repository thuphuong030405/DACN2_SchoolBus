import 'package:flutter_riverpod/flutter_riverpod.dart';


/// Chuyến mà phụ huynh đang chọn xem (sáng/chiều). Trang chủ và trang Theo dõi dùng CHUNG
/// để hai tab luôn hiển thị cùng một chuyến.
/// null = tự chọn chuyến phù hợp nhất (đang chạy > sắp chạy > chuyến cuối trong ngày).
/// Khi đăng xuất nhớ ref.invalidate(selectedTripIdProvider) như các provider chọn con.
class SelectedTripId extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? id) => state = id;
}

final selectedTripIdProvider =
    NotifierProvider<SelectedTripId, String?>(SelectedTripId.new);
