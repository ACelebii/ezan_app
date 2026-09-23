import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ezan_vakti_uygulamasi/core/utils/result.dart';
import 'package:ezan_vakti_uygulamasi/features/kuran/data/kuran_repository.dart';
import 'package:ezan_vakti_uygulamasi/features/kuran/kuran_models.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// UTF-8 gövde, başlıkta charset YOK (gerçek API gibi Türkçe harfler bozulmamalı).
http.Response _yanit(Object govde, [int kod = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(govde)), kod);

/// API'nin ayet biçimi: Diyanet (77) ve Elmalılı (52) çevirisi birlikte.
Map<String, dynamic> _ayetJson(String anahtar,
        {String diyanet = 'Diyanet metni',
        String elmali = 'Elmalılı metni',
        String ingilizce = 'English meal',
        int sayfa = 582}) =>
    {
      'id': anahtar.hashCode.abs() % 100000,
      'verse_key': anahtar,
      'text_uthmani': 'ar-$anahtar',
      'page_number': sayfa,
      'translations': [
        {'resource_id': 52, 'text': elmali},
        {'resource_id': 20, 'text': ingilizce},
        {'resource_id': 77, 'text': diyanet},
      ],
    };

Map<String, dynamic> _ayet(int no, {String ceviri = 'Meal'}) =>
    _ayetJson('78:$no', diyanet: ceviri);

Map<String, dynamic> _sayfa(int bas, int adet, {int? sonraki}) => {
      'verses': [for (var i = 0; i < adet; i++) _ayet(bas + i)],
      'pagination': {
        'per_page': 500,
        'next_page': sonraki,
        'total_records': 564
      },
    };

Map<String, dynamic> _sayfaAyetlerden(List<Map<String, dynamic>> ayetler) => {
      'verses': ayetler,
      'pagination': {'per_page': 500, 'next_page': null},
    };

/// Her çağrıda yeni geçici önbellek klasörü (ya da verilen).
KuranRepository _repo(FutureOr<http.Response> Function(http.Request) yanit,
    {Duration zamanAsimi = const Duration(seconds: 5), Directory? klasor}) {
  final k = klasor ?? Directory.systemTemp.createTempSync('kuran_test_');
  if (klasor == null) addTearDown(() => k.deleteSync(recursive: true));
  return KuranRepository(
      istemci: MockClient((istek) async => yanit(istek)),
      zamanAsimi: zamanAsimi,
      onbellekKlasoru: k);
}

/// Varlık dosyası okunamıyormuş gibi davranır.
class _BozukVarlik extends Fake implements AssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      throw Exception('yok');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('sure listesi (gömülü, internetsiz)', () {
    test(
        '114 sure, ayet toplamı 6236, sayfalar 1-604 ve sıralı; ağa hiç çıkılmaz',
        () async {
      var istek = 0;
      final sonuc = await _repo((_) {
        istek++;
        return _yanit({});
      }).getSurahs();

      final sureler = sonuc.data!;
      expect(sureler.map((s) => s.id), List.generate(114, (i) => i + 1));
      expect(sureler.fold<int>(0, (t, s) => t + s.versesCount), 6236);
      expect(sureler.first.startPage, 1);
      for (var i = 1; i < sureler.length; i++) {
        expect(sureler[i].startPage,
            greaterThanOrEqualTo(sureler[i - 1].startPage),
            reason: '${sureler[i].id}. sure sayfa sırası');
      }
      expect(sureler.last.startPage, lessThanOrEqualTo(604));
      expect(istek, 0, reason: 'liste gömülü; internet gerekmez');
    });

    test('Türkçe adlar (Fâtiha, Âl-i İmrân) ve iniş yeri bozulmadan okunur',
        () async {
      final sureler = (await _repo((_) => _yanit({})).getSurahs()).data!;

      expect(sureler.take(4).map((s) => s.displayName),
          ['Fâtiha', 'Bakara', 'Âl-i İmrân', 'Nisâ']);
      expect(sureler.last.displayName, 'Nâs');
      expect(sureler.first.nameSimple, 'Al-Fatihah');
      expect(sureler.first.nameArabic, isNotEmpty);
      expect((sureler[0].inisYeri, sureler[1].inisYeri), ('Mekke', 'Medine'));
      expect(sureler.where((s) => s.inisYeri == 'Mekke'), hasLength(86));
      expect(sureler.where((s) => s.inisYeri == 'Medine'), hasLength(28));
    });

    test('Türkçe ad gelmezse Latin yazım gösterilir', () {
      final sure = SurahModel.fromJson({
        'id': 4,
        'name_simple': 'An-Nisa',
        'name_arabic': 'x',
        'verses_count': 176,
        'translated_name': {'language_name': 'english', 'name': 'The Women'}
      });

      expect(sure.displayName, 'An-Nisa');
      expect(sure.inisYeri, isEmpty);
    });

    test('varlık okunamazsa çökmez, açık hata döner', () async {
      final sonuc =
          await KuranRepository(varliklar: _BozukVarlik()).getSurahs();

      expect(sonuc, isA<Failure<dynamic>>());
      expect(sonuc.errorMessage, isNot(contains('Exception')));
    });
  });

  group('ayetler ve sayfalama', () {
    test(
        'Cüz 30: API 500 ayet verip sonraki sayfayı gösterirse hepsi (564) toplanır',
        () async {
      final istekler = <Uri>[];
      final sonuc = await _repo((i) {
        istekler.add(i.url);
        final sayfa = int.parse(i.url.queryParameters['page']!);
        return _yanit(
            sayfa == 1 ? _sayfa(1, 500, sonraki: 2) : _sayfa(501, 64));
      }).getAyahsByJuz(30, 1);

      expect(sonuc.data, hasLength(564));
      expect(sonuc.data!.first.textUthmani, 'ar-78:1');
      expect(sonuc.data!.last.textUthmani, 'ar-78:564',
          reason: 'son ayetler kaybolmamalı');
      expect(istekler.map((u) => u.queryParameters['page']), ['1', '2']);
      expect(istekler.first.path, endsWith('/verses/by_juz/30'));
    });

    test(
        'istek: üç çeviri (Diyanet 77, Elmalılı 52, Saheeh International 20) ve metin alanı gider; ses istenmez',
        () async {
      Uri? adres;
      await _repo((i) {
        adres = i.url;
        return _yanit(_sayfa(1, 3));
      }).getAyahsBySurah(78, 7);

      expect(adres!.path, endsWith('/verses/by_chapter/78'));
      expect(adres!.queryParameters['translations'], '77,52,20');
      expect(adres!.queryParameters['fields'], 'text_uthmani');
      expect(adres!.queryParameters['per_page'], '500');
      expect(adres!.queryParameters.containsKey('audio'), isFalse,
          reason: 'ses adresi türetilir, istenmez');
    });

    test('tek sayfalık sonuç tek istekle biter (Sayfa 604)', () async {
      var sayac = 0;
      final sonuc = await _repo((_) {
        sayac++;
        return _yanit(_sayfa(1, 15));
      }).getAyahsByPage(604, 1);

      expect(sonuc.data, hasLength(15));
      expect(sayac, 1);
    });

    test('sunucu yanlış next_page verirse (aynı/önceki) sonsuz döngü olmaz',
        () async {
      var sayac = 0;
      final sonuc = await _repo((_) {
        sayac++;
        return _yanit(_sayfa(1, 5, sonraki: 1));
      }).getAyahsBySurah(1, 1);

      expect(sayac, 1);
      expect(sonuc, isA<Success<dynamic>>());
    });

    test('sayfalama hiç bitmezse eksik listeyi tam gibi sunmaz: hata döner',
        () async {
      var sayac = 0;
      final sonuc = await _repo((i) {
        sayac++;
        final sayfa = int.parse(i.url.queryParameters['page']!);
        return _yanit(_sayfa(1, 2, sonraki: sayfa + 1));
      }).getAyahsByJuz(1, 1);

      expect(sonuc, isA<Failure<dynamic>>());
      expect(sayac, 20, reason: 'üst sınırda durur');
    });

    test('ikinci sayfa alınamazsa yarım liste değil hata döner', () async {
      final sonuc = await _repo((i) {
        final sayfa = int.parse(i.url.queryParameters['page']!);
        return sayfa == 1
            ? _yanit(_sayfa(1, 500, sonraki: 2))
            : _yanit({'x': 1}, 503);
      }).getAyahsByJuz(30, 1);

      expect(sonuc, isA<Failure<dynamic>>());
      expect(sonuc.data, isNull);
    });

    test(
        'meal metnindeki HTML karakter kodları gerçek karaktere çevrilir (&quot; ekranda görünmez)',
        () async {
      // Diyanet meali biçimi (grupsuz bir ayet: 1:1).
      final sonuc = await _repo((_) => _yanit(_sayfaAyetlerden([
            _ayetJson('1:1',
                diyanet:
                    'De ki: &quot;İnsanlardan&quot; &amp; cinlerden &#39;sığınırım&#39; &lt;3&gt; &#x41; &nbsp;bitti &bilinmeyen;'),
          ]))).getAyahsBySurah(1, 1);

      expect(sonuc.data!.single.translation,
          "De ki: \"İnsanlardan\" & cinlerden 'sığınırım' <3> A  bitti &bilinmeyen;");
    });

    test(
        'çeviriden HTML etiketleri temizlenir; dipnot işaretleri tamamen atılır',
        () async {
      final sonuc = await _repo((_) => _yanit(_sayfaAyetlerden([
            _ayetJson('1:1', diyanet: 'Merhaba <sup foot_note=1>1</sup> dünya'),
          ]))).getAyahsBySurah(1, 7);

      expect(sonuc.data!.single.translation, 'Merhaba dünya',
          reason: 'dipnot rakamı kelimeye yapışmamalı');
    });
  });

  group('İngilizce meal (Saheeh International)', () {
    test('ayete İngilizce meal konur; Türkçe meal etkilenmez', () async {
      final sonuc = await _repo((_) => _yanit(_sayfaAyetlerden([
            _ayetJson('1:1',
                diyanet: 'Rahman ve Rahim', ingilizce: 'In the name of Allah'),
          ]))).getAyahsBySurah(1, 7);

      final a = sonuc.data!.single;
      expect((a.translation, a.translationEn),
          ('Rahman ve Rahim', 'In the name of Allah'));
    });

    test('dipnot işaretleri atılır ("Allāh,1 the Entirely Merciful,2" olmaz)',
        () async {
      final sonuc = await _repo((_) => _yanit(_sayfaAyetlerden([
            _ayetJson('1:1',
                ingilizce:
                    'In the name of Allāh,<sup foot_note=1>1</sup> the Entirely Merciful,<sup foot_note=2>2</sup> the Especially Merciful.'),
          ]))).getAyahsBySurah(1, 7);

      expect(sonuc.data!.single.translationEn,
          'In the name of Allāh, the Entirely Merciful, the Especially Merciful.');
    });

    test('İngilizce meal yoksa boş kalır, çökmez', () async {
      final j = _ayetJson('1:1');
      (j['translations'] as List).removeWhere((t) => t['resource_id'] == 20);
      final sonuc = await _repo((_) => _yanit(_sayfaAyetlerden([j])))
          .getAyahsBySurah(1, 7);

      expect(sonuc.data!.single.translationEn, isEmpty);
    });

    test('İngilizce meal cihaz önbelleğinde de saklanır (internetsiz gelir)',
        () async {
      final klasor = Directory.systemTemp.createTempSync('kuran_en_');
      addTearDown(() => klasor.deleteSync(recursive: true));
      await _repo(
              (_) => _yanit(_sayfaAyetlerden([
                    _ayetJson('2:255',
                        ingilizce: 'Allāh - there is no deity except Him')
                  ])),
              klasor: klasor)
          .getAyahsBySurah(2, 7);

      final internetsiz = KuranRepository(
          istemci: MockClient((_) async => throw http.ClientException('yok')),
          onbellekKlasoru: klasor);
      final a = (await internetsiz.getAyahsBySurah(2, 7)).data!.single;

      expect(a.translationEn, 'Allāh - there is no deity except Him');
    });

    test(
        'İngilizce mealsiz eski önbellek (v1) görmezden gelinir ve yeniden alınır',
        () async {
      final klasor = Directory.systemTemp.createTempSync('kuran_v1_');
      addTearDown(() => klasor.deleteSync(recursive: true));
      File('${klasor.path}/v1_sure_78.json').writeAsStringSync(json.encode({
        'v': 1,
        'ayetler': [
          {'id': 1, 'k': '78:1', 'a': 'x', 'm': 'eski', 's': 'Diyanet', 'p': 1}
        ]
      }));
      var istek = 0;
      final sonuc = await _repo((_) {
        istek++;
        return _yanit(_sayfa(1, 2));
      }, klasor: klasor)
          .getAyahsBySurah(78, 7);

      expect(istek, 1);
      expect(sonuc.data!.first.translationEn, 'English meal');
    });
  });

  group('meal kaynağı: Diyanet, eksikse Elmalılı', () {
    test(
        'Diyanet önceki ayetle aynı blok ise (2:27) Elmalılı gösterilir ve kaynak işaretlenir; diğerleri Diyanet',
        () async {
      // 2:26 ve 2:27 gerçek veride aynı Diyanet bloğunu taşır; 2:28 farklı.
      final sonuc = await _repo((_) => _yanit(_sayfaAyetlerden([
            _ayetJson('2:26', diyanet: 'BLOK', elmali: 'e26'),
            _ayetJson('2:27', diyanet: 'BLOK', elmali: 'e27'),
            _ayetJson('2:28', diyanet: 'd28', elmali: 'e28'),
          ]))).getAyahsBySurah(2, 7);

      final a = sonuc.data!;
      expect(a.map((x) => (x.verseKey, x.translation, x.mealKaynagi)), [
        ('2:26', 'BLOK', 'Diyanet'),
        ('2:27', 'e27', 'Elmalılı'),
        ('2:28', 'd28', 'Diyanet'),
      ]);
    });

    test(
        'Diyanet metni boşsa Elmalılı tamamlar; ikisi de boşsa boş kalır, çökmez',
        () async {
      final sonuc = await _repo((_) => _yanit(_sayfaAyetlerden([
            _ayetJson('3:1', diyanet: '', elmali: 'yalnız Elmalılı'),
            _ayetJson('3:2', diyanet: '  ', elmali: ''),
          ]))).getAyahsBySurah(3, 7);

      expect(sonuc.data!.map((x) => (x.translation, x.mealKaynagi)), [
        ('yalnız Elmalılı', 'Elmalılı'),
        ('', 'Diyanet'),
      ]);
    });

    test('çeviri sırası önemsiz: kaynak resource_id ile seçilir', () async {
      final j = _ayetJson('5:1', diyanet: 'D', elmali: 'E');
      (j['translations'] as List)
          .setAll(0, (j['translations'] as List).reversed);
      final sonuc = await _repo((_) => _yanit(_sayfaAyetlerden([j])))
          .getAyahsBySurah(5, 7);

      expect(sonuc.data!.single.translation, 'D');
    });

    test(
        'grup listesi okunamazsa yalnız boş Diyanet ayetleri tamamlanır (çökmez)',
        () async {
      final k = Directory.systemTemp.createTempSync('kuran_test_');
      addTearDown(() => k.deleteSync(recursive: true));
      final depo = KuranRepository(
          istemci: MockClient((_) async => _yanit(_sayfaAyetlerden([
                _ayetJson('2:26', diyanet: 'BLOK', elmali: 'e26'),
                _ayetJson('2:27', diyanet: 'BLOK', elmali: 'e27'),
                _ayetJson('2:28', diyanet: '', elmali: 'e28'),
              ]))),
          varliklar: _BozukVarlik(),
          onbellekKlasoru: k);

      final a = (await depo.getAyahsBySurah(2, 7)).data!;

      expect(a.map((x) => x.translation), ['BLOK', 'BLOK', 'e28']);
    });

    test(
        'gömülü grup listesi tutarlı: 796 ayet, 2:27 içinde, 2:26 ve 2:1 dışında',
        () async {
      final g = json.decode(
              await rootBundle.loadString('assets/json/diyanet_gruplu.json'))
          as Map;
      final sure = g['sure'] as Map;
      final ayetler = {
        for (final e in sure.entries)
          for (final a in e.value as List) '${e.key}:$a'
      };

      expect(ayetler.length, g['sayi']);
      expect(ayetler.length, 796);
      expect(ayetler, contains('2:27'));
      expect(ayetler, isNot(contains('2:26')),
          reason: 'grubun ilk ayeti Diyanet kalır');
      expect(ayetler, isNot(contains('2:1')));
    });
  });

  group('ses adresi', () {
    test('4 okuyucu için adresler (API yanıtıyla doğrulanmış örnekler)', () {
      const beklenen = {
        1: 'https://verses.quran.com/AbdulBaset/Mujawwad/mp3/002255.mp3',
        7: 'https://verses.quran.com/Alafasy/mp3/002255.mp3',
        12: 'https://mirrors.quranicaudio.com/everyayah/Husary_Muallim_128kbps/002255.mp3',
        3: 'https://verses.quran.com/Sudais/mp3/002255.mp3',
      };
      for (final e in beklenen.entries) {
        expect(KuranRepository.sesAdresi(e.key, '2:255'), e.value);
      }
      expect(KuranRepository.sesAdresi(7, '1:1'),
          'https://verses.quran.com/Alafasy/mp3/001001.mp3');
      expect(KuranRepository.sesAdresi(7, '114:6'),
          'https://verses.quran.com/Alafasy/mp3/114006.mp3');
    });

    test(
        'Husary adresi https://verses.quran.com/// ile başlamaz (eski hata: 404)',
        () {
      final adres = KuranRepository.sesAdresi(12, '1:1');

      expect(adres, startsWith('https://mirrors.quranicaudio.com/'));
      expect(adres, isNot(contains('verses.quran.com')));
    });

    test('bilinmeyen okuyucu ya da bozuk ayet anahtarı boş adres verir', () {
      expect(KuranRepository.sesAdresi(99, '2:255'), isEmpty);
      expect(KuranRepository.sesAdresi(7, 'bozuk'), isEmpty);
      expect(KuranRepository.sesAdresi(7, 'a:b'), isEmpty);
    });

    test('depo ayetlere seçilen okuyucunun adresini koyar', () async {
      final sonuc =
          await _repo((_) => _yanit(_sayfaAyetlerden([_ayetJson('2:255')])))
              .getAyahsBySurah(2, 12);

      expect(sonuc.data!.single.audioUrl,
          'https://mirrors.quranicaudio.com/everyayah/Husary_Muallim_128kbps/002255.mp3');
    });
  });

  group('cihaz önbelleği (ayetler ilk okumada kaydedilir)', () {
    late Directory klasor;
    setUp(() {
      klasor = Directory.systemTemp.createTempSync('kuran_onbellek_');
      addTearDown(() => klasor.deleteSync(recursive: true));
    });

    test('ilk okuma ağdan alır ve yazar; ikinci okuma internetsiz de açılır',
        () async {
      var istek = 0;
      final ilk = _repo((_) {
        istek++;
        return _yanit(_sayfa(1, 5));
      }, klasor: klasor);
      expect((await ilk.getAyahsBySurah(78, 7)).data, hasLength(5));
      expect(istek, 1);

      // Uygulama yeniden açıldı ve internet YOK: yeni depo, ağa çıkamaz.
      final internetsiz = KuranRepository(
          istemci: MockClient((_) async => throw http.ClientException('yok')),
          onbellekKlasoru: klasor);
      final sonuc = await internetsiz.getAyahsBySurah(78, 7);

      expect(sonuc, isA<Success<dynamic>>());
      expect(sonuc.data!.map((a) => a.textUthmani),
          ['ar-78:1', 'ar-78:2', 'ar-78:3', 'ar-78:4', 'ar-78:5']);
      expect(sonuc.data!.first.translation, 'Meal');
    });

    test(
        'önbellek okuyucudan bağımsız: Alafasy ile kaydedilen sure Sudais için doğru adresi verir',
        () async {
      await _repo((_) => _yanit(_sayfaAyetlerden([_ayetJson('2:255')])),
              klasor: klasor)
          .getAyahsBySurah(2, 7);

      final internetsiz = KuranRepository(
          istemci: MockClient((_) async => throw http.ClientException('yok')),
          onbellekKlasoru: klasor);
      final a = (await internetsiz.getAyahsBySurah(2, 3)).data!.single;

      expect(a.audioUrl, 'https://verses.quran.com/Sudais/mp3/002255.mp3');
    });

    test('Elmalılı ile tamamlanan meal ve kaynağı önbellekte korunur',
        () async {
      await _repo(
              (_) => _yanit(_sayfaAyetlerden([
                    _ayetJson('2:26', diyanet: 'BLOK', elmali: 'e26'),
                    _ayetJson('2:27', diyanet: 'BLOK', elmali: 'e27'),
                  ])),
              klasor: klasor)
          .getAyahsBySurah(2, 7);

      final internetsiz = KuranRepository(
          istemci: MockClient((_) async => throw http.ClientException('yok')),
          onbellekKlasoru: klasor);
      final a = (await internetsiz.getAyahsBySurah(2, 7)).data!;

      expect(a.map((x) => (x.translation, x.mealKaynagi)),
          [('BLOK', 'Diyanet'), ('e27', 'Elmalılı')]);
    });

    test(
        'Cüz 30 (2 API sayfası) tek bütün olarak saklanır: önbellekten 564 ayet gelir',
        () async {
      await _repo((i) {
        final sayfa = int.parse(i.url.queryParameters['page']!);
        return _yanit(
            sayfa == 1 ? _sayfa(1, 500, sonraki: 2) : _sayfa(501, 64));
      }, klasor: klasor)
          .getAyahsByJuz(30, 1);

      final internetsiz = KuranRepository(
          istemci: MockClient((_) async => throw http.ClientException('yok')),
          onbellekKlasoru: klasor);
      expect((await internetsiz.getAyahsByJuz(30, 1)).data, hasLength(564));
    });

    test(
        'sure, cüz ve sayfa ayrı anahtarlarla saklanır (birbirinin yerine geçmez)',
        () async {
      var istek = 0;
      final depo = _repo((_) {
        istek++;
        return _yanit(_sayfa(1, 2));
      }, klasor: klasor);

      await depo.getAyahsBySurah(1, 7);
      await depo.getAyahsByJuz(1, 7);
      await depo.getAyahsByPage(1, 7);
      await depo.getAyahsBySurah(1, 7); // önbellekten

      expect(istek, 3);
    });

    test(
        'bozuk önbellek dosyası yok sayılır, ağdan yeniden alınır ve düzeltilir',
        () async {
      File('${klasor.path}/v1_sure_78.json').writeAsStringSync('json değil {{');
      var istek = 0;
      final depo = _repo((_) {
        istek++;
        return _yanit(_sayfa(1, 3));
      }, klasor: klasor);

      final sonuc = await depo.getAyahsBySurah(78, 7);
      expect(sonuc.data, hasLength(3));
      expect(istek, 1);

      await depo.getAyahsBySurah(78, 7);
      expect(istek, 1, reason: 'düzeltilen dosya artık okunur');
    });

    test('farklı sürüm ya da eksik alanlı önbellek yok sayılır', () async {
      File('${klasor.path}/v1_sure_78.json')
          .writeAsStringSync(json.encode({'v': 99, 'ayetler': []}));
      File('${klasor.path}/v1_sure_79.json').writeAsStringSync(json.encode({
        'v': 1,
        'ayetler': [
          {'id': 1}
        ]
      }));
      var istek = 0;
      final depo = _repo((_) {
        istek++;
        return _yanit(_sayfa(1, 2));
      }, klasor: klasor);

      expect((await depo.getAyahsBySurah(78, 7)).data, hasLength(2));
      expect((await depo.getAyahsBySurah(79, 7)).data, hasLength(2));
      expect(istek, 2);
    });

    test('başarısız istek önbelleğe yazılmaz', () async {
      final sonuc = await _repo((_) => _yanit({'x': 1}, 500), klasor: klasor)
          .getAyahsBySurah(78, 7);

      expect(sonuc, isA<Failure<dynamic>>());
      expect(klasor.listSync(), isEmpty);
    });

    test(
        'önbellek klasörü açılamıyorsa okuma yine çalışır (yazma sessizce atlanır)',
        () async {
      // Klasör yolunda bir DOSYA var: oluşturulamaz.
      final dosya = File('${klasor.path}/engel')..writeAsStringSync('x');
      final sonuc = await KuranRepository(
              istemci: MockClient((_) async => _yanit(_sayfa(1, 4))),
              onbellekKlasoru: Directory(dosya.path))
          .getAyahsBySurah(78, 7);

      expect(sonuc.data, hasLength(4));
    });
  });

  group('hata metinleri kullanıcıya teknik ayrıntı sızdırmaz', () {
    test('HTTP hatası: durum kodu var, gövde ve istisna yok', () async {
      final sonuc = await _repo(
              (_) => http.Response('{"secret":"SUNUCU-IC-AYRINTI"}', 500))
          .getAyahsBySurah(2, 1);

      expect(sonuc, isA<Failure<dynamic>>());
      expect(sonuc.errorMessage, contains('500'));
      expect(sonuc.errorMessage, isNot(contains('SUNUCU-IC-AYRINTI')));
      expect(sonuc.errorMessage, isNot(contains('Body')));
    });

    test('ağ hatası: açık bir Türkçe mesaj, istisna adı yok', () async {
      final sonuc = await _repo((_) =>
              throw http.ClientException('Failed host lookup: api.quran.com'))
          .getAyahsBySurah(1, 1);

      expect(sonuc, isA<Failure<dynamic>>());
      expect(sonuc.errorMessage, contains('İnternet bağlantınızı kontrol'));
      expect(sonuc.errorMessage, isNot(contains('ClientException')));
      expect(sonuc.errorMessage, isNot(contains('api.quran.com')));
    });

    test('yanıt gecikirse zaman aşımı hata olur (sonsuz beklemez)', () async {
      final sonuc = await _repo(
              (_) => Future<http.Response>.delayed(
                  const Duration(seconds: 2), () => _yanit({})),
              zamanAsimi: const Duration(milliseconds: 50))
          .getAyahsBySurah(1, 1);

      expect(sonuc, isA<Failure<dynamic>>());
    });

    test('bozuk JSON hata olur, çökmez', () async {
      final sonuc = await _repo((_) => http.Response('bu json değil', 200))
          .getAyahsBySurah(1, 1);

      expect(sonuc, isA<Failure<dynamic>>());
    });
  });

  test('cüz listesi 1-30', () async {
    final sonuc = await _repo((_) => _yanit({})).getJuzList();

    expect(sonuc.data, List<int>.generate(30, (i) => i + 1));
  });
}
