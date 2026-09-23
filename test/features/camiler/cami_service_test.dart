import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:ezan_vakti_uygulamasi/core/api_client.dart';
import 'package:ezan_vakti_uygulamasi/features/camiler/cami_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ağa çıkmadan, verilen durum koduyla verilen gövdeyi döndürür ve son isteği saklar.
class _SahteAdaptor implements HttpClientAdapter {
  _SahteAdaptor(this.kod, this.govde);

  final int kod;
  final String govde;
  RequestOptions? istek;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    istek = options;
    return ResponseBody.fromString(govde, kod, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

const _anahtar = 'TEST-ANAHTARI-123';

void main() {
  late HttpClientAdapter eskiAdaptor;

  setUp(() {
    dotenv.loadFromString(envString: 'GOOGLE_MAPS_API_KEY=$_anahtar');
    eskiAdaptor = ApiClient.dio.httpClientAdapter;
  });

  tearDown(() => ApiClient.dio.httpClientAdapter = eskiAdaptor);

  _SahteAdaptor kur(int kod, String govde) {
    final a = _SahteAdaptor(kod, govde);
    ApiClient.dio.httpClientAdapter = a;
    return a;
  }

  test('yeni Places ucuna POST atar; anahtar adreste değil başlıkta, alan listesi dar', () async {
    final a = kur(200, '{}');

    await CamiService().getNearbyMosques(41.0082, 28.9784);

    final r = a.istek!;
    expect(r.method, 'POST');
    expect(r.uri.toString(), 'https://places.googleapis.com/v1/places:searchNearby');
    expect(r.uri.toString(), isNot(contains(_anahtar)));
    expect(r.headers['X-Goog-Api-Key'], _anahtar);
    expect(r.headers['X-Goog-FieldMask'],
        'places.id,places.displayName,places.location,places.shortFormattedAddress');
    // Anahtar Cloud Console'da "Android apps" ile kısıtlı; bu iki başlık
    // olmadan Google isteği tanımayıp 403 verir (bkz. google_android_kimlik.dart).
    expect(r.headers['X-Android-Package'], 'com.acelebi.ezanvakti');
    expect(r.headers['X-Android-Cert'], hasLength(40));
    expect(r.headers['X-Android-Cert'], matches(RegExp(r'^[0-9A-Fa-f]{40}$')),
        reason: 'iki nokta üst üste işaretsiz SHA-1 (Google REST başlığı biçimi)');
    final govde = r.data as Map;
    expect(govde['includedTypes'], ['mosque']);
    expect(govde['rankPreference'], 'DISTANCE');
    expect(govde['maxResultCount'], 20);
    final daire = (govde['locationRestriction'] as Map)['circle'] as Map;
    expect(daire['center'], {'latitude': 41.0082, 'longitude': 28.9784});
    expect(daire['radius'], 2000.0);
  });

  test('ayrı PLACES_API_KEY varsa o kullanılır; boşsa harita anahtarına düşer', () async {
    final a = kur(200, '{}');

    dotenv.loadFromString(envString: 'GOOGLE_MAPS_API_KEY=$_anahtar\nPLACES_API_KEY=AYRI-PLACES-9');
    await CamiService().getNearbyMosques(41, 29);
    expect(a.istek!.headers['X-Goog-Api-Key'], 'AYRI-PLACES-9');

    dotenv.loadFromString(envString: 'GOOGLE_MAPS_API_KEY=$_anahtar\nPLACES_API_KEY=');
    await CamiService().getNearbyMosques(41, 29);
    expect(a.istek!.headers['X-Goog-Api-Key'], _anahtar, reason: 'boş PLACES_API_KEY yok sayılır');
  });

  test('yanıttaki camileri okur: ad, koordinat (tam sayı dahil), kısa adres', () async {
    kur(200, '''
{"places":[
  {"id":"A1","displayName":{"text":"Sultanahmet Camii","languageCode":"tr"},
   "location":{"latitude":41.0054,"longitude":28.9768},"shortFormattedAddress":"Fatih/İstanbul"},
  {"id":"B2","location":{"latitude":41,"longitude":29}}
]}''');

    final liste = await CamiService().getNearbyMosques(41.0, 29.0);

    expect(liste.map((c) => c.id), ['A1', 'B2']);
    expect(liste[0].name, 'Sultanahmet Camii');
    expect(liste[0].lat, 41.0054);
    expect(liste[0].lon, 28.9768);
    expect(liste[0].address, 'Fatih/İstanbul');
    expect(liste[1].name, 'Cami', reason: 'adı olmayan kayıt "Cami" olur');
    expect(liste[1].lat, 41.0, reason: 'tam sayı koordinat double olur');
    expect(liste[1].address, isNull);
  });

  test('sonuç yoksa Google "places" göndermez ({}): hata değil, boş liste', () async {
    kur(200, '{}');

    expect(await CamiService().getNearbyMosques(0, 0), isEmpty);
  });

  test('konumu olmayan kayıt atlanır (0,0 okyanus işaretçisi olmaz), diğerleri kalır', () async {
    kur(200, '''
{"places":[
  {"id":"X","displayName":{"text":"Konumsuz"}},
  {"id":"Y","displayName":{"text":"Konumlu"},"location":{"latitude":1.5,"longitude":2.5}}
]}''');

    final liste = await CamiService().getNearbyMosques(1, 2);

    expect(liste.map((c) => c.id), ['Y']);
  });

  test('403 (kısıtlı anahtar) sessiz boş liste değil hata olur ve hata metni anahtarı içermez', () async {
    kur(403, '{"error":{"code":403,"status":"PERMISSION_DENIED","message":"blocked"}}');

    Object? hata;
    try {
      await CamiService().getNearbyMosques(41, 29);
    } catch (e) {
      hata = e;
    }

    expect(hata, isA<DioException>());
    expect(hata.toString(), isNot(contains(_anahtar)));
  });
}
