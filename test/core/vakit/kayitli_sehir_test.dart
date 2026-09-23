import 'package:ezan_vakti_uygulamasi/core/models/city_list.dart';
import 'package:ezan_vakti_uygulamasi/core/vakit/kayitli_sehir.dart';
import 'package:ezan_vakti_uygulamasi/core/vakit/vakit_modelleri.dart';
import 'package:flutter_test/flutter_test.dart';

KayitliSehir _yabanci(String ad, int id, {bool secili = false}) => KayitliSehir(
      isim: ad,
      ulke: 'Amerika Birleşik Devletleri',
      tur: 'Diyanet Takvimi',
      secili: secili,
      konum: Konum(
          ad: ad,
          ulke: 'Amerika Birleşik Devletleri',
          saatDilimi: 'America/Chicago',
          diyanetIlceId: id,
          enlem: 33.5,
          boylam: -86.8),
    );

KayitliSehir _il(String ad, {bool secili = false}) => KayitliSehir.fromMap(
    {'isim': ad, 'sehir': 'Türkiye', 'secili': secili ? 'true' : 'false'})!;

void main() {
  group('fromMap / toMap (depolama biçimi değişmedi)', () {
    test('uygulamanın ilk kurulumdaki İstanbul kaydı (tur yok, lat/lon var)',
        () {
      final s = KayitliSehir.fromMap({
        'isim': 'İstanbul',
        'sehir': 'Türkiye',
        'lat': 41.0082,
        'lon': 28.9784,
        'secili': 'true',
      })!;

      expect(s.isim, 'İstanbul');
      expect(s.ulke, 'Türkiye');
      expect(s.tur, '');
      expect(s.secili, isTrue);
      expect(s.konum.diyanetIlceId, 9541);
      expect(s.konum.enlem, 41.0082);
      expect(s.kimlik, KayitliSehir.varsayilan.kimlik);
    });

    test('yurt dışı kaydı tam konumuyla gidip gelir; Türkiye ili konum yazmaz',
        () {
      final a = _yabanci('Birmingham', 100, secili: true);
      final geri = KayitliSehir.fromMap(a.toMap())!;

      expect(a.toMap()['konum'], isA<Map>());
      expect(a.toMap()['secili'], 'true');
      expect(geri.kimlik, a.kimlik);
      expect(geri.konum.saatDilimi, 'America/Chicago');
      expect(geri.tur, 'Diyanet Takvimi');

      final ankara = _il('Ankara');
      expect(ankara.toMap().containsKey('konum'), isFalse);
      expect(ankara.toMap()['secili'], 'false');
    });

    test(
        'secili: "true" metni ve gerçek bool kabul edilir, başka her şey false',
        () {
      bool oku(Object? v) =>
          KayitliSehir.fromMap({'isim': 'Van', 'secili': v})!.secili;
      expect(oku('true'), isTrue);
      expect(oku(true), isTrue);
      expect(oku('false'), isFalse);
      expect(oku(null), isFalse);
      expect(oku('evet'), isFalse);
    });

    test('81 ilin hepsi depolanıp geri okunur', () {
      for (final il in CityData.allCities) {
        final geri = KayitliSehir.fromMap(_il(il).toMap());
        expect(geri, isNotNull, reason: il);
        expect(geri!.isim, il);
        expect(geri.kimlik, _il(il).kimlik, reason: il);
      }
    });

    test('anlaşılamayan kayıt null döner', () {
      expect(KayitliSehir.fromMap({'isim': 'Atlantis'}), isNull);
      expect(KayitliSehir.fromMap({'isim': 42}), isNull);
      expect(KayitliSehir.fromMap({}), isNull);
    });
  });

  group('kimlik', () {
    test('aynı adlı iki yabancı yer ve aynı adlı il/yabancı yer ayrı sayılır',
        () {
      expect(_yabanci('Birmingham', 1).kimlik,
          isNot(_yabanci('Birmingham', 2).kimlik));
      expect(_yabanci('Van', 5).kimlik, isNot(_il('Van').kimlik));
      expect(_il('Van').kimlik, _il('Van').kimlik);
    });
  });

  group('listeCoz', () {
    test('bozuk satırlar atlanır, geçerliler kalır', () {
      final l = KayitliSehir.listeCoz([
        {'isim': 'Ankara', 'secili': 'true'},
        'bozuk',
        {'isim': 'Atlantis'},
        {'isim': 'İzmir'},
      ]);
      expect(l.map((s) => s.isim), ['Ankara', 'İzmir']);
    });

    test('hiç geçerli kayıt yoksa (null, boş, bozuk) varsayılan İstanbul', () {
      for (final ham in [
        null,
        <Object>[],
        'x',
        [42],
        [
          {'isim': 'Atlantis'}
        ]
      ]) {
        final l = KayitliSehir.listeCoz(ham);
        expect(l, hasLength(1), reason: '$ham');
        expect(l.single.isim, 'İstanbul');
        expect(l.single.secili, isTrue);
      }
    });

    test('tam bir şehir seçili olur: hiç yoksa ilki, birden çoksa ilk seçili',
        () {
      final hicYok = KayitliSehir.listeCoz([
        {'isim': 'Ankara'},
        {'isim': 'İzmir'}
      ]);
      expect(hicYok.map((s) => s.secili), [true, false]);

      final cok = KayitliSehir.listeCoz([
        {'isim': 'Ankara'},
        {'isim': 'İzmir', 'secili': 'true'},
        {'isim': 'Van', 'secili': 'true'},
      ]);
      expect(cok.map((s) => s.secili), [false, true, false]);
    });
  });

  group('liste işlemleri', () {
    final ankara = _il('Ankara', secili: true);
    final izmir = _il('İzmir');
    final bhamAl = _yabanci('Birmingham', 1);
    final bhamUk = _yabanci('Birmingham', 2);

    test('secerek yalnızca istenen kimliği seçili yapar', () {
      final l = [ankara, izmir, bhamAl].secerek(izmir.kimlik);
      expect(l.map((s) => s.secili), [false, true, false]);
      expect(l.seciliOlan.isim, 'İzmir');
    });

    test('ekleyipSecerek: yeni yer eklenir ve seçilir, eskiler seçili kalmaz',
        () {
      final l = [ankara, izmir].ekleyipSecerek(bhamAl);
      expect(l.map((s) => s.isim), ['Ankara', 'İzmir', 'Birmingham']);
      expect(l.map((s) => s.secili), [false, false, true]);
    });

    test(
        'ekleyipSecerek: aynı yer tekrar eklenmez; aynı adlı başka yer eklenir',
        () {
      final ilk = [ankara, bhamAl];
      final ayni = ilk.ekleyipSecerek(_yabanci('Birmingham', 1));
      expect(ayni, hasLength(2));
      expect(ayni.seciliOlan.kimlik, bhamAl.kimlik);

      final baska = ilk.ekleyipSecerek(bhamUk);
      expect(baska, hasLength(3));
      expect(baska.seciliOlan.kimlik, bhamUk.kimlik);
    });

    test('cikararak: seçili olmayan çıkınca seçim korunur', () {
      final l = [ankara, izmir, bhamAl].cikararak(izmir.kimlik);
      expect(l.map((s) => s.isim), ['Ankara', 'Birmingham']);
      expect(l.seciliOlan.isim, 'Ankara');
    });

    test(
        'cikararak: seçili çıkınca ilk şehir seçilir (hiçbiri seçili kalmaz diye bir durum yok)',
        () {
      final l = [ankara, izmir].cikararak(ankara.kimlik);
      expect(l.map((s) => s.isim), ['İzmir']);
      expect(l.single.secili, isTrue);
    });

    test('cikararak: son kalan şehir çıkarılamaz', () {
      final tek = [ankara];
      expect(tek.cikararak(ankara.kimlik), tek);
    });

    test('işlemler eldeki listeyi değiştirmez', () {
      final l = [ankara, izmir];
      l.secerek(izmir.kimlik);
      l.ekleyipSecerek(bhamAl);
      l.cikararak(izmir.kimlik);
      expect(l.map((s) => s.secili), [true, false]);
      expect(l, hasLength(2));
    });
  });
}
