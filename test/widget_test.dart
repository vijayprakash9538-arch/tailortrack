import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tailor_track/main.dart';

void main() {
  testWidgets('App boots to the Home screen with the TailorTrack title', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: TailorTrackApp()));
    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pumpAndSettle();

    expect(find.text('TailorTrack'), findsWidgets);
  });
}
