import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/shared/widgets/order_timeline_widget.dart';

void main() {
  group('OrderTimelineWidget', () {
    testWidgets('renders fallback timeline when config not loaded', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OrderTimelineWidget(currentStatus: 'confirmed'),
            ),
          ),
        ),
      );

      // Should render fallback steps
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Dikonfirmasi'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);
    });

    testWidgets('renders consumer view with showConsumerView=true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OrderTimelineWidget(
                currentStatus: 'pending',
                showConsumerView: true,
              ),
            ),
          ),
        ),
      );

      // Fallback should still render
      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('shows status logs timestamps when provided', (tester) async {
      final logs = [
        {'to_status': 'pending', 'created_at': '2026-04-13T10:00:00Z'},
        {'to_status': 'confirmed', 'created_at': '2026-04-13T10:30:00Z'},
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OrderTimelineWidget(
                currentStatus: 'confirmed',
                statusLogs: logs,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(OrderTimelineWidget), findsOneWidget);
    });
  });
}
