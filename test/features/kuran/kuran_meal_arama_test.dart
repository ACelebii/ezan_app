import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ezan_vakti_uygulamasi/core/i18n/ek_ceviriler.dart';
import 'package:ezan_vakti_uygulamasi/core/utils/result.dart';
import 'package:ezan_vakti_uygulamasi/core/utils/arama_metni.dart';
import 'package:ezan_vakti_uygulamasi/features/auth/auth_service.dart';
import 'package:ezan_vakti_uygulamasi/features/kuran/data/kuran_arama_indeksi.dart';
import 'package:ezan_vakti_uygulamasi/features/kuran/data/kuran_repository.dart';
import 'package:ezan_vakti_uygulamasi/features/kuran/providers/kuran_provider.dart';
import 'package:ezan_vakti_uygulamasi/features/kuran/surah_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'kuran_test_yardimcilari.dart';

class _SahteAuth extends ChangeNotifier with Fake implements AuthService {
  _SahteAuth({this.ingilizce = false});

  final bool ingilizce;

  @override
  String get uygulamaDili => ingilizce ? 'English' : 'Türkçe';
  @override
  String translate(String? text) =>
      text == null ? '' : (ingilizce ? ekCeviriEn(text) ?? text : text);
}

/// 114 sure: her birinde tek ayet.
Map<int, List<dynamic>> _tumSureler() => {
      for (var i = 1; i <= 114; i++)
        i: [aramaAyeti(i, 1, 'metin-$i', 'text-$i')],
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('arama metni (harf sadeleştirme)', () {
    test(
        'İngilizce mealdeki işaretli harfler sadeleşir: Allāh, Muḥammad, Ṣalāh',
        () {
      expect(aramaMetni('Allāh'), 'allah');
      expect(aramaMetni('Muḥammad'), 'muhammad');
      expect(aramaMetni('Ṣalāh, Zakāh, Ṭūr, Ḍuḥā, Ẓulm'),
          'salah, zakah, tur, duha, zulm');
      expect(aramaMetni('Allāh’s ʿAlī'), "allah's ali",
          reason: 'eğri kesme düzleşir, ayn işareti atılır');
    });

    test('Türkçe sadeleştirme değişmedi', () {
      expect(aramaMetni('İSTANBUL Fâtiha'), 'istanbul fatiha');
    });
  });

  group('KuranAramaIndeksi', () {
    late KuranAramaIndeksi indeks;
    setUp(() {
      indeks = KuranAramaIndeksi()
        ..sureEkle(2, [
          aramaAyeti(
              2,
              153,
              'Ey iman edenler! Sabır ve namazla yardım dileyin.',
              'O you who have believed, seek help through patience and prayer.'),
          aramaAyeti(2, 154, 'Allah yolunda öldürülenlere ölü demeyin.',
              'And do not say about those who are killed'),
        ])
        ..sureEkle(103, [
          aramaAyeti(103, 3, 'Birbirlerine sabır tavsiye ederler.',
              'and advised each other to patience.')
        ])
        ..sureEkle(1, [
          aramaAyeti(1, 1, 'Rahman ve Rahim olan Allah’ın adıyla.',
              'In the name of Allāh, the Entirely Merciful.')
        ]);
    });

    test('tüm surelerde arar; sonuçlar Mushaf sırasında; harf aksanı önemsiz',
        () {
      final sonuc = indeks.ara('SABIR', ingilizce: false);

      expect(sonuc.sonuclar.map((s) => s.verseKey), ['2:153', '103:3']);
      expect(sonuc.toplam, 2);
      expect(sonuc.sonuclar.first.kaynak, 'Diyanet');
      expect(sonuc.sonuclar.first.sureId, 2);
      expect(sonuc.sonuclar.first.ayetNo, 153);
    });

    test(
        'İngilizce arama İngilizce mealde çalışır ve Saheeh International etiketi verir',
        () {
      final sonuc = indeks.ara('patience', ingilizce: true);

      expect(sonuc.sonuclar.map((s) => s.verseKey), ['2:153', '103:3']);
      expect(sonuc.sonuclar.first.meal, startsWith('O you who have believed'));
      expect(sonuc.sonuclar.first.kaynak, 'Saheeh International');
      expect(indeks.ara('sabır', ingilizce: true).toplam, 0,
          reason: 'İngilizce modda Türkçe mealde aranmaz');
    });

    test('"allah" yazınca "Allāh" bulunur (İngilizce)', () {
      expect(
          indeks.ara('allah', ingilizce: true).sonuclar.map((s) => s.verseKey),
          ['1:1']);
    });

    test('birden çok sözcük: hepsi geçmeli, sıra önemsiz', () {
      expect(
          indeks
              .ara('namazla sabır', ingilizce: false)
              .sonuclar
              .map((s) => s.verseKey),
          ['2:153']);
      expect(indeks.ara('namazla zikir', ingilizce: false).toplam, 0);
    });

    test('ayet anahtarı ("2:154") tam eşleşir', () {
      final sonuc = indeks.ara('2:154', ingilizce: false);

      expect(sonuc.sonuclar.single.verseKey, '2:154');
      expect(indeks.ara('2:15', ingilizce: false).toplam, 0,
          reason: 'kısmi anahtar eşleşmez');
    });

    test(
        'boş sorgu sonuç vermez; İngilizce meali olmayan ayet Türkçeyle aranır',
        () {
      expect(indeks.ara('   ', ingilizce: false).toplam, 0);
      indeks.sureEkle(5, [aramaAyeti(5, 1, 'yalnız türkçe metin')]);

      final sonuc = indeks.ara('yalniz', ingilizce: true);
      expect(sonuc.sonuclar.single.verseKey, '5:1');
      expect(sonuc.sonuclar.single.kaynak, 'Diyanet');
    });

    test('sonuçlar 100 ile sınırlanır ama toplam sayı doğru verilir', () {
      indeks.sureEkle(7,
          [for (var i = 1; i <= 150; i++) aramaAyeti(7, i, 'ortak kelime $i')]);

      final sonuc = indeks.ara('ortak', ingilizce: false);

      expect(sonuc.toplam, 150);
      expect(sonuc.sonuclar, hasLength(KuranAramaIndeksi.enFazlaSonuc));
      expect(sonuc.sonuclar.last.ayetNo, 100);
    });

    test('sure yeniden eklenirse eskisinin yerini alır (çift sonuç olmaz)', () {
      indeks.sureEkle(103, [aramaAyeti(103, 3, 'yeni metin sabır')]);

      expect(
          indeks
              .ara('sabir', ingilizce: false)
              .sonuclar
              .where((s) => s.sureId == 103),
          hasLength(1));
      expect(indeks.sureSayisi, 3);
    });
  });

  group('Türkçe ünlü düşmesi ve alaka sıralaması', () {
    test(
        'unluDusmesi: sabır->sabr, akıl->akl, şehir->şehr, ömür->ömr; öteki sözcüklere dokunmaz',
        () {
      expect(unluDusmesi(aramaMetni('sabır')), ['sabr']);
      expect(unluDusmesi(aramaMetni('akıl')), ['akl']);
      expect(unluDusmesi(aramaMetni('şehir')), ['sehr']);
      expect(unluDusmesi(aramaMetni('ömür')), ['omr']);
      expect(unluDusmesi(aramaMetni('isim')), ['ism']);
      for (final w in ['kitap', 'namaz', 'bir', 'sabr', 'iman', 'allah']) {
        expect(unluDusmesi(w), isEmpty, reason: w);
      }
    });

    test('unluEkleme: sabr->sabir/sabur; ünsüz kümesi yoksa boş', () {
      expect(unluEkleme('sabr'), ['sabir', 'sabur']);
      expect(unluEkleme('akl'), isEmpty, reason: '3 harf: çok kısa');
      expect(unluEkleme('sabir'), isEmpty);
    });

    KuranAramaIndeksi kur(Map<String, String> metinler) {
      final i = KuranAramaIndeksi();
      var no = 0;
      i.sureEkle(
          2, [for (final e in metinler.entries) aramaAyeti(2, ++no, e.value)]);
      return i;
    }

    test('"sabır" yazınca sabrı, sabret, sabredenler de bulunur', () {
      final i = kur({
        'a': 'Sabrı tavsiye ederler.',
        'b': 'Sabredin, Allah sabredenlerle beraberdir.',
        'c': 'Ölçü tam olsun.',
        'd': 'Sabır ve namazla yardım dileyin.',
      });

      expect(
          i
              .ara('sabır', ingilizce: false)
              .sonuclar
              .map((s) => s.ayetNo)
              .toSet(),
          {1, 2, 4});
    });

    test('sonuç, aramada kullanılan sözcük biçimlerini taşır (vurgu için); ayet anahtarında boş', () {
      final i = kur({'a': 'Sabrı tavsiye ederler.', 'b': 'Sabır ve namaz'});

      final tr = i.ara('sabır', ingilizce: false).sonuclar.first.terimler;
      expect(tr, containsAll(['sabir', 'sabr']));

      final en = i.ara('sabır', ingilizce: true);
      expect(en.sonuclar.first.terimler, ['sabir'], reason: 'İngilizcede ünlü düşmesi yok');

      expect(i.ara('2:1', ingilizce: false).sonuclar.single.terimler, isEmpty);
    });

    test('İngilizcede ünlü düşmesi uygulanmaz', () {
      final i = kur({'a': 'the patience of Job', 'b': 'sabr'});

      expect(i.ara('sabir', ingilizce: true).toplam, 0);
    });

    test(
        'alaka: tam sözcük > sözcük başı > sözcük içi; eşitlikte Mushaf sırası',
        () {
      final i = kur({
        '1': 'xsabir gibi bir sözcük', // sözcük içi
        '2': 'sabırla bekleyin', // sözcük başı
        '3': 'yalnız sabır vardır', // tam sözcük
        '4': 'sabır sabır', // tam sözcük (eşit alaka, Mushaf'ta sonra)
      });

      expect(i.ara('sabır', ingilizce: false).sonuclar.map((s) => s.ayetNo),
          [3, 4, 2, 1]);
    });

    test('yazılan sözcükler ardışık geçiyorsa öne çıkar', () {
      final i = kur({
        '1': 'iman eden kişiler ve edenler', // ayrı geçiyor
        '2': 'iman edenler kurtuldu', // ardışık
      });

      expect(i.ara('iman edenler', ingilizce: false).sonuclar.first.ayetNo, 2);
    });

    test(
        'tam eşleşme yoksa sonu kırpılarak benzerleri bulunur ve yaklaşık diye işaretlenir',
        () {
      final i = kur({
        'a': 'Sabreden erkekler ve sabreden kadınlar',
        'b': 'Zekât verenler'
      });

      final sonuc = i.ara('sabredenler', ingilizce: false);

      expect(sonuc.sonuclar.map((s) => s.ayetNo), [1]);
      expect(sonuc.yaklasik, isTrue);
      expect(i.ara('sabreden', ingilizce: false).yaklasik, isFalse,
          reason: 'tam eşleşme yaklaşık değil');
    });

    test('yazılan ekli biçim de bulunur: "sabrı" -> sabır (ünlü geri konur)',
        () {
      final i = kur({'a': 'Sabır ve namaz', 'b': 'Zekât ver'});

      final sonuc = i.ara('sabrı', ingilizce: false);

      expect(sonuc.sonuclar.map((s) => s.ayetNo), [1]);
    });

    test('İngilizce: "patience" yazınca "patient" yaklaşık bulunur', () {
      final i = KuranAramaIndeksi()
        ..sureEkle(2, [
          aramaAyeti(2, 1, 'tr', 'be patient and pray'),
          aramaAyeti(2, 2, 'tr2', 'give charity')
        ]);

      final sonuc = i.ara('patience', ingilizce: true);

      expect(sonuc.sonuclar.map((s) => s.ayetNo), [1]);
      expect(sonuc.yaklasik, isTrue);
    });

    test(
        'kısa sözcüklerde (<=4 harf) yedek arama yapılmaz: "ve" yalnız geçtiği yeri bulur',
        () {
      final i = kur({'a': 'Rahman ve Rahim', 'b': 'iman'});

      final sonuc = i.ara('vex', ingilizce: false);

      expect(sonuc.toplam, 0);
      expect(sonuc.yaklasik, isFalse);
    });

    test(
        'yedek arama yalnız hiç sonuç yokken devreye girer (sonuç varken benzerler karışmaz)',
        () {
      final i = kur({'a': 'sabreden', 'b': 'sabredenler'});

      final sonuc = i.ara('sabredenler', ingilizce: false);

      expect(sonuc.sonuclar.map((s) => s.ayetNo), [2]);
      expect(sonuc.yaklasik, isFalse);
    });
  });

  group('KuranRepository: cihazdaki sureler', () {
    late Directory klasor;
    setUp(() {
      klasor = Directory.systemTemp.createTempSync('kuran_arama_');
      addTearDown(() => klasor.deleteSync(recursive: true));
    });

    KuranRepository depo({bool ag = true}) => KuranRepository(
        istemci: MockClient((istek) async {
          if (!ag) throw http.ClientException('internet yok');
          final v = <Map<String, dynamic>>[
            {
              'id': 1,
              'verse_key': '78:1',
              'text_uthmani': 'ar',
              'page_number': 1,
              'translations': [
                {'resource_id': 77, 'text': 'diyanet'},
                {'resource_id': 20, 'text': 'english'},
              ],
            }
          ];
          return http.Response.bytes(
              utf8.encode(jsonEncode({
                'verses': v,
                'pagination': {'next_page': null}
              })),
              200);
        }),
        onbellekKlasoru: klasor);

    test(
        'okunan sureler listelenir; cüz ve sayfa kayıtları sure sayılmaz; ağa çıkılmaz',
        () async {
      final d = depo();
      await d.getAyahsBySurah(78, 7);
      await d.getAyahsBySurah(2, 7);
      await d.getAyahsByJuz(30, 7);
      await d.getAyahsByPage(604, 7);

      final internetsiz = depo(ag: false);
      expect(await internetsiz.onbellekliSureler(), {2, 78});
      final ayetler = (await internetsiz.sureOnbellekten(78))!;
      expect((ayetler.single.translation, ayetler.single.translationEn),
          ('diyanet', 'english'));
    });

    test('kaydı olmayan sure için null döner ve ağa ÇIKMAZ', () async {
      var istek = 0;
      final d = KuranRepository(
          istemci: MockClient((_) async {
            istek++;
            return http.Response('{}', 200);
          }),
          onbellekKlasoru: klasor);

      expect(await d.sureOnbellekten(5), isNull);
      expect(await d.onbellekliSureler(), isEmpty);
      expect(istek, 0);
    });

    test('bozuk ya da eski sürüm dosyaları listede görünmez/okunmaz', () async {
      File('${klasor.path}/v2_sure_9.json').writeAsStringSync('bozuk');
      File('${klasor.path}/v1_sure_10.json').writeAsStringSync('{}');
      File('${klasor.path}/v2_cuz_3.json').writeAsStringSync('{}');

      final d = depo();
      expect(await d.onbellekliSureler(), {9},
          reason: 'liste dosya adına bakar');
      expect(await d.sureOnbellekten(9), isNull,
          reason: 'içerik bozuk: okunamaz');
    });
  });

  group('KuranProvider: tüm Kur\'an\'da meal arama', () {
    Future<(KuranProvider, SahteDeposu)> kur({bool ingilizce = false}) async {
      SharedPreferences.setMockInitialValues({});
      final depo = SahteDeposu();
      final p = KuranProvider(
          repo: depo,
          audioPlayer: SahteOynatici(),
          ingilizceMi: () => ingilizce);
      await pumpEventQueue();
      return (p, depo);
    }

    test('cihazdaki sureler indekslenir ve internetsiz aranır', () async {
      final (p, depo) = await kur();
      depo.onbellek[2] = [
        aramaAyeti(2, 153, 'Sabır ve namazla yardım dileyin.',
            'seek help through patience')
      ];
      depo.onbellek[103] = [
        aramaAyeti(
            103, 3, 'sabrı tavsiye ederler', 'advised each other to patience')
      ];

      await p.aramaIndeksiniHazirla();

      expect(p.aramadakiSureSayisi, 2);
      expect(p.aramaHazirlaniyor, isFalse);
      expect(p.mealAra('sabir').sonuclar.map((s) => s.verseKey),
          ['2:153', '103:3'],
          reason: 'tam sözcük (sabır) önce, ünlü düşmesi (sabrı) sonra');
      expect(p.mealAra('sabr').sonuclar.map((s) => s.verseKey), ['103:3']);
      expect(depo.indirilenler, isEmpty, reason: 'hazırlama ağa çıkmaz');
    });

    test('aramanın dili uygulama diliyle değişir', () async {
      var en = false;
      SharedPreferences.setMockInitialValues({});
      final depo = SahteDeposu()
        ..onbellek[2] = [
          aramaAyeti(2, 153, 'Sabır ve namazla', 'through patience and prayer')
        ];
      final p = KuranProvider(
          repo: depo, audioPlayer: SahteOynatici(), ingilizceMi: () => en);
      await pumpEventQueue();
      await p.aramaIndeksiniHazirla();

      expect(p.mealAra('sabir').toplam, 1);
      expect(p.mealAra('patience').toplam, 0);
      en = true;
      expect(p.mealAra('patience').toplam, 1);
      expect(p.mealAra('sabir').toplam, 0);
    });

    test(
        'Tümünü indir: eksik surelerin hepsini alır, olanları yeniden indirmez',
        () async {
      final (p, depo) = await kur();
      depo.onbellek[2] = [aramaAyeti(2, 1, 'var', 'exists')];
      depo.onbellek[3] = [aramaAyeti(3, 1, 'var', 'exists')];
      await p.aramaIndeksiniHazirla();
      for (final e in _tumSureler().entries) {
        depo.hazirSureler[e.key] = e.value.cast();
      }

      await p.tumKuraniIndir();

      expect(p.aramadakiSureSayisi, 114);
      expect(p.tumKuranIndiriliyor, isFalse);
      expect(p.indirmeHatasi, isNull);
      expect(depo.indirilenler, hasLength(112));
      expect(depo.indirilenler, isNot(contains(2)));
      expect(p.mealAra('metin-114').sonuclar.single.verseKey, '114:1');
    });

    test(
        'hata çıkarsa durur, mesajı gösterir; tekrar denenince kaldığı yerden devam eder',
        () async {
      final (p, depo) = await kur();
      for (final e in _tumSureler().entries) {
        depo.hazirSureler[e.key] = e.value.cast();
      }
      depo.hataSure = 50;

      await p.tumKuraniIndir();

      expect(p.aramadakiSureSayisi, 49);
      expect(p.indirmeHatasi, contains('İnternet bağlantınızı kontrol'));
      expect(p.tumKuranIndiriliyor, isFalse, reason: 'düğme yeniden görünmeli');

      depo.hataSure = null;
      depo.indirilenler.clear();
      await p.tumKuraniIndir();

      expect(p.aramadakiSureSayisi, 114);
      expect(p.indirmeHatasi, isNull);
      expect(depo.indirilenler.first, 50, reason: '1-49 yeniden indirilmez');
      expect(depo.indirilenler, hasLength(65));
    });

    test('indirme sürerken ikinci çağrı yok sayılır', () async {
      final (p, depo) = await kur();
      depo.hazirSureler[1] = [aramaAyeti(1, 1, 'a', 'a')];
      for (var i = 2; i <= 114; i++) {
        depo.hazirSureler[i] = [aramaAyeti(i, 1, 'a', 'a')];
      }

      final ilk = p.tumKuraniIndir();
      final ikinci = p.tumKuraniIndir();
      await Future.wait([ilk, ikinci]);

      expect(depo.indirilenler, hasLength(114), reason: 'her sure bir kez');
    });

    test('okunan sure de aramaya girer', () async {
      final (p, depo) = await kur();
      unawaited(p.loadSurahDetails(p.surahs[1]));
      depo.sureIstekleri[2]!
          .complete(Success([aramaAyeti(2, 1, 'benzersizkelime burada', 'x')]));
      await pumpEventQueue();

      expect(p.mealAra('benzersizkelime').sonuclar.single.verseKey, '2:1');
      expect(p.aramadakiSureSayisi, 1);
    });
  });

  group('arama sayfası (Meal sekmesi)', () {
    Future<(KuranProvider, SahteDeposu)> sayfayiAc(WidgetTester t,
        {bool ingilizce = false}) async {
      SharedPreferences.setMockInitialValues({});
      final depo = SahteDeposu(sureler: [
        sahteSure(1, 'Fâtiha'),
        sahteSure(2, 'Bakara'),
        sahteSure(103, 'Asr')
      ])
        ..onbellek[2] = [
          aramaAyeti(2, 153, 'Sabır ve namazla yardım dileyin.',
              'seek help through patience and prayer'),
        ]
        ..onbellek[103] = [
          aramaAyeti(103, 3, 'Birbirlerine sabır tavsiye ederler.',
              'advised each other to patience')
        ];
      final p = KuranProvider(
          repo: depo,
          audioPlayer: SahteOynatici(),
          ingilizceMi: () => ingilizce);
      await t.pump();
      await t.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(
              value: _SahteAuth(ingilizce: ingilizce) as AuthService),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (c) => Scaffold(
              body: TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                      context: c,
                      isScrollControlled: true,
                      builder: (_) => SearchBottomSheet(provider: p)),
                  child: const Text('ac')),
            ),
          ),
        ),
      ));
      await t.tap(find.text('ac'));
      await t.pumpAndSettle();
      return (p, depo);
    }

    testWidgets(
        'Meal sekmesi: durum satırı, tüm surelerde sonuçlar ve sonuca dokununca o ayete gider',
        (t) async {
      final (p, depo) = await sayfayiAc(t);

      await t.tap(find.text('Meal'));
      await t.pumpAndSettle();
      expect(find.text('2 / 114 sure cihazda'), findsOneWidget);
      expect(find.text('Tümünü indir'), findsOneWidget);
      expect(find.text('Aramak için yazın.'), findsOneWidget);

      await t.enterText(find.byType(TextField), 'sabır');
      await t.pumpAndSettle();
      expect(find.text('2 sonuç'), findsOneWidget);
      expect(find.text('Bakara  ·  2:153'), findsOneWidget);
      expect(find.text('Asr  ·  103:3'), findsOneWidget,
          reason: 'açık olmayan sure de bulunur');

      await t.tap(find.text('Asr  ·  103:3'));
      await t.pumpAndSettle();

      expect(find.byType(SearchBottomSheet), findsNothing,
          reason: 'pencere kapanır');
      expect(depo.sureIstekleri.keys, [103],
          reason: 'sure o ayette açılmak üzere yüklenir');
      expect(p.activeSurah!.id, 103);
    });

    /// Sonuç satırındaki [tam] metnin kalın (vurgulu) parçaları.
    List<String> vurgulu(WidgetTester t, String tam) {
      final w = t.widget<Text>(find.byWidgetPredicate(
          (w) => w is Text && w.textSpan?.toPlainText() == tam));
      return [
        for (final c in (w.textSpan! as TextSpan).children!)
          if ((c as TextSpan).style?.fontWeight == FontWeight.bold) c.text!
      ];
    }

    testWidgets(
        'sonuçta aranan sözcük vurgulanır (harf aksanı önemsiz, özgün yazım korunur)',
        (t) async {
      await sayfayiAc(t);
      await t.tap(find.text('Meal'));
      await t.pumpAndSettle();

      await t.enterText(find.byType(TextField), 'sabir');
      await t.pumpAndSettle();

      expect(vurgulu(t, 'Sabır ve namazla yardım dileyin.'), ['Sabır']);
      expect(vurgulu(t, 'Birbirlerine sabır tavsiye ederler.'), ['sabır']);
    });

    testWidgets('İngilizce arayüzde İngilizce mealde vurgulanır', (t) async {
      await sayfayiAc(t, ingilizce: true);
      await t.tap(find.text('Translation'));
      await t.pumpAndSettle();

      await t.enterText(find.byType(TextField), 'patience');
      await t.pumpAndSettle();

      expect(vurgulu(t, 'seek help through patience and prayer'), ['patience']);
    });

    testWidgets(
        'tam eşleşme yoksa benzer sözcükler gösterilir ve not düşülür; tam eşleşmede not yok',
        (t) async {
      await sayfayiAc(t);
      await t.tap(find.text('Meal'));
      await t.pumpAndSettle();

      await t.enterText(find.byType(TextField), 'sabırlar');
      await t.pumpAndSettle();
      expect(find.text('Tam eşleşme yok; benzer sözcükler gösteriliyor.'),
          findsOneWidget);
      expect(find.text('Bakara  ·  2:153'), findsOneWidget);

      await t.enterText(find.byType(TextField), 'sabır');
      await t.pumpAndSettle();
      expect(find.text('Tam eşleşme yok; benzer sözcükler gösteriliyor.'),
          findsNothing);
    });

    testWidgets('İngilizce arayüzde benzer sözcük notu İngilizce', (t) async {
      await sayfayiAc(t, ingilizce: true);
      await t.tap(find.text('Translation'));
      await t.pumpAndSettle();

      await t.enterText(find.byType(TextField), 'patiences');
      await t.pumpAndSettle();

      expect(
          find.text('No exact match; showing similar words.'), findsOneWidget);
    });

    testWidgets('sonuç yoksa açıklama; Git! ilk sonuca gider', (t) async {
      final (p, _) = await sayfayiAc(t);
      await t.tap(find.text('Meal'));
      await t.pumpAndSettle();

      await t.enterText(find.byType(TextField), 'olmayankelime');
      await t.pumpAndSettle();
      expect(find.text('Sonuç bulunamadı.'), findsOneWidget);

      await t.enterText(find.byType(TextField), 'sabır');
      await t.pumpAndSettle();
      await t.tap(find.text('Git!'));
      await t.pumpAndSettle();

      expect(p.activeSurah!.id, 2, reason: 'ilk sonuç: 2:153');
    });

    testWidgets('Tümünü indir: ilerleme görünür, bitince düğme kalkar',
        (t) async {
      final (p, depo) = await sayfayiAc(t);
      for (var i = 1; i <= 114; i++) {
        depo.hazirSureler[i] = [aramaAyeti(i, 1, 'metin-$i', 'text-$i')];
      }
      await t.tap(find.text('Meal'));
      await t.pumpAndSettle();

      await t.tap(find.text('Tümünü indir'));
      await t.pumpAndSettle();

      expect(p.aramadakiSureSayisi, 114);
      expect(find.text('114 / 114 sure cihazda'), findsOneWidget);
      expect(find.text('Tümünü indir'), findsNothing);
    });

    testWidgets(
        'indirme hatası kırmızı iletiyle gösterilir ve düğme geri gelir',
        (t) async {
      final (_, depo) = await sayfayiAc(t);
      for (var i = 1; i <= 114; i++) {
        depo.hazirSureler[i] = [aramaAyeti(i, 1, 'metin-$i', 'text-$i')];
      }
      depo.hataSure = 10;
      await t.tap(find.text('Meal'));
      await t.pumpAndSettle();

      await t.tap(find.text('Tümünü indir'));
      await t.pumpAndSettle();

      expect(
          find.textContaining('İnternet bağlantınızı kontrol'), findsOneWidget);
      expect(find.text('Tümünü indir'), findsOneWidget);
    });

    testWidgets(
        'İngilizce arayüz: İngilizce mealde arar, durum ve sonuç sayısı İngilizce',
        (t) async {
      await sayfayiAc(t, ingilizce: true);
      await t.tap(find.text('Translation'));
      await t.pumpAndSettle();

      expect(find.text('2 / 114 surahs on device'), findsOneWidget);
      expect(find.text('Download all'), findsOneWidget);
      expect(find.text('Type to search.'), findsOneWidget);

      await t.enterText(find.byType(TextField), 'patience');
      await t.pumpAndSettle();

      expect(find.text('2 results'), findsOneWidget);
      expect(find.textContaining('seek help through patience'), findsOneWidget);
      expect(find.textContaining('Sabır'), findsNothing,
          reason: 'İngilizce modda Türkçe meal görünmez');
    });
  });
}
