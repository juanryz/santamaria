import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/shared/widgets/glass_alarm_overlay.dart';

void main() {
  group('GlassAlarmOverlay', () {
    testWidgets('renders title and message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GlassAlarmOverlay(
            title: 'Test Alarm',
            message: 'This is a test alarm message',
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Test Alarm'), findsOneWidget);
      expect(find.text('This is a test alarm message'), findsOneWidget);
    });

    testWidgets('shows order ID when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GlassAlarmOverlay(
            title: 'Alert',
            message: 'Message',
            orderId: 'SM-20260413-ABCD',
          ),
        ),
      );

      await tester.pump();

      expect(find.text('SM-20260413-ABCD'), findsOneWidget);
    });

    testWidgets('shows action button when onAction provided', (tester) async {
      bool actionCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: GlassAlarmOverlay(
            title: 'Alert',
            message: 'Message',
            onAction: () => actionCalled = true,
            actionLabel: 'Lihat Detail',
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Lihat Detail'), findsOneWidget);

      await tester.tap(find.text('Lihat Detail'));
      expect(actionCalled, isTrue);
    });

    testWidgets('dismiss button works', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showAlarmOverlay(
                context,
                title: 'Test',
                message: 'Dismissible',
              ),
              child: const Text('Show'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('Test'), findsOneWidget);

      await tester.tap(find.text('Tutup'));
      await tester.pumpAndSettle();

      expect(find.text('Test'), findsNothing);
    });
  });
}
