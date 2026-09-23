import 'package:ezan_vakti_uygulamasi/core/vakit/diyanet_kaynagi.dart';
import 'package:ezan_vakti_uygulamasi/core/vakit/vakit_modelleri.dart';
import 'package:ezan_vakti_uygulamasi/core/vakit/yer_bulucu.dart';
import 'package:ezan_vakti_uygulamasi/features/auth/auth_service.dart';
import 'package:ezan_vakti_uygulamasi/features/settings/dunya_yer_sec_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// AuthService'in kurucusu Firebase ister; sayfa yalnızca dil ve çeviriyi kullanır.
class _SahteAuth extends ChangeNotifier with Fake implements AuthService {
  @override
  String get uygulamaDili => 'Türkçe';

  @override
  String translate(String? text) => text ?? '';
}

const _abd = DiyanetYeri(
    id: 33, ad: 'AMERİKA BİRLEŞİK DEVLETLERİ', adEn: 'UNITED STATES');
const _almanya = DiyanetYeri(id: 13, ad: 'ALMANYA', adEn: 'GERMANY');
const _japonya = DiyanetYeri(id: 116, ad: 'JAPONYA', adEn: 'JAPAN');
const _kaliforniya = DiyanetYeri(id: 585, ad: 'CALIFORNIA', adEn: 'CALIFORNIA');
const _la = DiyanetYeri(id: 8626, ad: 'LOS ANGELES', adEn: 'LOS ANGELES');
const _adachi = DiyanetYeri(id: 14707, ad: 'ADACHI-KU', adEn: 'ADACHI-KU');

class _SahteDiyanet extends Fake implements DiyanetKaynagi {
  bool hataVer = false;

  @override
  Future<List<DiyanetYeri>> ulkeler() async {
    if (hataVer) throw DiyanetHatasi('kapalı');
    return const [_japonya, _abd, _almanya]; // karışık sıra: sayfa sıralar
  }

  @override
  Future<List<DiyanetYeri>> sehirler(int ulkeId) async => switch (ulkeId) {
        33 => const [
            _kaliforniya,
            DiyanetYeri(id: 586, ad: 'ALABAMA', adEn: 'ALABAMA')
          ],
        116 => const [
            DiyanetYeri(id: 1160, ad: 'JAPAN', adEn: 'JAPAN')
          ], // tek "şehir"
        _ => const [
            DiyanetYeri(id: 130, ad: 'BAYERN', adEn: 'BAYERN'),
            DiyanetYeri(id: 131, ad: 'HESSEN', adEn: 'HESSEN'),
          ],
      };

  @override
  Future<List<DiyanetYeri>> ilceler(int sehirId) async =>
      sehirId == 1160 ? const [_adachi] : const [_la];
}

class _SahteBulucu extends Fake implements YerBulucu {
  bool hataVer = false;
  final cagrilar = <String>[];

  @override
  Future<Konum> bul({
    required DiyanetYeri ulke,
    DiyanetYeri? sehir,
    required DiyanetYeri ilce,
  }) async {
    cagrilar.add('${ulke.id}/${sehir?.id}/${ilce.id}');
    if (hataVer) throw YerBulucuHatasi('bulunamadı');
    return Konum(
        ad: baslikYaz(ilce.ad),
        saatDilimi: 'America/Los_Angeles',
        diyanetIlceId: ilce.id,
        enlem: 34,
        boylam: -118);
  }
}

Future<ValueNotifier<Konum?>> _ac(
    WidgetTester tester, _SahteDiyanet diyanet, _SahteBulucu bulucu) async {
  final sonuc = ValueNotifier<Konum?>(null);
  final router = GoRouter(routes: [
    GoRoute(
        path: '/',
        builder: (c, _) => Scaffold(
            body: Center(
                child: ElevatedButton(
                    onPressed: () async =>
                        sonuc.value = await c.push<Konum>('/sec'),
                    child: const Text('ac'))))),
    GoRoute(
        path: '/sec',
        builder: (c, _) => DunyaYerSecPage(diyanet: diyanet, bulucu: bulucu)),
  ]);
  await tester.pumpWidget(ChangeNotifierProvider<AuthService>.value(
      value: _SahteAuth() as AuthService,
      child: MaterialApp.router(routerConfig: router)));
  await tester.tap(find.text('ac'));
  await tester.pumpAndSettle();
  return sonuc;
}

void main() {
  testWidgets('Ülke → eyalet → ilçe: seçilen yer Konum olarak döner',
      (tester) async {
    final bulucu = _SahteBulucu();
    final sonuc = await _ac(tester, _SahteDiyanet(), bulucu);

    // Ülkeler Türkçe yazılır ve alfabetik sıralanır.
    expect(find.text('Amerika Birleşik Devletleri'), findsOneWidget);
    final sira = ['Almanya', 'Amerika Birleşik Devletleri', 'Japonya']
        .map((a) => tester.getTopLeft(find.text(a)).dy)
        .toList();
    expect(sira, [...sira]..sort());

    await tester.tap(find.text('Amerika Birleşik Devletleri'));
    await tester.pumpAndSettle();
    expect(find.text('Şehir Seç'), findsOneWidget);
    expect(find.text('California'), findsOneWidget);

    await tester.tap(find.text('California'));
    await tester.pumpAndSettle();
    expect(find.text('İlçe Seç'), findsOneWidget);

    await tester.tap(find.text('Los Angeles'));
    await tester.pumpAndSettle();

    expect(bulucu.cagrilar, ['33/585/8626']);
    expect(sonuc.value?.diyanetIlceId, 8626);
    expect(find.text('ac'), findsOneWidget,
        reason: 'sayfa kapanıp geri dönmeli');
  });

  testWidgets(
      'tek şehirli ülkede şehir basamağı atlanır; geri ülke listesine döner',
      (tester) async {
    await _ac(tester, _SahteDiyanet(), _SahteBulucu());

    await tester.tap(find.text('Japonya'));
    await tester.pumpAndSettle();
    expect(find.text('İlçe Seç'), findsOneWidget);
    expect(find.text('Adachi-Ku'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Ülke Seç'), findsOneWidget,
        reason: 'şehir basamağında takılmamalı');
    expect(find.text('Japonya'), findsOneWidget);
  });

  testWidgets(
      'sistem geri tuşu bir basamak geri gider, en başta sayfayı kapatır',
      (tester) async {
    await _ac(tester, _SahteDiyanet(), _SahteBulucu());
    await tester.tap(find.text('Almanya'));
    await tester.pumpAndSettle();
    expect(find.text('Şehir Seç'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Ülke Seç'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('ac'), findsOneWidget);
  });

  testWidgets('arama, Türkçe ve İngilizce adla süzer', (tester) async {
    await _ac(tester, _SahteDiyanet(), _SahteBulucu());

    await tester.enterText(find.byType(TextField), 'germ');
    await tester.pump();
    expect(find.text('Almanya'), findsOneWidget);
    expect(find.text('Japonya'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    expect(find.text('Sonuç yok'), findsOneWidget);
  });

  testWidgets('konum bulunamazsa uyarı çıkar, sayfa açık kalır',
      (tester) async {
    final bulucu = _SahteBulucu()..hataVer = true;
    final sonuc = await _ac(tester, _SahteDiyanet(), bulucu);

    await tester.tap(find.text('Amerika Birleşik Devletleri'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('California'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Los Angeles'));
    await tester.pumpAndSettle();

    expect(find.textContaining('eklenemedi'), findsOneWidget);
    expect(find.text('İlçe Seç'), findsOneWidget);
    expect(sonuc.value, isNull);
  });

  testWidgets('liste alınamazsa hata ve "Tekrar Dene" çıkar', (tester) async {
    final diyanet = _SahteDiyanet()..hataVer = true;
    await _ac(tester, diyanet, _SahteBulucu());
    expect(find.text('Liste alınamadı.'), findsOneWidget);

    diyanet.hataVer = false;
    await tester.tap(find.text('Tekrar Dene'));
    await tester.pumpAndSettle();
    expect(find.text('Almanya'), findsOneWidget);
  });
}
