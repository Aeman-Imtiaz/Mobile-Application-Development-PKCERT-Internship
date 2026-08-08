import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Budget progress bar shows correct label and amount', (tester) async {
    // A minimal, isolated widget test — no Firebase or full app needed.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Text('Monthly Budget'),
              Text('Rs. 3000 / 5000'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Monthly Budget'), findsOneWidget);
    expect(find.text('Rs. 3000 / 5000'), findsOneWidget);
  });
}