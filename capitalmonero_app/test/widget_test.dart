import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capitalmonero_app/config/app_theme.dart';
import 'package:capitalmonero_app/config/constants.dart';

void main() {
  testWidgets('App theme has correct colors', (WidgetTester tester) async {
    expect(AppColors.accent, const Color(0xFFE94560));
    expect(AppConstants.appName, 'CapitalMonero');
    expect(AppConstants.tradeFeePercent, 1.0);
    expect(CryptoCurrencies.btc, 'BTC');
    expect(CryptoCurrencies.xmr, 'XMR');
  });

  testWidgets('App renders without crashing', (WidgetTester tester) async {
    // Basic smoke test - just ensure MaterialApp can be created with our theme
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: Center(child: Text('CapitalMonero')),
        ),
      ),
    );
    expect(find.text('CapitalMonero'), findsOneWidget);
  });
}
