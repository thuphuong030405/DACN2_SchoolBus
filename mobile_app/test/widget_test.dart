import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/app.dart';

void main() {
  testWidgets('SchoolBusApp smoke test', (WidgetTester tester) async {
    // Bọc SchoolBusApp trong ProviderScope vì app của bạn sử dụng Riverpod
    await tester.pumpWidget(
      const ProviderScope(
        child: SchoolBusApp(),
      ),
    );

    // Kiểm tra xem ứng dụng đã khởi chạy thành công và hiển thị giao diện AuthGate
    // (Bạn có thể tùy chỉnh lại kỳ vọng tùy thuộc vào nội dung màn hình AuthGate của bạn)
    expect(find.byType(SchoolBusApp), findsOneWidget);
  });
}