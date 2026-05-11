import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_lite/main.dart';
import 'package:word_lite/services/word_lite_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(<String, Object>{});

  testWidgets('应用能启动并显示标题', (WidgetTester tester) async {
    final WordLiteRepository repo = WordLiteRepository();
    await repo.init();
    await tester.pumpWidget(WordLiteApp(repository: repo));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('WordLite'), findsOneWidget);
  });
}
