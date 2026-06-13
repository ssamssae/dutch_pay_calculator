import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dutch_pay_calculator/widgets/version_footer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'dutch_pay_calculator',
      packageName: 'com.daejongkang.dutchpay',
      version: '9.9.9',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  testWidgets('VersionFooter renders "v<version> · 강대종"', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: VersionFooter())),
    );
    await tester.pumpAndSettle();

    expect(find.text('v9.9.9 · 강대종'), findsOneWidget);
  });
}
