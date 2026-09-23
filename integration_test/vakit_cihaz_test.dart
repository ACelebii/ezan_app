// Gerçek telefonda çalışan testler.
//
// test/ klasöründeki birim testleri bilgisayarda çalışır. Bu dosya aynı
// testleri telefonun kendi Dart motorunda çalıştırır. İleride internet,
// bildirim ve saat dilimi gibi yalnızca telefonda denenebilen testler de
// buraya eklenecek.
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/core/vakit/vakit_modelleri_test.dart' as vakit_modelleri;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('telefonun saat dilimi okunur', () {
    final simdi = DateTime.now();
    debugPrint('Telefonun saat dilimi: ${simdi.timeZoneName} '
        '(UTC${simdi.timeZoneOffset.isNegative ? '' : '+'}'
        '${simdi.timeZoneOffset.inMinutes / 60})');
    expect(simdi.timeZoneName, isNotEmpty);
  });

  vakit_modelleri.main();
}
