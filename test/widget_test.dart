// This is a basic Flutter widget test.
import 'package:flutter_test/flutter_test.dart';
import 'package:commitly/app.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const CommitlyApp());
    await tester.pump();

    expect(find.text('Connect to Git Service'), findsOneWidget);
  });
}
