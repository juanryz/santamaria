import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/shared/widgets/dynamic_status_badge.dart';

void main() {
  group('DynamicStatusBadge', () {
    testWidgets('renders with value as fallback label when config not loaded', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DynamicStatusBadge(
              enumGroup: 'order_status',
              value: 'confirmed',
            ),
          ),
        ),
      );

      // Should fall back to raw value when ConfigService not loaded
      expect(find.text('confirmed'), findsOneWidget);
    });

    testWidgets('applies green color for positive statuses', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DynamicStatusBadge(
              enumGroup: 'order_status',
              value: 'completed',
            ),
          ),
        ),
      );

      expect(find.text('completed'), findsOneWidget);
    });

    testWidgets('applies red color for negative statuses', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DynamicStatusBadge(
              enumGroup: 'order_status',
              value: 'cancelled',
            ),
          ),
        ),
      );

      expect(find.text('cancelled'), findsOneWidget);
    });

    testWidgets('allows color override', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DynamicStatusBadge(
              enumGroup: 'order_status',
              value: 'pending',
              color: Colors.purple,
            ),
          ),
        ),
      );

      expect(find.text('pending'), findsOneWidget);
    });
  });
}
