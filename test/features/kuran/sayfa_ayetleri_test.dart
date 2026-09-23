import 'dart:async';

import 'package:ezan_vakti_uygulamasi/core/i18n/ceviri.dart';
import 'package:ezan_vakti_uygulamasi/core/utils/result.dart';
import 'package:ezan_vakti_uygulamasi/features/auth/auth_service.dart';
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

/// Bakara: 1-2. ayet 1. sayfada, 3-5. ayet 2. sayfada, 6. ayet 3. sayfada.
AyahModel _ayet(int no) {
  final s = sesliAyet(2, no);
  return AyahModel(
      id: s.id,
      verseKey: s.verseKey,
      textUthmani: s.textUthmani,
      translation: s.translation,
      translationEn: s.translationEn,
      audioUrl: s.audioUrl,
      pageNumber: no <= 2 ? 1 : (no <= 5 ? 2 : 3));
}

Future<(KuranProvider, SahteOynatici)> _ac(WidgetTester t,
    {int sayfa = 2, bool ingilizce = false}) async {
  SharedPreferences.setMockInitialValues({});
  final depo = SahteDeposu();
  final oynatici = SahteOynatici();
  final p = KuranProvider(
      repo: depo, audioPlayer: oynatici, ingilizceMi: () => ingilizce);
  await t.pump();
  unawaited(p.loadSurahDetails(p.surahs[1]));
  depo.sureIstekleri[2]!.complete(Success([for (var i = 1; i <= 6; i++) _ayet(i)]));
  await t.pumpAndSettle();

  await t.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthService>.value(
          value: _SahteAuth(ingilizce: ingilizce) as AuthService),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SayfaAyetleri(
            provider: p,
            sayfa: sayfa,
            txtColor: Colors.white,
            arabicFontSize: 24),
      ),
    ),
  ));
  await t.pumpAndSettle();
  return (p, oynatici);
}

void main() {
  testWidgets('yalnız o sayfanın ayetlerini gösterir ve sayfa başlığı yazar', (t) async {
    await _ac(t, sayfa: 2);

    expect(find.text('Sayfa 2'), findsOneWidget);
    for (final no in [3, 4, 5]) {
      expect(find.textContaining('ayet-$no'), findsOneWidget, reason: '$no. ayet 2. sayfada');
    }
    for (final no in [1, 2, 6]) {
      expect(find.textContaining('ayet-$no '), findsNothing, reason: '$no. ayet başka sayfada');
    }
    expect(find.text('meal-3'), findsOneWidget);
  });

  testWidgets('kalp düğmesi favoriye ekler ve çıkarır (liste görünümündeki gibi)', (t) async {
    final (p, _) = await _ac(t, sayfa: 1);
    final ilk = p.currentAyahs.first;
    expect(p.favoriMi(ilk), isFalse);

    await t.tap(find.byIcon(Icons.favorite_border).first);
    await t.pumpAndSettle();

    expect(p.favoriMi(ilk), isTrue);
    expect(find.byIcon(Icons.favorite), findsOneWidget, reason: 'alt sayfa kendini yeniledi');

    await t.tap(find.byIcon(Icons.favorite));
    await t.pumpAndSettle();

    expect(p.favoriMi(ilk), isFalse);
  });

  testWidgets('ayete dokununca sayfa içindeki sıra değil, sure içindeki ayet çalınır', (t) async {
    final (p, oynatici) = await _ac(t, sayfa: 2);

    await t.tap(find.text('meal-4'));
    await t.pumpAndSettle();

    expect(p.activeAyahId, 2004, reason: '4. ayet (sure içinde sıra 3), sayfa içinde 2. sıradaydı');
    expect(oynatici.atlamalar.last, 3);
    expect(oynatici.oynatma, greaterThan(0));
  });

  testWidgets('not düğmesi (kalem) not penceresini açar', (t) async {
    await _ac(t, sayfa: 2);

    await t.tap(find.byIcon(Icons.edit_note).first);
    await t.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('İngilizce arayüzde başlık ve düğme ipuçları İngilizce', (t) async {
    await _ac(t, sayfa: 2, ingilizce: true);

    expect(find.text('Page 2'), findsOneWidget);
    expect(find.byTooltip('Add to favorites'), findsWidgets);
    expect(find.byTooltip('Add note'), findsWidgets);
    expect(find.text('english-3'), findsOneWidget, reason: 'İngilizce meal');
  });

  testWidgets('sayfada ayet yoksa boş liste (çökmez)', (t) async {
    await _ac(t, sayfa: 99);

    expect(find.text('Sayfa 99'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsNothing);
  });
}
