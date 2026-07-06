import 'package:cukur_map/core/strings.dart';
import 'package:cukur_map/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app opens on camera tab with all four destinations',
      (tester) async {
    // Kamera/harita ekranları gerçek platform eklentileriyle (camera,
    // permission_handler) konuşur; bu çağrılar flutter test'in fake-async
    // zamanında hiç sonuçlanmaz, bu yüzden pumpAndSettle KULLANMA — sonsuz
    // CircularProgressIndicator animasyonunda zaman aşımına uğrar. Sekme
    // barı ilk frame'de statik olarak render olur, tek pump yeterli.
    await tester.pumpWidget(const ProviderScope(child: CukurMapApp()));
    await tester.pump();

    expect(find.text(Strings.tabCamera), findsOneWidget);
    expect(find.text(Strings.tabMap), findsOneWidget);
    expect(find.text(Strings.tabStats), findsOneWidget);
    expect(find.text(Strings.tabProfile), findsOneWidget);
  });
}
