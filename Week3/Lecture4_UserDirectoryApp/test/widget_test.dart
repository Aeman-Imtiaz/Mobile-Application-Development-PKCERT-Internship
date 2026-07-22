import 'package:flutter_test/flutter_test.dart';
import 'package:lecture4_public_api/main.dart';

void main() {
  testWidgets('User Directory App loads successfully',
      (WidgetTester tester) async {

    await tester.pumpWidget(
      const UserDirectoryApp(),
    );

    expect(find.text('User Directory'), findsOneWidget);
  });
}