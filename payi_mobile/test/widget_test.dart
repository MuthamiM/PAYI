import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:payi_mobile/main.dart';
import 'package:payi_mobile/providers/wallet_provider.dart';

void main() {
  testWidgets('Dashboard smoke test', (WidgetTester tester) async {
    // Build the app with Provider
    // Build the app with Provider
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => WalletProvider()..fetchData()),
        ],
        child: const MaterialApp(home: DashboardSaaSScreen()),
      ),
    );

    // Wait for mock data to load
    await tester.pumpAndSettle();

    // Verify dashboard renders key elements
    // Verify dashboard renders key elements
    expect(find.text('Pay contacts or search...'), findsOneWidget);
    expect(find.text('Total Balance'), findsOneWidget);
    expect(find.text('People'), findsOneWidget);
  });
}
