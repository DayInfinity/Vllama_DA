// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:vllama_da/main.dart';

void main() {
  testWidgets('App boots and shows Home', (WidgetTester tester) async {
    await tester.pumpWidget(const VllamaApp());
    await tester.pumpAndSettle();
    expect(find.text('Vllama'), findsOneWidget);
    expect(find.text('3D Model'), findsOneWidget);
  });
}
