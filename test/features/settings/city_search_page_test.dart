import 'dart:async';

import 'package:ezan_vakti_uygulamasi/core/services/konum_servisi.dart';
import 'package:ezan_vakti_uygulamasi/core/vakit/vakit_modelleri.dart';
import 'package:ezan_vakti_uygulamasi/core/vakit/yer_bulucu.dart';
import 'package:ezan_vakti_uygulamasi/features/auth/auth_service.dart';
import 'package:ezan_vakti_uygulamasi/features/settings/city_search_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class _SahteAuth extends ChangeNotifier with Fake implements AuthService {
  @override
  String get uygulamaDili => 'Türkçe';
  @override
  String translate(String? text) => text ?? '';
}

const _tokyo = Konum(
    ad: 'Adachi-Ku',
    ulke: 'Japonya',
    saatDilimi: 'Asia/Tokyo',
    diyanetIlceId: 14707,
    enlem: 35.77,
    boylam: 139.80);

/// '/' → arama sayfası; sayfanın döndürdüğü değer [sonuc]a yazılır. Dünya
/// seçicisi yerine, [_tokyo]yu döndüren bir sahte sayfa vardır.
Future<ValueNotifier<Object?>> _ac(WidgetTester tester,
    {Future<Konum> Function()? konumBul}) async {
  final sonuc = ValueNotifier<Object?>(null);
  final router = GoRouter(routes: [
    GoRoute(
        path: '/',
        builder: (c, _) => Scaffold(
            body: Center(
                child: ElevatedButton(
                    onPressed: () async =>
                        sonuc.value = await c.push<Object>('/ara'),
                    child: const Text('ac'))))),
    GoRoute(
        path: '/ara', builder: (c, _) => CitySearchPage(konumBul: konumBul)),
    GoRoute(
        path: '/settings/cities/dunya',
        builder: (c, _) => Scaffold(
            body: Center(
                child: ElevatedButton(
                    onPressed: () => c.pop(_tokyo),
                    child: const Text('dunyadan-sec'))))),
  ]);
  await tester.pumpWidget(ChangeNotifierProvider<AuthService>.value(
      value: _SahteAuth() as AuthService,
      child: MaterialApp.router(routerConfig: router)));
  await tester.tap(find.text('ac'));
  await tester.pumpAndSettle();
  return sonuc;
}

/// Sonuç listesindeki bir satır (yazı kutusundaki metin sayılmaz).
Finder _sonucta(String ad) =>
    find.descendant(of: find.byType(ListView), matching: find.text(ad));

Future<void> _yaz(WidgetTester tester, String metin) async {
  await tester.enterText(find.byType(TextField), metin);
  await tester.pump();
}

void main() {
  testWidgets(
      'yazmadan önce yalnızca "Yurt Dışı" satırı görünür, il listesi boş',
      (tester) async {
    await _ac(tester);

    expect(find.text('Konumumu Kullan'), findsOneWidget);
    expect(find.text('Yurt Dışı (Tüm Ülkeler)'), findsOneWidget);
    expect(find.text('Ankara'), findsNothing);
  });

  testWidgets('Türkçe harfler ve büyük/küçük harf fark etmez', (tester) async {
    await _ac(tester);

    // Eski arama toLowerCase kullandığı için "istanbul" ile "İstanbul" bulunmuyordu.
    await _yaz(tester, 'istanbul');
    expect(_sonucta('İstanbul'), findsOneWidget);
    await _yaz(tester, 'İSTANBUL');
    expect(_sonucta('İstanbul'), findsOneWidget);

    for (final yazim in ['igdir', 'ığdır', 'IĞDIR', 'Iğdır']) {
      await _yaz(tester, yazim);
      expect(_sonucta('Iğdır'), findsOneWidget, reason: yazim);
    }
    await _yaz(tester, 'sanliurfa');
    expect(_sonucta('Şanlıurfa'), findsOneWidget);
  });

  testWidgets('sonuç satırına dokunmak il adını döndürür', (tester) async {
    final sonuc = await _ac(tester);

    await _yaz(tester, 'ankar');
    await tester.tap(find.text('Ankara'));
    await tester.pumpAndSettle();

    expect(sonuc.value, 'Ankara');
    expect(find.text('ac'), findsOneWidget, reason: 'sayfa kapanmalı');
  });

  testWidgets('hiçbir şeye uymayan yazı boş liste gösterir', (tester) async {
    await _ac(tester);

    await _yaz(tester, 'zzzz');

    expect(find.byType(ListTile),
        findsNWidgets(2)); // yalnızca "Konumumu Kullan" ve "Yurt Dışı"
  });

  testWidgets(
      'gönder: tam eşleşme ya da tek sonuç varsa kapanır, çok sonuçta kapanmaz',
      (tester) async {
    final sonuc = await _ac(tester);

    await _yaz(tester, 'an'); // birçok il
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(sonuc.value, isNull);
    expect(find.byType(CitySearchPage), findsOneWidget);

    await _yaz(tester, 'agri'); // tek sonuç: Ağrı
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(sonuc.value, 'Ağrı');
  });

  testWidgets('gönder: tam eşleşme (izmir → İzmir)', (tester) async {
    final sonuc = await _ac(tester);

    await _yaz(tester, 'izmir');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(sonuc.value, 'İzmir');
  });

  testWidgets('"Yurt Dışı": dünya seçicisinden gelen Konum aynen döner',
      (tester) async {
    final sonuc = await _ac(tester);

    await tester.tap(find.text('Yurt Dışı (Tüm Ülkeler)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('dunyadan-sec'));
    await tester.pumpAndSettle();

    expect(sonuc.value, _tokyo);
    expect(find.text('ac'), findsOneWidget,
        reason: 'arama sayfası da kapanmalı');
  });

  testWidgets('dünya seçicisinden vazgeçilirse arama sayfası açık kalır',
      (tester) async {
    final sonuc = await _ac(tester);

    await tester.tap(find.text('Yurt Dışı (Tüm Ülkeler)'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute(); // sistem geri tuşu
    await tester.pumpAndSettle();

    expect(sonuc.value, isNull);
    expect(find.byType(CitySearchPage), findsOneWidget);
  });

  group('Konumumu Kullan (GPS)', () {
    testWidgets('bulunan konum aynen döner ve sayfa kapanır', (tester) async {
      final sonuc = await _ac(tester, konumBul: () async => _tokyo);

      await tester.tap(find.text('Konumumu Kullan'));
      await tester.pumpAndSettle();

      expect(sonuc.value, _tokyo);
      expect(find.text('ac'), findsOneWidget);
    });

    testWidgets(
        'aranırken bekleme göstergesi çıkar; ikinci dokunuş ikinci arama başlatmaz',
        (tester) async {
      final bekle = Completer<Konum>();
      var cagri = 0;
      final sonuc = await _ac(tester, konumBul: () {
        cagri++;
        return bekle.future;
      });

      await tester.tap(find.text('Konumumu Kullan'));
      await tester.pump();

      expect(find.text('Konum bulunuyor...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.text('Konum bulunuyor...'));
      await tester.pump();
      expect(cagri, 1);

      bekle.complete(_tokyo);
      await tester.pumpAndSettle();
      expect(sonuc.value, _tokyo);
    });

    testWidgets(
        'izin reddedilirse uyarı çıkar, sayfa açık kalır, yeniden denenebilir',
        (tester) async {
      var deneme = 0;
      final sonuc = await _ac(tester, konumBul: () async {
        if (++deneme == 1) throw const KonumHatasi(KonumSorunu.izinReddedildi);
        return _tokyo;
      });

      await tester.tap(find.text('Konumumu Kullan'));
      await tester.pumpAndSettle();
      expect(find.text('Konum izni reddedildi.'), findsOneWidget);
      expect(find.byType(CitySearchPage), findsOneWidget);
      expect(find.text('Konumumu Kullan'), findsOneWidget,
          reason: 'bekleme göstergesi kalkmalı');

      await tester.tap(find.text('Konumumu Kullan'));
      await tester.pumpAndSettle();
      expect(sonuc.value, _tokyo);
    });

    testWidgets(
        'bir sonraki denemede eski uyarı silinir; başarıdan sonra uyarı asılı kalmaz',
        (tester) async {
      var deneme = 0;
      final sonuc = await _ac(tester, konumBul: () async {
        if (++deneme == 1) throw const KonumHatasi(KonumSorunu.izinReddedildi);
        return _tokyo;
      });

      await tester.tap(find.text('Konumumu Kullan'));
      await tester.pumpAndSettle();
      expect(find.text('Konum izni reddedildi.'), findsOneWidget);

      await tester.tap(find.text('Konumumu Kullan'));
      await tester.pumpAndSettle();

      expect(sonuc.value, _tokyo);
      expect(find.text('Konum izni reddedildi.'), findsNothing,
          reason: 'sayfa kapandıktan sonra ana ekranda eski uyarı kalmamalı');
    });

    testWidgets('konum servisi kapalıysa ilgili uyarı çıkar', (tester) async {
      await _ac(tester,
          konumBul: () async =>
              throw const KonumHatasi(KonumSorunu.servisKapali));

      await tester.tap(find.text('Konumumu Kullan'));
      await tester.pumpAndSettle();

      expect(find.text('Konum servisleri kapalı.'), findsOneWidget);
    });

    testWidgets('izin kalıcı reddedilmişse uyarıda "Ayarlar" eylemi de çıkar',
        (tester) async {
      await _ac(tester,
          konumBul: () async =>
              throw const KonumHatasi(KonumSorunu.izinKaliciReddedildi));

      await tester.tap(find.text('Konumumu Kullan'));
      await tester.pumpAndSettle();

      expect(find.text('Konum izni kalıcı olarak reddedildi.'), findsOneWidget);
      expect(find.text('Ayarlar'), findsOneWidget);
    });

    testWidgets(
        'yer eşleştirilemezse (ağ/Diyanet hatası) açıklayıcı uyarı çıkar',
        (tester) async {
      await _ac(tester,
          konumBul: () async =>
              throw YerBulucuHatasi('Diyanet yer listesine ulaşılamadı'));

      await tester.tap(find.text('Konumumu Kullan'));
      await tester.pumpAndSettle();

      expect(
          find.textContaining('Bu konum için yer bulunamadı'), findsOneWidget);
      expect(find.byType(CitySearchPage), findsOneWidget);
    });
  });
}
