import 'package:ezan_vakti_uygulamasi/core/vakit/kayitli_sehir.dart';
import 'package:ezan_vakti_uygulamasi/core/vakit/vakit_modelleri.dart';
import 'package:ezan_vakti_uygulamasi/core/vakit/vakit_servisi.dart';
import 'package:ezan_vakti_uygulamasi/core/vakit/vakit_tercihi.dart';
import 'package:ezan_vakti_uygulamasi/features/auth/auth_service.dart';
import 'package:ezan_vakti_uygulamasi/features/settings/add_city_preview_page.dart';
import 'package:ezan_vakti_uygulamasi/locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

const _los = Konum(
    ad: 'Los Angeles',
    ulke: 'Amerika Birleşik Devletleri',
    saatDilimi: 'America/Los_Angeles',
    diyanetIlceId: 8626,
    enlem: 34.05,
    boylam: -118.24);

class _SahteAuth extends ChangeNotifier with Fake implements AuthService {
  _SahteAuth(this.kayitli);

  final List<KayitliSehir> kayitli;

  /// Kaydet'e basılınca yazılan şehir listesi.
  List<KayitliSehir>? kaydedilen;
  final guncellemeler = <String, dynamic>{};

  @override
  String get uygulamaDili => 'Türkçe';
  @override
  String translate(String? text) => text ?? '';
  @override
  String get hesaplamaYontemi => 'Diyanet Takvimi';
  @override
  VakitTercihi vakitTercihiIcin(String yontem) => const VakitTercihi();
  @override
  List<KayitliSehir> get kayitliSehirler => kayitli;
  @override
  Future<void> sehirleriKaydet(List<KayitliSehir> liste) async =>
      kaydedilen = liste;
  @override
  Future<void> updateSetting(String key, dynamic value) async =>
      guncellemeler[key] = value;
}

/// Hangi konum için vakit istendiyse onu kaydeder; saatler konuma göre değişir.
class _SahteServis extends Fake implements VakitServisi {
  final istenenler = <Konum>[];

  @override
  DateTime bugun(Konum konum) => DateTime.utc(2026, 9, 20);

  @override
  Future<List<GunlukVakit>> vakitleriGetir(Konum konum,
      [VakitTercihi tercih = const VakitTercihi()]) async {
    istenenler.add(konum);
    final la = konum.diyanetIlceId == 8626;
    final saatler = {
      Vakit.imsak: la ? '05:16' : '05:15',
      Vakit.gunes: '06:32',
      Vakit.ogle: la ? '12:52' : '13:03',
      Vakit.ikindi: '16:19',
      Vakit.aksam: '19:01',
      Vakit.yatsi: '20:08',
    };
    return [
      GunlukVakit(
        tarih: DateTime.utc(2026, 9, 20),
        kaynak: VakitKaynagi.diyanet,
        saatler: saatler,
        anlar: {for (final v in Vakit.values) v: DateTime.utc(2026, 9, 20, 12)},
      ),
    ];
  }
}

const _istanbul = KayitliSehir.varsayilan;
const _losKayit = KayitliSehir(
    isim: 'Los Angeles',
    ulke: 'Amerika Birleşik Devletleri',
    tur: 'Diyanet Takvimi',
    konum: _los);

/// '/' → önizleme; önizlemedeki "Değiştir" arama sayfasını açar. Sahte arama
/// sayfası, verilen sonucu (Konum ya da il adı) döndürür.
Future<_SahteAuth> _ac(WidgetTester tester, Object aramaSonucu,
    {List<KayitliSehir>? kayitli}) async {
  final auth = _SahteAuth(kayitli ?? [_istanbul]);
  final router = GoRouter(routes: [
    GoRoute(
        path: '/',
        builder: (c, _) => Scaffold(
            body: Center(
                child: ElevatedButton(
                    // Gerçek yığın: Şehirler sayfası → önizleme ("Kaydet" ikisini de kapatır).
                    onPressed: () {
                      c.push('/sehirler');
                      c.push('/onizleme');
                    },
                    child: const Text('ac'))))),
    GoRoute(
        path: '/sehirler',
        builder: (c, _) => const Scaffold(body: Text('sehirler'))),
    GoRoute(
        path: '/onizleme',
        builder: (c, _) =>
            const AddCityPreviewPage(baslangicSehri: 'İstanbul')),
    GoRoute(
        path: '/settings/cities/search',
        builder: (c, _) => Scaffold(
            body: Center(
                child: ElevatedButton(
                    onPressed: () => c.pop(aramaSonucu),
                    child: const Text('sonucu-sec'))))),
  ]);
  await tester.pumpWidget(ChangeNotifierProvider<AuthService>.value(
      value: auth as AuthService,
      child: MaterialApp.router(routerConfig: router)));
  await tester.tap(find.text('ac'));
  await tester.pumpAndSettle();
  return auth;
}

Future<void> _degistirVeSec(WidgetTester tester) async {
  await tester.tap(find.text('Değiştir'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('sonucu-sec'));
  await tester.pumpAndSettle();
}

void main() {
  late _SahteServis servis;

  setUp(() {
    servis = _SahteServis();
    locator.registerSingleton<VakitServisi>(servis);
  });
  tearDown(() => locator.reset());

  testWidgets(
      'dünya yeri seçilince o yerin vakitleri, ülkesi ve saat dilimi görünür',
      (tester) async {
    await _ac(tester, _los);
    expect(find.text('İstanbul'), findsOneWidget);
    expect(find.text('05:15'), findsOneWidget);

    await _degistirVeSec(tester);

    expect(find.text('Los Angeles'), findsOneWidget);
    expect(find.text('Amerika Birleşik Devletleri · America/Los_Angeles'),
        findsOneWidget);
    expect(find.text('05:16'), findsOneWidget);
    expect(find.text('12:52'), findsOneWidget);
    // Vakitler İstanbul koduyla değil, seçilen yerin Konum'uyla istendi.
    expect(servis.istenenler.last.diyanetIlceId, 8626);
    expect(servis.istenenler.last.saatDilimi, 'America/Los_Angeles');
  });

  testWidgets('Kaydet: yabancı yer tam konumuyla kaydedilir ve seçili olur',
      (tester) async {
    final auth = await _ac(tester, _los);
    await _degistirVeSec(tester);

    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    final liste = auth.kaydedilen!;
    expect(liste, hasLength(2));
    expect(liste.first.isim, 'İstanbul');
    expect(liste.first.secili, isFalse);
    final yeni = liste.last;
    expect(yeni.isim, 'Los Angeles');
    expect(yeni.ulke, 'Amerika Birleşik Devletleri');
    expect(yeni.tur, 'Diyanet Takvimi');
    expect(yeni.secili, isTrue);
    expect(yeni.kimlik, _losKayit.kimlik);
    // Depolanıp geri okununca aynı konum çıkar (ana ekran, bildirim, imsakiye
    // hep bunu kullanır); depolama biçimi eski kayıtlarla aynı.
    final geri = KayitliSehir.fromMap(yeni.toMap())!;
    expect(geri.konum.anahtar, _los.anahtar);
    expect(geri.konum.saatDilimi, 'America/Los_Angeles');
    expect(yeni.toMap()['secili'], 'true');
    // Hesaplama yöntemi de kaydedilir.
    expect(auth.guncellemeler['hesaplama_yontemi'], 'Diyanet Takvimi');
  });

  testWidgets('aynı yer ikinci kez eklenmez, yalnızca seçilir', (tester) async {
    final auth = await _ac(tester, _los, kayitli: [
      _istanbul,
      _losKayit
    ]); // Los Angeles zaten kayıtlı, seçili değil
    await _degistirVeSec(tester);
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    final liste = auth.kaydedilen!;
    expect(liste, hasLength(2));
    expect([for (final s in liste) s.secili], [false, true]);
  });

  testWidgets(
      'Türkiye\'deki il eskisi gibi kaydedilir (depolamada konum alanı yok)',
      (tester) async {
    final auth = await _ac(tester, 'Ankara');
    await _degistirVeSec(tester);
    expect(find.text('Ankara'), findsOneWidget);
    expect(find.text('Türkiye'), findsOneWidget);

    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    final yeni = auth.kaydedilen!.last;
    expect(yeni.isim, 'Ankara');
    expect(yeni.ulke, 'Türkiye');
    expect(yeni.toMap().containsKey('konum'), isFalse);
  });

  testWidgets(
      'GPS ile bulunan, Diyanet listesinde olmayan yerde "hesaplanır" notu çıkar; Diyanet yerinde çıkmaz',
      (tester) async {
    const westminster = Konum(
        ad: 'City of Westminster',
        ulke: 'United Kingdom',
        saatDilimi: 'Europe/London',
        enlem: 51.5,
        boylam: -0.13); // diyanetIlceId yok

    await _ac(tester, westminster);
    await _degistirVeSec(tester);
    expect(
        find.textContaining('Bu yer için Diyanet saati yok'), findsOneWidget);
    expect(find.text('United Kingdom · Europe/London'), findsOneWidget);
    expect(servis.istenenler.last.diyanetIlceId, isNull);
  });

  testWidgets('Diyanet ilçesi olan yerde (Los Angeles) not çıkmaz',
      (tester) async {
    await _ac(tester, _los);
    await _degistirVeSec(tester);

    expect(find.textContaining('Bu yer için Diyanet saati yok'), findsNothing);
  });
}
