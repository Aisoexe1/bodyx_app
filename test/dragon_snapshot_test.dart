import 'package:flutter_test/flutter_test.dart';

import 'package:bodyx_app/models/models.dart';
import 'package:bodyx_app/widgets/pet/dragon_snapshot.dart';

void main() {
  testWidgets('renders a non-empty PNG for every pet stage',
      (WidgetTester tester) async {
    // Picture.toImage()'s completion comes from a real engine/rasterizer
    // callback, not a microtask testWidgets' fake-async zone can drain —
    // without runAsync() this just hangs forever waiting on it.
    await tester.runAsync(() async {
      for (final stage in PetStage.values) {
        final png = await renderDragonPng(stage, size: 64);
        expect(png, isNotEmpty);
        // A PNG file always starts with this 8-byte signature — cheap way
        // to confirm this is actually a decodable image, not random bytes.
        expect(png.take(8).toList(),
            [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
      }
    });
  });
}
