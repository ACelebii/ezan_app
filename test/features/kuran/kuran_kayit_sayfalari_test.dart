import 'dart:async';

import 'package:ezan_vakti_uygulamasi/core/utils/result.dart';
import 'package:ezan_vakti_uygulamasi/core/i18n/ek_ceviriler.dart';
import 'package:ezan_vakti_uygulamasi/features/auth/auth_service.dart';
import 'package:ezan_vakti_uygulamasi/features/kuran/data/kuran_kayitlari.dart';
import 'package:ezan_vakti_uygulamasi/features/kuran/data/kuran_repository.dart';
import 'package:ezan_vakti_uygulamasi/features/kuran/kuran_kayit_sayfalari.dart';
import 'package:ezan_vakti_uygulamasi/features/kuran/kuran_models.dart';
import 'package:ezan_vakti_uygulamasi/features/kuran/providers/kuran_provider.dart';
import 'package:ezan_vakti_uygulamasi/features/kuran/surah_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'kuran_test_yardimcilari.dart';

/// Gerçek ek sözlüğü kullanır ([ekCeviriEn]); dil "English" ise çevirir.
class _SahteAuth extends ChangeNotifier with Fake implements AuthService {
  _SahteAuth({this.ingilizce = false});

  final bool ingilizce;

  @override
  double get kuranYaziBoyutu => 28;
  @override
  String get uygulamaDili => ingilizce ? 'English' : 'Türkçe';
  @override
  String translate(String? text) =>
      text == null ? '' : (ingilizce ? ekCeviriEn(text) ?? text : text);
}

late List<SurahModel> _gercekSureler;

const _bakara4 = AyetKaydi(
    verseKey: '2:4', sureAdi: 'Bakara', arapca: 'ayet-4', meal: 'meal-4');

Future<(KuranProvider, SahteDeposu, SahteOynatici)> _kur(WidgetTester t,
    {bool gercekSureler = false, bool ingilizce = false}) async {
  final depo = SahteDeposu(sureler: gercekSureler ? _gercekSureler : null);
  final oynatici = SahteOynatici();
  final p = KuranProvider(
      repo: depo, audioPlayer: oynatici, ingilizceMi: () => ingilizce);
  await t.pump();
  return (p, depo, oynatici);
}

/// Bakara'yı [ayet] ayetle yükler (yükleme tamamlanır).
Future<void> _bakaraYukle(WidgetTester t, KuranProvider p, SahteDeposu depo,
    {int ayet = 6, int? ayetNo}) async {
  unawaited(p.loadSurahDetails(p.surahs[1], ayetNo: ayetNo));
  depo.sureIstekleri[2]!
      .complete(Success([for (var i = 1; i <= ayet; i++) sesliAyet(2, i)]));
  await t.pump();
  await t.pump();
}

/// Menüdeki bir özelliği (detay ekranı açıkmış gibi) açar.
Future<void> _ozellikAc(WidgetTester t, KuranProvider p, KuranOzelligi ozellik,
    {bool ingilizce = false}) async {
  await t.pumpWidget(ChangeNotifierProvider<AuthService>.value(
    value: _SahteAuth(ingilizce: ingilizce) as AuthService,
    child: MaterialApp(
      home: Builder(
        builder: (c) => Scaffold(
          body: TextButton(
              onPressed: () => kuranOzelligiAc(c, p, ozellik, detayAcik: true),
              child: const Text('ac')),
        ),
      ),
    ),
  ));
  await t.tap(find.text('ac'));
  await t.pumpAndSettle();
}

Future<void> _detayAc(WidgetTester t, KuranProvider p,
    {bool ingilizce = false}) async {
  await t.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider<KuranProvider>.value(value: p),
      ChangeNotifierProvider<AuthService>.value(
          value: _SahteAuth(ingilizce: ingilizce) as AuthService),
    ],
    child: const MaterialApp(home: SurahDetailPage()),
  ));
  await t.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    _gercekSureler = (await KuranRepository().getSurahs()).data!;
  });
  setUp(() => SharedPreferences.setMockInitialValues(
      {'kuran_page_style': 'Liste (Sure)'}));

  group('Fihrist', () {
    testWidgets(
        '114 sure: ad, iniş yeri, ayet sayısı, sayfa; dokununca sure açılır ve sayfa kapanır',
        (t) async {
      final (p, depo, _) = await _kur(t, gercekSureler: true);
      await _ozellikAc(t, p, KuranOzelligi.fihrist);

      expect(find.text('Fihrist'), findsOneWidget);
      expect(find.text('Fâtiha'), findsOneWidget);
      expect(find.text('Mekke  ·  7 ayet  ·  Sayfa 1'), findsOneWidget);

      await t.scrollUntilVisible(find.text('Nâs'), 400);
      expect(find.textContaining('6 ayet  ·  Sayfa 604'), findsOneWidget);
      await t.scrollUntilVisible(find.text('Bakara'), -400);
      await t.tap(find.text('Bakara'));
      await t.pumpAndSettle();

      expect(find.text('Fihrist'), findsNothing, reason: 'sayfa kapanır');
      expect(depo.sureIstekleri.keys, [2], reason: 'Bakara yüklenmeye başlar');
    });
  });

  group('Favori', () {
    testWidgets(
        'boş açıklama, kart, kalple çıkarma ve karta dokununca o ayete gitme',
        (t) async {
      final (p, depo, _) = await _kur(t);
      await _ozellikAc(t, p, KuranOzelligi.favori);
      expect(find.textContaining('Henüz favori ayet yok'), findsOneWidget);

      await p.kayitDegistir(_bakara4, favori: true);
      await t.pump();
      expect(find.text('Bakara  ·  2:4'), findsOneWidget);
      expect(find.text('meal-4'), findsOneWidget);
      expect(find.textContaining('Henüz favori ayet yok'), findsNothing);

      await t.tap(find.byTooltip('Favoriden çıkar'));
      await t.pump();
      expect(p.ayetKayitlari, isEmpty);
      expect(find.textContaining('Henüz favori ayet yok'), findsOneWidget);

      await p.kayitDegistir(_bakara4, favori: true);
      await t.pump();
      await t.tap(find.text('Bakara  ·  2:4'));
      await t.pumpAndSettle();
      expect(find.text('Favori Ayetler'), findsNothing,
          reason: 'sayfa kapanır');

      depo.sureIstekleri[2]!
          .complete(Success([for (var i = 1; i <= 6; i++) sesliAyet(2, i)]));
      await t.pump();
      expect(p.hedefAyetIndex, 3, reason: '2:4 = listedeki 4. ayet');
    });

    testWidgets('yalnızca notu olan ayet Favori sayfasında görünmez',
        (t) async {
      final (p, _, _) = await _kur(t);
      await p.kayitDegistir(_bakara4, not: 'sadece not');
      await _ozellikAc(t, p, KuranOzelligi.favori);

      expect(find.textContaining('Henüz favori ayet yok'), findsOneWidget);
    });
  });

  group('Not', () {
    testWidgets('boş açıklama; not karta gelir; düzenle, kaydet ve sil çalışır',
        (t) async {
      final (p, _, _) = await _kur(t);
      await _ozellikAc(t, p, KuranOzelligi.not);
      expect(find.textContaining('Henüz not yok'), findsOneWidget);

      await p.kayitDegistir(_bakara4, not: 'Çok önemli');
      await t.pump();
      expect(find.text('Çok önemli'), findsOneWidget);

      await t.tap(find.byTooltip('Notu düzenle'));
      await t.pumpAndSettle();
      expect(find.textContaining('Bakara 2:4 için not'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Çok önemli'), findsOneWidget);
      await t.enterText(find.byType(TextField), '  Ezberlenecek ');
      await t.tap(find.text('Kaydet'));
      await t.pumpAndSettle();
      expect(find.text('Ezberlenecek'), findsOneWidget,
          reason: 'boşluklar kırpılır');
      expect(p.ayetKayitlari.single.not, 'Ezberlenecek');

      await t.tap(find.byTooltip('Notu düzenle'));
      await t.pumpAndSettle();
      await t.tap(find.text('Notu Sil'));
      await t.pumpAndSettle();
      expect(find.textContaining('Henüz not yok'), findsOneWidget);
      expect(p.ayetKayitlari, isEmpty);
    });

    testWidgets('Vazgeç notu değiştirmez', (t) async {
      final (p, _, _) = await _kur(t);
      await p.kayitDegistir(_bakara4, not: 'eski');
      await _ozellikAc(t, p, KuranOzelligi.not);

      await t.tap(find.byTooltip('Notu düzenle'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'yeni');
      await t.tap(find.text('Vazgeç'));
      await t.pumpAndSettle();

      expect(p.ayetKayitlari.single.not, 'eski');
    });
  });

  group('Okuma listesi', () {
    testWidgets('sure ekle (aramayla), okundu işaretle, ilerleme, çıkar',
        (t) async {
      final (p, depo, _) = await _kur(t, gercekSureler: true);
      await _ozellikAc(t, p, KuranOzelligi.okumaListesi);
      expect(find.textContaining('Okuma listeniz boş'), findsOneWidget);

      await t.tap(find.byTooltip('Sure ekle'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'bakara');
      await t.pump();
      await t.tap(find.text('2. Bakara'));
      await t.pump();
      expect(p.okumaListesi.map((o) => o.sureId), [2]);
      expect(find.text('Eklenecek sure kalmadı.'), findsOneWidget,
          reason: 'eklenen sure seçiciden kalkar');

      await t.tapAt(const Offset(10, 10)); // sheet'i kapat
      await t.pumpAndSettle();
      expect(find.text('2. Bakara'), findsOneWidget);
      expect(find.text('0 / 1 sure okundu'), findsOneWidget);

      await t.tap(find.byType(Checkbox));
      await t.pump();
      expect(find.text('1 / 1 sure okundu'), findsOneWidget);

      await t.tap(find.byTooltip('Listeden çıkar'));
      await t.pump();
      expect(find.textContaining('Okuma listeniz boş'), findsOneWidget);

      await p.okumayaEkle(2);
      await t.pump();
      await t.tap(find.text('2. Bakara'));
      await t.pumpAndSettle();
      expect(depo.sureIstekleri.keys, [2],
          reason: 'satıra dokununca sure açılır');
    });
  });

  group('Ezberleme', () {
    testWidgets(
        'aralık ve tekrar seçilir, Başlat ses listesini kurar ve pencereyi kapatır',
        (t) async {
      final (p, depo, oynatici) = await _kur(t);
      await _bakaraYukle(t, p, depo);
      final onceki = oynatici.kurulanListeler.length;

      await _ozellikAc(t, p, KuranOzelligi.ezberleme);
      expect(find.text('Ezberleme  ·  Bakara Suresi'), findsOneWidget);
      expect(find.text('5 ayet x 3 = 15 çalma'), findsOneWidget);

      await t.tap(find.text('5'));
      await t.pump();
      expect(find.text('5 ayet x 5 = 25 çalma'), findsOneWidget);
      await t.tap(find.text('Başlat'));
      await t.pumpAndSettle();

      expect(find.text('Başlat'), findsNothing, reason: 'pencere kapanır');
      expect(oynatici.kurulanListeler.length, onceki + 1);
      expect(oynatici.kurulanListeler.last, hasLength(25));
      expect(p.ezberModu, isTrue);
    });

    testWidgets('açık sure yoksa önce sure açılması istenir', (t) async {
      final (p, _, _) = await _kur(t);
      await _ozellikAc(t, p, KuranOzelligi.ezberleme);

      expect(find.textContaining('önce bir sure, cüz ya da sayfa açın'),
          findsOneWidget);
    });

    testWidgets(
        'ezberleme açıkken "Ezberlemeyi Bitir" görünür ve tam listeyi geri getirir',
        (t) async {
      final (p, depo, _) = await _kur(t);
      await _bakaraYukle(t, p, depo);
      await p.ezberle(0, 1, 2);
      await _ozellikAc(t, p, KuranOzelligi.ezberleme);

      await t.tap(find.text('Ezberlemeyi Bitir'));
      await t.pumpAndSettle();

      expect(p.ezberModu, isFalse);
      expect(find.text('Ezberlemeyi Bitir'), findsNothing);
    });
  });

  group('Seslendirme', () {
    testWidgets('hafızlar listelenir; seçim uygulanır ve pencere kapanır',
        (t) async {
      final (p, _, _) = await _kur(t);
      await _ozellikAc(t, p, KuranOzelligi.seslendirme);

      expect(find.text('Seslendirme (Hafız)'), findsOneWidget);
      for (final ad in ['Abdul Basit', 'Mishary Alafasy', 'Husary', 'Südais']) {
        expect(find.text(ad), findsOneWidget);
      }
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);

      await t.tap(find.text('Mishary Alafasy'));
      await t.pumpAndSettle();

      expect(p.selectedHafizName, 'Mishary Alafasy');
      expect(find.text('Seslendirme (Hafız)'), findsNothing);
    });
  });

  group('Sure ekranındaki ayet listesi', () {
    testWidgets('kalp ve not düğmeleri ayete işlenir', (t) async {
      final (p, depo, _) = await _kur(t);
      await _detayAc(t, p);
      await _bakaraYukle(t, p, depo);

      await t.tap(find.byTooltip('Favorilere ekle').first);
      await t.pump();
      expect(p.favoriMi(p.currentAyahs[0]), isTrue);
      expect(find.byTooltip('Favoriden çıkar'), findsOneWidget);

      await t.tap(find.byTooltip('Not ekle').first);
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'Bu ayet güzel');
      await t.tap(find.text('Kaydet'));
      await t.pumpAndSettle();
      expect(find.text('Bu ayet güzel'), findsOneWidget);
      expect(find.byTooltip('Notu düzenle'), findsOneWidget);
      expect(p.ayetKayitlari.single.verseKey, '2:1');
      expect(p.ayetKayitlari.single.favori, isTrue);
    });

    testWidgets('Favori/Not\'tan gelince liste doğrudan o ayete kaydırılır',
        (t) async {
      final (p, depo, _) = await _kur(t);
      await _detayAc(t, p);
      await _bakaraYukle(t, p, depo, ayet: 60, ayetNo: 50);
      await t.pump();

      expect(find.textContaining('ayet-50 ﴿'), findsOneWidget);
      expect(find.textContaining('ayet-1 ﴿'), findsNothing,
          reason: 'liste başa değil, hedefe kaydırılmış');
      expect(p.hedefAyetIndex, isNull, reason: 'hedef bir kez kullanılır');
    });

    testWidgets('açık liste ayeteKaydir ile (Meal araması) istenen ayete kayar',
        (t) async {
      final (p, depo, _) = await _kur(t);
      await _detayAc(t, p);
      await _bakaraYukle(t, p, depo, ayet: 60);
      expect(find.textContaining('ayet-1 ﴿'), findsOneWidget);

      p.ayeteKaydir(49); // 0'dan sayılan sıra: 50. ayet
      await t.pump();
      await t.pump();

      expect(find.textContaining('ayet-50 ﴿'), findsOneWidget);
      expect(find.textContaining('ayet-1 ﴿'), findsNothing);
    });

    testWidgets('hedef yoksa liste baştan açılır', (t) async {
      final (p, depo, _) = await _kur(t);
      await _detayAc(t, p);
      await _bakaraYukle(t, p, depo, ayet: 60);

      expect(find.textContaining('ayet-1 ﴿'), findsOneWidget);
      expect(find.textContaining('ayet-50 ﴿'), findsNothing);
    });
    testWidgets(
        'ayetler yüklenemezse boş ekran değil açıklama ve Tekrar Dene görünür; Tekrar Dene yeniden yükler',
        (t) async {
      final (p, depo, _) = await _kur(t);
      await _detayAc(t, p);
      unawaited(p.loadSurahDetails(p.surahs[1]));
      depo.sureIstekleri[2]!.complete(Failure(
          'Sure ayetleri yüklenemedi. İnternet bağlantınızı kontrol edip tekrar deneyin.'));
      await t.pump();
      await t.pump();
      expect(find.textContaining('Ayetler yüklenemedi'), findsOneWidget);
      final ilkIstek = depo.sureIstekleri[2]!;

      await t.tap(find.text('Tekrar Dene'));
      await t.pump();
      expect(depo.sureIstekleri[2], isNot(same(ilkIstek)),
          reason: 'yeniden istek atılır');
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      depo.sureIstekleri[2]!
          .complete(Success([sesliAyet(2, 1), sesliAyet(2, 2)]));
      await t.pump();
      await t.pump();
      expect(find.textContaining('Ayetler yüklenemedi'), findsNothing);
      expect(find.textContaining('ayet-1 ﴿'), findsOneWidget);
    });
  });

  group('İngilizce meal', () {
    testWidgets(
        'sure ekranı: ayetin altında Saheeh International metni ve etiketi',
        (t) async {
      final (p, depo, _) = await _kur(t, ingilizce: true);
      await _detayAc(t, p, ingilizce: true);
      await _bakaraYukle(t, p, depo);

      expect(find.text('english-1'), findsOneWidget);
      expect(find.text('Saheeh International'), findsWidgets);
      expect(find.text('meal-1'), findsNothing);
    });

    testWidgets('Türkçe arayüzde Türkçe meal ve Diyanet etiketi', (t) async {
      final (p, depo, _) = await _kur(t);
      await _detayAc(t, p);
      await _bakaraYukle(t, p, depo);

      expect(find.text('meal-1'), findsOneWidget);
      expect(find.text('english-1'), findsNothing);
      expect(find.text('Diyanet'), findsWidgets);
    });

    testWidgets('Favori kartı İngilizce arayüzde İngilizce meali gösterir',
        (t) async {
      final (p, _, _) = await _kur(t, ingilizce: true);
      await p.kayitDegistir(
          const AyetKaydi(
              verseKey: '2:4',
              sureAdi: 'Bakara',
              arapca: 'ar',
              meal: 'türkçe meal',
              mealEn: 'english meal'),
          favori: true);
      await _ozellikAc(t, p, KuranOzelligi.favori, ingilizce: true);

      expect(find.text('english meal'), findsOneWidget);
      expect(find.text('türkçe meal'), findsNothing);
    });
  });

  group('İngilizce arayüz', () {
    testWidgets(
        'Fihrist: başlık, sure adı (Latin yazım), iniş yeri, ayet ve sayfa İngilizce',
        (t) async {
      final (p, _, _) = await _kur(t, gercekSureler: true, ingilizce: true);
      await _ozellikAc(t, p, KuranOzelligi.fihrist, ingilizce: true);

      expect(find.text('Index'), findsOneWidget);
      expect(find.text('Al-Fatihah'), findsOneWidget,
          reason: 'Türkçe "Fâtiha" değil');
      expect(find.text('Fâtiha'), findsNothing);
      expect(find.text('Makkah  ·  7 verses  ·  Page 1'), findsOneWidget);
    });

    testWidgets('boş Favori ve Not sayfaları İngilizce açıklama verir',
        (t) async {
      final (p, _, _) = await _kur(t, ingilizce: true);
      await _ozellikAc(t, p, KuranOzelligi.favori, ingilizce: true);
      expect(find.text('Favorite Verses'), findsOneWidget);
      expect(find.textContaining('No favorite verses yet.'), findsOneWidget);
      expect(find.textContaining('Henüz'), findsNothing);
    });

    testWidgets(
        'sure ekranı: başlık, ayet sayısı ve düğme ipuçları İngilizce; kayıtlı değerler Türkçe kalır',
        (t) async {
      final (p, depo, _) = await _kur(t, ingilizce: true);
      await _detayAc(t, p, ingilizce: true);
      await _bakaraYukle(t, p, depo);

      expect(find.text('Surah Sure2'), findsOneWidget,
          reason: 'sahte sureler nameSimple = Sure2');
      expect(find.text('6 Verses'), findsOneWidget);
      expect(find.byTooltip('Add to favorites'), findsWidgets);
      expect(find.byTooltip('Add note'), findsWidgets);
      expect(p.pageStyle, 'Liste (Sure)',
          reason: 'kayıtlı tercih Türkçe anahtar kalır');
    });

    testWidgets('yükleme hatası İngilizce açıklama gösterir', (t) async {
      final (p, depo, _) = await _kur(t, ingilizce: true);
      await _detayAc(t, p, ingilizce: true);
      unawaited(p.loadSurahDetails(p.surahs[1]));
      depo.sureIstekleri[2]!.complete(Failure(
          'Sure ayetleri yüklenemedi. İnternet bağlantınızı kontrol edip tekrar deneyin.'));
      await t.pump();
      await t.pump();

      expect(
          find.textContaining('Verses could not be loaded.'), findsOneWidget);
      // ('Tekrar Dene' düğmesi ana sözlükten çevrilir; sahte çeviri onu bilmez.)
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('Ezberleme ve Seslendirme pencereleri İngilizce', (t) async {
      final (p, depo, _) = await _kur(t, ingilizce: true);
      await _bakaraYukle(t, p, depo);
      await _ozellikAc(t, p, KuranOzelligi.ezberleme, ingilizce: true);
      expect(find.text('Memorization  ·  Surah Sure2'), findsOneWidget);
      expect(find.text('5 verses x 3 = 15 plays'), findsOneWidget);
      expect(find.text('Repeats per verse'), findsOneWidget);
      await t.tapAt(const Offset(10, 10)); // açık pencereyi kapat
      await t.pumpAndSettle();

      await _ozellikAc(t, p, KuranOzelligi.seslendirme, ingilizce: true);
      expect(find.text('Recitation (Reciter)'), findsOneWidget);
      expect(find.text('Sudais'), findsOneWidget, reason: 'Südais -> Sudais');
    });

    testWidgets('Okuma listesi İngilizce: ilerleme ve boş durum', (t) async {
      final (p, _, _) = await _kur(t, gercekSureler: true, ingilizce: true);
      await p.okumayaEkle(2);
      await p.okunduDegistir(2);
      await _ozellikAc(t, p, KuranOzelligi.okumaListesi, ingilizce: true);

      expect(find.text('Reading List'), findsOneWidget);
      expect(find.text('1 / 1 surahs read'), findsOneWidget);
      expect(find.text('2. Al-Baqarah'), findsOneWidget);
      expect(find.text('286 verses'), findsOneWidget);
    });
  });
}
