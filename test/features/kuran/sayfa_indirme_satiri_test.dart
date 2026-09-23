import 'dart:async';

import 'package:ezan_vakti_uygulamasi/core/i18n/ceviri.dart';
import 'package:ezan_vakti_uygulamasi/features/auth/auth_service.dart';
import 'package:ezan_vakti_uygulamasi/features/kuran/data/sayfa_indirici.dart';
import 'package:ezan_vakti_uygulamasi/features/kuran/kuran_models.dart';
import 'package:ezan_vakti_uygulamasi/features/kuran/providers/kuran_provider.dart';
import 'package:ezan_vakti_uygulamasi/features/kuran/surah_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'kuran_test_yardimcilari.dart';

class _SahteAuth extends ChangeNotifier with Fake implements AuthService {
  _SahteAuth({this.ingilizce = false});

  final bool ingilizce;

  @override
  String get uygulamaDili => ingilizce ? 'English' : 'Türkçe';
  @override
  String translate(String? text) => Ceviri.cevir(text, uygulamaDili);
}

Future<(KuranProvider, SahteSayfalar)> _ac(WidgetTester t,
    {int baslangic = 0, bool ingilizce = false, List<int>? acikSayfalar}) async {
  SharedPreferences.setMockInitialValues({});
  final sayfalar = SahteSayfalar(baslangic: baslangic, toplam: kuranSayfaSayisi);
  final depo = SahteDeposu();
  if (acikSayfalar != null) {
    depo.hazirSureler[1] = [
      for (var i = 0; i < acikSayfalar.length; i++)
        AyahModel(
            id: i + 1,
            verseKey: '1:${i + 1}',
            textUthmani: 'a',
            translation: 't',
            audioUrl: '',
            pageNumber: acikSayfalar[i]),
    ];
  }
  final p = KuranProvider(
      repo: depo,
      audioPlayer: SahteOynatici(),
      sayfalar: sayfalar,
      ingilizceMi: () => ingilizce);
  if (acikSayfalar != null) {
    await t.pump();
    await p.loadSurahDetails(p.surahs[0]);
  }
  await t.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthService>.value(
          value: _SahteAuth(ingilizce: ingilizce) as AuthService),
    ],
    child: MaterialApp(
      home: Scaffold(
          body: SayfaIndirmeSatiri(provider: p, txtColor: Colors.white)),
    ),
  ));
  await t.pumpAndSettle();
  return (p, sayfalar);
}

void main() {
  testWidgets('durum satırı cihazdaki sayıyı gösterir; hepsi inmediyse "Tümünü indir" vardır', (t) async {
    await _ac(t, baslangic: 12);

    expect(find.text('12 / 604 sayfa cihazda'), findsOneWidget);
    expect(find.text('Tümünü indir'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('604 sayfanın hepsi cihazdaysa düğme yoktur', (t) async {
    await _ac(t, baslangic: 604);

    expect(find.text('604 / 604 sayfa cihazda'), findsOneWidget);
    expect(find.text('Tümünü indir'), findsNothing);
  });

  testWidgets('düğme önce boyutu söyleyen bir onay sorar; Vazgeç indirmez', (t) async {
    final (_, sayfalar) = await _ac(t, baslangic: 10);

    await t.tap(find.text('Tümünü indir'));
    await t.pumpAndSettle();
    expect(find.text('Tüm sayfaları indir'), findsOneWidget);
    expect(find.textContaining('57 MB'), findsOneWidget);

    await t.tap(find.text('Vazgeç'));
    await t.pumpAndSettle();

    expect(sayfalar.cagri, 0);
    expect(find.text('10 / 604 sayfa cihazda'), findsOneWidget);
  });

  testWidgets('İndir: ilerleme çubuğu ve "Durdur" çıkar, bitince sayaç 604 olur ve düğme kalkar', (t) async {
    final (_, sayfalar) = await _ac(t, baslangic: 590);
    sayfalar.kapi = Completer<void>();

    await t.tap(find.text('Tümünü indir'));
    await t.pumpAndSettle();
    await t.tap(find.text('İndir'));
    await t.pump();
    await t.pump();

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Durdur'), findsOneWidget);
    expect(find.text('Tümünü indir'), findsNothing);

    sayfalar.kapi!.complete();
    await t.pumpAndSettle();

    expect(find.text('604 / 604 sayfa cihazda'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('Durdur'), findsNothing);
    expect(find.text('Tümünü indir'), findsNothing);
  });

  testWidgets('Durdur indirmeyi bırakır; kalan sayfalar için "Tümünü indir" geri gelir', (t) async {
    final (_, sayfalar) = await _ac(t, baslangic: 100);
    sayfalar.kapi = Completer<void>();

    await t.tap(find.text('Tümünü indir'));
    await t.pumpAndSettle();
    await t.tap(find.text('İndir'));
    await t.pump();
    await t.pump();
    await t.tap(find.text('Durdur'));
    sayfalar.kapi!.complete();
    await t.pumpAndSettle();

    expect(find.text('Durdur'), findsNothing);
    expect(find.text('Tümünü indir'), findsOneWidget);
    expect(find.textContaining('/ 604 sayfa cihazda'), findsOneWidget);
  });

  testWidgets('indirme hatası kırmızı, teknik ayrıntısız iletiyle gösterilir ve düğme geri gelir', (t) async {
    final (_, sayfalar) = await _ac(t, baslangic: 20);
    sayfalar.hata = const SayfaIndirmeHatasi(21, 'HTTP 503 ayrıntı');

    await t.tap(find.text('Tümünü indir'));
    await t.pumpAndSettle();
    await t.tap(find.text('İndir'));
    await t.pumpAndSettle();

    expect(
        find.text(
            'Sayfa görselleri indirilemedi. İnternet bağlantınızı kontrol edip tekrar deneyin.'),
        findsOneWidget);
    expect(find.textContaining('503'), findsNothing);
    expect(find.text('Tümünü indir'), findsOneWidget);
  });

  testWidgets('İngilizce arayüzde satır, onay penceresi ve hata İngilizce', (t) async {
    final (_, sayfalar) = await _ac(t, baslangic: 7, ingilizce: true);

    expect(find.text('7 / 604 pages on device'), findsOneWidget);
    expect(find.text('Download all'), findsOneWidget);

    await t.tap(find.text('Download all'));
    await t.pumpAndSettle();
    expect(find.text('Download all pages'), findsOneWidget);
    expect(find.textContaining('About 57 MB'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    sayfalar.hata = const SayfaIndirmeHatasi(8, 'x');
    await t.tap(find.text('Download'));
    await t.pumpAndSettle();
    expect(
        find.text(
            'Page images could not be downloaded. Check your internet connection and try again.'),
        findsOneWidget);
  });

  group('"Bu sayfaları indir" (yalnız açık sure/cüz/sayfa)', () {
    testWidgets('kitap tamamlanmadıysa "Tümünü indir" ile birlikte görünür, onaysız çalışır', (t) async {
      final (_, sayfalar) = await _ac(t, baslangic: 10, acikSayfalar: [3, 4, 5]);

      expect(find.text('Bu sayfaları indir'), findsOneWidget);
      expect(find.text('Tümünü indir'), findsOneWidget);

      await t.tap(find.text('Bu sayfaları indir'));
      await t.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing, reason: 'küçük indirme onay istemez');
      expect(sayfalar.sonIstenenSayfalar!.toSet(), {3, 4, 5});
      expect(find.text('13 / 604 sayfa cihazda'), findsOneWidget);
    });

    testWidgets('604 sayfanın hepsi cihazdaysa (açık sayfalar dahil) hiçbir indirme düğmesi yoktur', (t) async {
      await _ac(t, baslangic: 604, acikSayfalar: [3, 4]);

      expect(find.text('Bu sayfaları indir'), findsNothing);
      expect(find.text('Tümünü indir'), findsNothing);
    });

    testWidgets('indirirken ilerleme çubuğu ve Durdur çıkar; ikisi de kalkar', (t) async {
      final (_, sayfalar) = await _ac(t, baslangic: 10, acikSayfalar: [3, 4, 5]);
      sayfalar.kapi = Completer<void>();

      await t.tap(find.text('Bu sayfaları indir'));
      await t.pump();
      await t.pump();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Durdur'), findsOneWidget);
      expect(find.text('Bu sayfaları indir'), findsNothing);
      expect(find.text('Tümünü indir'), findsNothing);

      sayfalar.kapi!.complete();
      await t.pumpAndSettle();

      expect(find.text('13 / 604 sayfa cihazda'), findsOneWidget);
      expect(find.text('Durdur'), findsNothing);
    });

    testWidgets('İngilizce arayüzde düğme İngilizce', (t) async {
      await _ac(t, baslangic: 10, acikSayfalar: [3, 4], ingilizce: true);

      expect(find.text('Download these pages'), findsOneWidget);
    });
  });
}
