import 'package:flutter_test/flutter_test.dart';
import 'package:quickplate/app.dart';

void main() {
  testWidgets('app launches to the splash screen', (tester) async {
    await tester.pumpWidget(const QuickPlateApp());

    expect(find.text('QuickPlate'), findsOneWidget);
  });
}
