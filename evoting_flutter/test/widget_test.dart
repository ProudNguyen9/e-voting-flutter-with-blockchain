import 'package:flutter_test/flutter_test.dart';

import 'package:evoting_flutter/main.dart';

void main() {
  testWidgets('Mặc định hiển thị trang đăng nhập', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Đăng nhập cử tri'), findsOneWidget);
    expect(find.text('Server URL'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
    expect(find.text('Qua trang đăng ký'), findsOneWidget);
  });

  testWidgets('Có thể mở trang đăng ký từ link', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    final registerLink = find.text('Qua trang đăng ký');
    await tester.ensureVisible(registerLink);
    await tester.tap(registerLink);
    await tester.pumpAndSettle();

    expect(find.text('Đăng ký cử tri'), findsNWidgets(2));
    expect(find.text('Họ và tên'), findsOneWidget);
    expect(find.text('Nhập lại mật khẩu'), findsOneWidget);
    expect(find.text('Quay lại đăng nhập'), findsOneWidget);
  });
}
