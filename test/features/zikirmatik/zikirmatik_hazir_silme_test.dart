import 'package:ezan_vakti_uygulamasi/features/zikirmatik/zikir.dart';
import 'package:ezan_vakti_uygulamasi/features/zikirmatik/zikirmatik_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
      'hazirdanSil: yalnız id\'li (kendi eklenen) zikri kalıcı siler; hazır zikirlere dokunmaz; kalıcıdır',
      () async {
    SharedPreferences.setMockInitialValues({});
    final p = ZikirmatikProvider();
    await pumpEventQueue();
    final fabrika = p.hazirZikirler.first; // id'siz
    p.zikirEkle(Zikir(id: '1', ad: 'Benim', hedef: 10, imame: 5));
    p.aktiftenKaldir(p.aktifZikirler.last);
    await pumpEventQueue();
    final adet = p.hazirZikirler.length;

    p.hazirdanSil(fabrika);
    expect(p.hazirZikirler.length, adet, reason: 'hazır zikir silinemez');

    p.hazirdanSil(p.hazirZikirler.last);
    await pumpEventQueue();
    expect(p.hazirZikirler.length, adet - 1);

    final yeni = ZikirmatikProvider(); // uygulama yeniden açıldı
    await pumpEventQueue();
    expect(yeni.hazirZikirler.any((z) => z.ad == 'Benim'), isFalse);
    expect(yeni.hazirZikirler.length, adet - 1);
  });
}
