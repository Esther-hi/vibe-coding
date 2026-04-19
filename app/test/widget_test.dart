import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_assistant/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: KitchenAssistantApp()));
    expect(find.text('智能厨房助手'), findsOneWidget);
  });
}
