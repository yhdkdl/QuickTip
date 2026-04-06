import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mobile/main.dart';
import 'package:mobile/core/auth/auth_provider.dart';

void main() {
  testWidgets('QuickTip app boots and shows splash', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const QuickTipApp(),
      ),
    );

    await tester.pump();

    expect(find.text('QuickTip'), findsOneWidget);

    // Dispose app and elapse splash delay so no timers remain pending.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 2000));
  });
}
