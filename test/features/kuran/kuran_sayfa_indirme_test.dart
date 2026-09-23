import 'dart:async';

import 'package:ezan_vakti_uygulamasi/features/kuran/data/sayfa_indirici.dart';
import 'package:ezan_vakti_uygulamasi/features/kuran/kuran_models.dart';
import 'package:ezan_vakti_uygulamasi/features/kuran/providers/kuran_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'kuran_test_yardimcilari.dart';

Future<(KuranProvider, SahteSayfalar)> _kur({int baslangic = 0}) async {
  SharedPreferences.setMockInitialValues({});
  final sayfalar = SahteSayfalar(baslangic: baslangic);
  final p = KuranProvider(
      repo: SahteDeposu(), audioPlayer: SahteOynatici(), sayfalar: sayfalar);
  await pumpEventQueue();
  return (p, sayfalar);
}

/// [sayfaNumaralari]'ndaki sayfalara dağılmış ayetlerle bir sure yükler
/// (`acikSayfalariIndir`'in `currentAyahs`tan hangi sayfaları istediğini
/// sınamak için).
Future<(KuranProvider, SahteSayfalar)> _sureAcik(List<int> sayfaNumaralari,
    {int baslangic = 0}) async {
  SharedPreferences.setMockInitialValues({});
  final sayfalar = SahteSayfalar(baslangic: baslangic, toplam: 20);
  final depo = SahteDeposu();
  depo.hazirSureler[1] = [
    for (var i = 0; i < sayfaNumaralari.length; i++)
      AyahModel(
          id: i + 1,
          verseKey: '1:${i + 1}',
          textUthmani: 'a',
          translation: 't',
          audioUrl: '',
          pageNumber: sayfaNumaralari[i]),
  ];
  final p = KuranProvider(
      repo: depo, audioPlayer: SahteOynatici(), sayfalar: sayfalar);
  await pumpEventQueue();
  await p.loadSurahDetails(p.surahs[0]);
  await pumpEventQueue();
  return (p, sayfalar);
}

void main() {
  test('sayfaDurumunuYukle cihazdaki sayıyı okur', () async {
    final (p, _) = await _kur(baslangic: 42);

    await p.sayfaDurumunuYukle();

    expect(p.sayfaCihazda, 42);
  });

  test('durum okunamazsa sayı korunur ve hata fırlamaz', () async {
    final (p, sayfalar) = await _kur(baslangic: 5);
    await p.sayfaDurumunuYukle();
    sayfalar.okumaHatasi = true;

    await p.sayfaDurumunuYukle();

    expect(p.sayfaCihazda, 5);
  });

  test('tumSayfalariIndir: ilerleme sayaca yansır, bitince indirme kapanır', () async {
    final (p, _) = await _kur(baslangic: 2);
    final sayilar = <int>[];
    p.addListener(() => sayilar.add(p.sayfaCihazda));

    await p.tumSayfalariIndir();

    expect(p.sayfaCihazda, 10);
    expect(p.sayfalarIndiriliyor, isFalse);
    expect(p.sayfaHatasi, isNull);
    expect(sayilar, [...sayilar]..sort(), reason: 'sayaç geri gitmez');
  });

  test('indirme sürerken tekrar başlatılamaz', () async {
    final (p, sayfalar) = await _kur();
    sayfalar.kapi = Completer<void>();

    final ilk = p.tumSayfalariIndir();
    await pumpEventQueue();
    expect(p.sayfalarIndiriliyor, isTrue);
    await p.tumSayfalariIndir(); // ikinci çağrı hemen döner
    expect(sayfalar.cagri, 1);

    sayfalar.kapi!.complete();
    await ilk;
    expect(p.sayfalarIndiriliyor, isFalse);
  });

  test('hata: kullanıcı metni (teknik ayrıntı yok), indirme kapanır; tekrar denenebilir', () async {
    final (p, sayfalar) = await _kur(baslangic: 3);
    sayfalar.hata = const SayfaIndirmeHatasi(4, 'HTTP 500 ağ ayrıntısı');

    await p.tumSayfalariIndir();

    expect(p.sayfaHatasi, 'Sayfa görselleri indirilemedi. İnternet bağlantınızı kontrol edip tekrar deneyin.');
    expect(p.sayfaHatasi, isNot(contains('HTTP')));
    expect(p.sayfalarIndiriliyor, isFalse);
    expect(p.sayfaCihazda, 3, reason: 'hata öncesi ilerleme korunur');

    sayfalar.hata = null;
    await p.tumSayfalariIndir();

    expect(p.sayfaHatasi, isNull, reason: 'yeni denemede eski hata temizlenir');
    expect(p.sayfaCihazda, 10);
  });

  test('sayfaIndirmesiniDurdur hata vermeden durdurur; sonra kalandan sürer', () async {
    final (p, _) = await _kur();
    var durdur = true;
    p.addListener(() {
      if (durdur && p.sayfaCihazda >= 4) p.sayfaIndirmesiniDurdur();
    });

    await p.tumSayfalariIndir();

    expect(p.sayfaCihazda, 4);
    expect(p.sayfaHatasi, isNull);
    expect(p.sayfalarIndiriliyor, isFalse);

    durdur = false;
    await p.tumSayfalariIndir();

    expect(p.sayfaCihazda, 10, reason: 'aynı sağlayıcı kaldığı yerden sürer');
  });

  test('yeni indirme, önceki durdurma isteğini sıfırlar', () async {
    final (p, sayfalar) = await _kur();
    p.sayfaIndirmesiniDurdur(); // indirme yokken gelen durdurma bir sonrakini etkilemez

    await p.tumSayfalariIndir();

    expect(p.sayfaCihazda, 10);
    expect(sayfalar.cagri, 1);
  });

  group('acikSayfalariIndir (yalnız açık sure/cüz/sayfanın görselleri)', () {
    test('yalnız currentAyahs\'taki sayfaları ister, tekrarsız', () async {
      final (p, sayfalar) = await _sureAcik([3, 3, 5, 4], baslangic: 10);

      await p.acikSayfalariIndir();

      expect(sayfalar.sonIstenenSayfalar!.toSet(), {3, 4, 5});
      expect(p.sayfaCihazda, 13, reason: '10 + 3 yeni sayfa');
      expect(p.sayfalarIndiriliyor, isFalse);
    });

    test('sure yüklenmeden çağrılırsa (currentAyahs boş) isteğe geçmez', () async {
      final (p, sayfalar) = await _kur(baslangic: 7);
      await p.sayfaDurumunuYukle();

      await p.acikSayfalariIndir();

      expect(sayfalar.cagri, 0);
      expect(p.sayfaCihazda, 7, reason: 'değişmedi');
    });

    test('tumSayfalariIndir sürerken çağrılırsa (aynı anda tek indirme) hemen döner', () async {
      final (p, sayfalar) = await _sureAcik([3, 4]);
      sayfalar.kapi = Completer<void>();

      final tumu = p.tumSayfalariIndir();
      await pumpEventQueue();
      expect(p.sayfalarIndiriliyor, isTrue);

      await p.acikSayfalariIndir();
      expect(sayfalar.cagri, 1, reason: 'ikinci istek atlanır');

      sayfalar.kapi!.complete();
      await tumu;
    });

    test('hata metni ve durum, tumSayfalariIndir ile aynı yolu (aynı alanları) kullanır', () async {
      final (p, sayfalar) = await _sureAcik([3, 4]);
      sayfalar.hata = const SayfaIndirmeHatasi(3, 'HTTP 500');

      await p.acikSayfalariIndir();

      expect(p.sayfaHatasi,
          'Sayfa görselleri indirilemedi. İnternet bağlantınızı kontrol edip tekrar deneyin.');
      expect(p.sayfalarIndiriliyor, isFalse);
    });
  });
}
