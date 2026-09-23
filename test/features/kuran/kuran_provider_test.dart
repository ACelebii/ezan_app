import 'dart:async';

import 'package:ezan_vakti_uygulamasi/core/utils/result.dart';
import 'package:ezan_vakti_uygulamasi/features/kuran/providers/kuran_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'kuran_test_yardimcilari.dart';

Future<(KuranProvider, SahteDeposu)> _kur() async {
  SharedPreferences.setMockInitialValues({});
  final depo = SahteDeposu();
  final p = KuranProvider(repo: depo, audioPlayer: SahteOynatici());
  await pumpEventQueue();
  return (p, depo);
}

void main() {
  test('sure listesi Türkçe adlarla gelir; başlık Türkçe ad kullanır',
      () async {
    final (p, depo) = await _kur();
    expect(p.surahs.map((s) => s.displayName), ['Fâtiha', 'Bakara']);

    unawaited(p.loadSurahDetails(p.surahs[1]));
    depo.sureIstekleri[2]!.complete(Success([sahteAyet(1, 'a')]));
    await pumpEventQueue();

    expect(p.activeTitle, 'Bakara Suresi');
    expect(p.currentAyahs, hasLength(1));
    expect(p.isAyahsLoading, isFalse);
  });

  test('yükleme sırasında yükleniyor durumu açıktır ve ayetler temizdir',
      () async {
    final (p, depo) = await _kur();

    unawaited(p.loadSurahDetails(p.surahs[0]));

    expect(p.isAyahsLoading, isTrue);
    expect(p.currentAyahs, isEmpty);
    depo.sureIstekleri[1]!.complete(Success([sahteAyet(1, 'a')]));
    await pumpEventQueue();
    expect(p.isAyahsLoading, isFalse);
  });

  test(
      'kullanıcı hızlıca başka sureye geçerse eski yüklemenin geç yanıtı yenisini ezmez',
      () async {
    final (p, depo) = await _kur();
    final fatiha = p.surahs[0], bakara = p.surahs[1];

    unawaited(p.loadSurahDetails(fatiha)); // yavaş
    unawaited(p.loadSurahDetails(bakara)); // sonra başlayan
    depo.sureIstekleri[2]!.complete(Success([sahteAyet(200, 'bakara-ayeti')]));
    await pumpEventQueue();
    expect(p.currentAyahs.single.textUthmani, 'bakara-ayeti');

    // Eski (Fâtiha) yanıt şimdi, geç geliyor.
    depo.sureIstekleri[1]!.complete(Success([sahteAyet(100, 'fatiha-ayeti')]));
    await pumpEventQueue();

    expect(p.activeSurah!.id, 2);
    expect(p.activeTitle, 'Bakara Suresi');
    expect(p.currentAyahs.single.textUthmani, 'bakara-ayeti',
        reason: 'geç gelen eski yanıt ekranı bozmamalı');
    expect(p.isAyahsLoading, isFalse);
  });

  test(
      'eski yükleme HATAYLA dönse bile yeni yüklemenin ayetlerini ve hata durumunu bozmaz',
      () async {
    final (p, depo) = await _kur();

    unawaited(p.loadSurahDetails(p.surahs[0]));
    unawaited(p.loadSurahDetails(p.surahs[1]));
    depo.sureIstekleri[2]!.complete(Success([sahteAyet(2, 'yeni')]));
    await pumpEventQueue();
    depo.sureIstekleri[1]!.complete(Failure('Sure ayetleri yüklenemedi.'));
    await pumpEventQueue();

    expect(p.currentAyahs.single.textUthmani, 'yeni');
    expect(p.errorMessage, isNull);
  });

  test('yükleme hatası kullanıcı metniyle errorMessage olur', () async {
    final (p, depo) = await _kur();

    unawaited(p.loadSurahDetails(p.surahs[0]));
    depo.sureIstekleri[1]!.complete(Failure(
        'Sure ayetleri yüklenemedi. İnternet bağlantınızı kontrol edip tekrar deneyin.'));
    await pumpEventQueue();

    expect(p.errorMessage, contains('İnternet bağlantınızı kontrol'));
    expect(p.currentAyahs, isEmpty);
    expect(p.isAyahsLoading, isFalse);
  });

  test('cüz yüklemesi de başlığı ve durumu doğru kurar', () async {
    final (p, _) = await _kur();

    await p.loadJuzDetails(30);

    expect(p.activeTitle, '30. Cüz');
    expect(p.activeJuz, 30);
    expect(p.currentAyahs.single.textUthmani, 'cuz');
  });

  test(
      'yer imi: sure seçiliyken eklenir, tekrar dokununca kalkar; yeniden açılışta korunur',
      () async {
    final (p, depo) = await _kur();
    unawaited(p.loadSurahDetails(p.surahs[1]));
    depo.sureIstekleri[2]!.complete(Success([sahteAyet(1, 'a')]));
    await pumpEventQueue();

    await p.toggleBookmark();
    expect(p.isBookmarked, isTrue);
    expect((p.savedBookmarkType, p.savedBookmarkId, p.savedBookmarkTitle),
        ('surah', 2, 'Bakara Suresi'));

    // Uygulama yeniden açıldı: kayıt SharedPreferences'tan gelir.
    final yeni = KuranProvider(repo: depo, audioPlayer: SahteOynatici());
    await pumpEventQueue();
    expect(yeni.savedBookmarkTitle, 'Bakara Suresi');

    await p.toggleBookmark();
    expect(p.isBookmarked, isFalse);
    expect(p.savedBookmarkType, isNull);
  });

  test('hafız değişince açık sure yeni okuyucuyla yeniden yüklenir', () async {
    final (p, depo) = await _kur();
    unawaited(p.loadSurahDetails(p.surahs[0]));
    depo.sureIstekleri[1]!.complete(Success([sahteAyet(1, 'a')]));
    await pumpEventQueue();

    p.changeHafiz('Mishary Alafasy');
    await pumpEventQueue();

    expect(depo.okuyucular, [1, 7],
        reason: 'önce Abdul Basit (1), sonra Alafasy (7)');
  });

  group('favori, not, okuma listesi', () {
    Future<(KuranProvider, SahteDeposu)> bakaraAc() async {
      final (p, depo) = await _kur();
      unawaited(p.loadSurahDetails(p.surahs[1]));
      depo.sureIstekleri[2]!
          .complete(Success([for (var i = 1; i <= 6; i++) sesliAyet(2, i)]));
      await pumpEventQueue();
      return (p, depo);
    }

    test(
        'favori: eklenir, tekrar dokununca kalkar; kayıt boşalınca silinir; yeniden açılışta korunur',
        () async {
      final (p, depo) = await bakaraAc();
      final a = p.currentAyahs[3];

      await p.kayitDegistir(p.ayetKaydi(a), favori: true);
      expect(p.favoriMi(a), isTrue);

      // Uygulama yeniden açıldı: kayıt cihazdan gelir, metin de saklıdır.
      final yeni = KuranProvider(repo: depo, audioPlayer: SahteOynatici());
      await pumpEventQueue();
      expect(yeni.ayetKayitlari.single.verseKey, '2:4');
      expect(yeni.ayetKayitlari.single.arapca, 'ayet-4');
      expect(yeni.ayetKayitlari.single.meal, 'meal-4');

      await p.kayitDegistir(p.ayetKaydi(a), favori: false);
      expect(p.favoriMi(a), isFalse);
      expect(p.ayetKayitlari, isEmpty,
          reason: 'ne favori ne not kalınca kayıt silinir');
    });

    test(
        'not: kırpılarak kaydedilir, boş metin notu siler ama favoriyi korur; kayıtlar sure/ayet sırasında',
        () async {
      final (p, _) = await bakaraAc();

      await p.kayitDegistir(p.ayetKaydi(p.currentAyahs[4]),
          favori: true); // 2:5
      await p.kayitDegistir(p.ayetKaydi(p.currentAyahs[1]),
          not: '  Çok önemli  '); // 2:2
      expect(p.ayetKayitlari.map((k) => k.verseKey), ['2:2', '2:5']);
      expect(p.notu(p.currentAyahs[1]), 'Çok önemli');

      await p.kayitDegistir(p.ayetKaydi(p.currentAyahs[4]), not: 'x');
      await p.kayitDegistir(p.ayetKaydi(p.currentAyahs[4]), not: '');
      expect(p.notu(p.currentAyahs[4]), isEmpty);
      expect(p.favoriMi(p.currentAyahs[4]), isTrue,
          reason: 'notu silmek favoriyi bozmaz');
    });

    test('kayıt sure adını saklar (çevrimdışı gösterim için)', () async {
      final (p, _) = await bakaraAc();

      expect(p.ayetKaydi(p.currentAyahs[0]).sureAdi, 'Bakara');
    });

    test('bozuk kayıtlı veri açılışta çökmez, geçerli kayıtlar kalır',
        () async {
      SharedPreferences.setMockInitialValues({
        'kuran_ayet_kayitlari':
            '[{"verse_key":"2:4","sure":"Bakara","arapca":"a","meal":"m","favori":true,"not":""},'
                '{"verse_key":"bozuk"},5,null]',
        'kuran_okuma_listesi':
            '[{"sure_id":3,"okundu":true},{"sure_id":999},"x"]',
      });
      final p =
          KuranProvider(repo: SahteDeposu(), audioPlayer: SahteOynatici());
      await pumpEventQueue();

      expect(p.ayetKayitlari.map((k) => k.verseKey), ['2:4']);
      expect(p.okumaListesi.map((o) => (o.sureId, o.okundu)), [(3, true)]);

      SharedPreferences.setMockInitialValues(
          {'kuran_ayet_kayitlari': 'json değil'});
      final q =
          KuranProvider(repo: SahteDeposu(), audioPlayer: SahteOynatici());
      await pumpEventQueue();
      expect(q.ayetKayitlari, isEmpty);
    });

    test(
        'okuma listesi: ekle (tekrar eklenmez), okundu işareti, çıkar; yeniden açılışta korunur',
        () async {
      final (p, depo) = await _kur();

      await p.okumayaEkle(2);
      await p.okumayaEkle(2);
      await p.okumayaEkle(36);
      await p.okunduDegistir(36);
      expect(p.okumaListesi.map((o) => (o.sureId, o.okundu)),
          [(2, false), (36, true)]);

      final yeni = KuranProvider(repo: depo, audioPlayer: SahteOynatici());
      await pumpEventQueue();
      expect(yeni.okumaListesi.map((o) => (o.sureId, o.okundu)),
          [(2, false), (36, true)]);

      await p.okumadanCikar(2);
      expect(p.okumaListesi.map((o) => o.sureId), [36]);
    });

    test(
        'ayeteKaydir: hedef ve vurgu kurulur; sınır dışı yok sayılır; yeni cüz yüklemesi hedefi siler',
        () async {
      final (p, _) = await bakaraAc();

      p.ayeteKaydir(2);
      expect((p.hedefAyetIndex, p.activeAyahId), (2, 2003));
      p.hedefiTemizle();
      p.ayeteKaydir(99);
      p.ayeteKaydir(-1);
      expect(p.hedefAyetIndex, isNull);

      p.ayeteKaydir(2);
      await p.loadJuzDetails(30);
      expect(p.hedefAyetIndex, isNull,
          reason: 'eski hedef yeni içeriğe taşınmaz');
    });

    test(
        'ayete gitme: hedef indeks, vurgu ve ses o ayetten başlar; olmayan ayette başa döner',
        () async {
      final (p, depo) = await _kur();
      final oynatici = p.audioPlayer as SahteOynatici;

      unawaited(p.loadSurahDetails(p.surahs[1], ayetNo: 4));
      depo.sureIstekleri[2]!
          .complete(Success([for (var i = 1; i <= 6; i++) sesliAyet(2, i)]));
      await pumpEventQueue();

      expect(p.hedefAyetIndex, 3);
      expect(p.activeAyahId, 2004);
      expect(oynatici.baslangicIndeksleri.last, 3);
      p.hedefiTemizle();
      expect(p.hedefAyetIndex, isNull);

      unawaited(p.loadSurahDetails(p.surahs[1], ayetNo: 99));
      depo.sureIstekleri[2]!
          .complete(Success([for (var i = 1; i <= 6; i++) sesliAyet(2, i)]));
      await pumpEventQueue();
      expect(p.hedefAyetIndex, isNull);
      expect(oynatici.baslangicIndeksleri.last, 0);
    });
  });

  group('ezberleme', () {
    Future<(KuranProvider, SahteOynatici)> bakaraAc() async {
      final (p, depo) = await _kur();
      unawaited(p.loadSurahDetails(p.surahs[1]));
      depo.sureIstekleri[2]!
          .complete(Success([for (var i = 1; i <= 6; i++) sesliAyet(2, i)]));
      await pumpEventQueue();
      return (p, p.audioPlayer as SahteOynatici);
    }

    test('her ayet tekrarlanarak sırayla çalınır', () async {
      final (p, oynatici) = await bakaraAc();
      final onceki = oynatici.kurulanListeler.length;

      final hata = await p.ezberle(1, 2, 3);

      expect(hata, isNull);
      expect(oynatici.kurulanListeler.length, onceki + 1);
      expect(oynatici.kurulanListeler.last, [
        for (final no in [2, 3])
          for (var k = 0; k < 3; k++) 'https://ses.test/2-$no.mp3',
      ]);
      expect(oynatici.baslangicIndeksleri.last, 0);
      expect(oynatici.oynatma, greaterThan(0));
      expect(p.ezberModu, isTrue);
    });

    test(
        'ters aralık, sesli ayet olmayan aralık ve aşırı büyük istek hata metni döner; liste değişmez',
        () async {
      final (p, oynatici) = await bakaraAc();
      final onceki = oynatici.kurulanListeler.length;

      expect(await p.ezberle(3, 1, 3), contains('sesli ayet yok'));
      expect(await p.ezberle(0, 99, 3), contains('sesli ayet yok'));
      expect(await p.ezberle(0, 5, 0), contains('sesli ayet yok'));
      final buyuk = await p.ezberle(0, 5, 60); // 6 x 60 = 360 > 300
      expect(buyuk, allOf(contains('360'), contains('300')));

      expect(oynatici.kurulanListeler.length, onceki);
      expect(p.ezberModu, isFalse);
    });

    test(
        'ezber aralığı dışındaki ayete dokunulursa tam liste kurulur ve ezber modu kapanır',
        () async {
      final (p, oynatici) = await bakaraAc();
      await p.ezberle(0, 1, 2);
      expect(p.ezberModu, isTrue);

      await p.playSingleAyah(4);

      expect(p.ezberModu, isFalse);
      expect(oynatici.kurulanListeler.last, hasLength(6));
      expect(oynatici.atlamalar.last, 4);
    });

    test('ezber aralığı içindeki ayete dokunmak listeyi bozmaz', () async {
      final (p, oynatici) = await bakaraAc();
      await p.ezberle(0, 1, 2);
      final kurulum = oynatici.kurulanListeler.length;

      await p.playSingleAyah(1);

      expect(oynatici.kurulanListeler.length, kurulum);
      expect(p.ezberModu, isTrue);
    });

    test('ezberi bitirmek tam çalma listesini geri getirir', () async {
      final (p, oynatici) = await bakaraAc();
      await p.ezberle(0, 1, 2);

      await p.ezberiBitir();

      expect(p.ezberModu, isFalse);
      expect(oynatici.kurulanListeler.last, hasLength(6));
    });
  });

  group('meal dili', () {
    test(
        'İngilizce arayüzde Saheeh International, Türkçede Diyanet/Elmalılı gösterilir',
        () async {
      SharedPreferences.setMockInitialValues({});
      var en = false;
      final p = KuranProvider(
          repo: SahteDeposu(),
          audioPlayer: SahteOynatici(),
          ingilizceMi: () => en);
      await pumpEventQueue();
      final a = sesliAyet(2, 4);

      expect((p.mealMetni(a), p.mealKaynagiEtiketi(a)), ('meal-4', 'Diyanet'));
      en = true;
      expect((p.mealMetni(a), p.mealKaynagiEtiketi(a)),
          ('english-4', 'Saheeh International'));
    });

    test('İngilizce meal yoksa Türkçeye düşülür (boş ekran olmaz)', () async {
      SharedPreferences.setMockInitialValues({});
      final p = KuranProvider(
          repo: SahteDeposu(),
          audioPlayer: SahteOynatici(),
          ingilizceMi: () => true);
      await pumpEventQueue();
      final a = sahteAyet(1, 'ar'); // İngilizce meali yok

      expect(p.mealMetni(a), a.translation);
      expect(p.mealKaynagiEtiketi(a), 'Diyanet');
    });

    test(
        'favori/not kaydı İngilizce mealle saklanır; eski kayıt (mealsiz) ayet yüklenince tamamlanır',
        () async {
      SharedPreferences.setMockInitialValues({
        'kuran_ayet_kayitlari':
            '[{"verse_key":"2:4","sure":"Bakara","arapca":"a","meal":"eski meal","favori":true,"not":""}]',
      });
      var en = true;
      final p = KuranProvider(
          repo: SahteDeposu(),
          audioPlayer: SahteOynatici(),
          ingilizceMi: () => en);
      await pumpEventQueue();
      final eski = p.ayetKayitlari.single;
      expect(p.kartMeali(eski), 'eski meal',
          reason: 'İngilizcesi yok: Türkçe gösterilir');

      final a = sesliAyet(2, 4);
      await p.kayitDegistir(p.ayetKaydi(a), not: 'x');

      final yeni = p.ayetKayitlari.single;
      expect((yeni.mealEn, p.kartMeali(yeni)), ('english-4', 'english-4'));
      en = false;
      expect(p.kartMeali(yeni), 'eski meal');
      // Yeni kayıt da İngilizce mealle başlar.
      await p.kayitDegistir(p.ayetKaydi(sesliAyet(2, 5)), favori: true);
      expect(p.ayetKayitlari.last.mealEn, 'english-5');
    });
  });

  group('uygulama dili', () {
    test(
        'sure adı, başlık ve yer imi başlığı dile göre üretilir; diske Türkçe yazılır',
        () async {
      SharedPreferences.setMockInitialValues({});
      var en = false;
      final depo = SahteDeposu();
      final p = KuranProvider(
          repo: depo, audioPlayer: SahteOynatici(), ingilizceMi: () => en);
      await pumpEventQueue();
      final bakara = p.surahs[1];
      expect(p.sureAdi(bakara), 'Bakara');

      unawaited(p.loadSurahDetails(bakara));
      depo.sureIstekleri[2]!.complete(Success([sahteAyet(1, 'a')]));
      await pumpEventQueue();
      await p.toggleBookmark();
      expect((p.activeTitle, p.savedBookmarkTitle),
          ('Bakara Suresi', 'Bakara Suresi'));

      en = true; // ayarlardan İngilizce seçildi; yeniden yükleme gerekmez
      expect(p.sureAdi(bakara), 'Sure2',
          reason: 'Latin yazım (sahtede nameSimple)');
      expect((p.activeTitle, p.savedBookmarkTitle),
          ('Surah Sure2', 'Surah Sure2'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('bookmark_title'), 'Bakara Suresi',
          reason: 'kayıt dilden bağımsız (Türkçe) kalır');

      await p.loadJuzDetails(30);
      expect(p.activeTitle, 'Juz 30');
      en = false;
      expect(p.activeTitle, '30. Cüz');
      await p.loadPageDetails(12);
      expect(p.activeTitle, '12. Sayfa');
      en = true;
      expect(p.activeTitle, 'Page 12');
    });

    test('Türkçe adı olmayan sure Latin yazımla gösterilir; bilinmeyen id boş',
        () async {
      final (p, _) = await _kur();

      expect(p.sureAdiId(2), 'Bakara');
      expect(p.sureAdiId(99, 'yedek'), 'yedek');
    });
  });
}
