import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/main.dart';

void main() {
  testWidgets('App loads login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const HabitTrackerApp());
    await tester.pumpAndSettle();
    expect(find.text('Log In'), findsOneWidget);
  });
}
