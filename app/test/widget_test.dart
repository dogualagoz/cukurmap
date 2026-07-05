import 'package:cukur_map/core/strings.dart';
import 'package:cukur_map/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app opens on camera tab with all four destinations',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CukurMapApp()));
    await tester.pumpAndSettle();

    expect(find.text(Strings.tabCamera), findsOneWidget);
    expect(find.text(Strings.tabMap), findsOneWidget);
    expect(find.text(Strings.tabStats), findsOneWidget);
    expect(find.text(Strings.tabProfile), findsOneWidget);
    expect(find.text(Strings.cameraComingSoon), findsOneWidget);
  });
}
