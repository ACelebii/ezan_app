import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/api_client.dart';
import '../../core/google_android_kimlik.dart';
import 'cami_model.dart';

/// Yakındaki camileri Google Places API (New) ile bulur.
///
/// Eski `maps/api/place/nearbysearch` (Places API Legacy) yeni projelerde
/// kapalı geliyor; bu sınıf `places:searchNearby` ucunu kullanır. Anahtar
/// adrese değil başlığa konur; böylece bir hata iletisine ya da günlüğe
/// (Dio istisnaları adresi yazar) sızmaz.
class CamiService {
  CamiService({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  /// Yalnızca bu alanlar istenir: Google, faturayı istenen alanlara göre keser.
  static const _alanlar =
      'places.id,places.displayName,places.location,places.shortFormattedAddress';

  /// Places çağrısının anahtarı: `PLACES_API_KEY`; yoksa harita anahtarına
  /// (`GOOGLE_MAPS_API_KEY`) düşer. Ayrı anahtar, Places kısıtları düzenlenirken
  /// haritanın ("Maps SDK for Android") bozulmasını önler; ikisi de tanımlı
  /// değilse boş döner ve Google 403 verir (sessiz boş liste olmaz).
  @visibleForTesting
  static String anahtar() {
    final places = dotenv.env['PLACES_API_KEY'] ?? '';
    return places.isNotEmpty ? places : dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  }

  Future<List<Cami>> getNearbyMosques(double lat, double lon) async {
    final apiKey = anahtar();
    // Başarısız yanıt (403 kısıtlı anahtar, 429 kota...) Dio'da DioException
    // olarak fırlar; "yakında cami yok" gibi sessiz bir boş liste dönmez.
    final response = await _dio.post(
      'v1/places:searchNearby',
      options: Options(headers: {
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask': _alanlar,
        // Anahtar Cloud Console'da "Android apps" (paket adı + SHA-1) ile
        // kısıtlı; bu iki başlık olmadan Google isteği tanımayıp 403 verir.
        'X-Android-Package': googleAndroidPaket,
        'X-Android-Cert': googleAndroidSertifika,
      }),
      data: {
        'includedTypes': ['mosque'],
        'maxResultCount': 20,
        // Varsayılan sıralama "popülerlik"; "Yakın Camiler" için en yakın önce.
        'rankPreference': 'DISTANCE',
        'languageCode': 'tr',
        'locationRestriction': {
          'circle': {
            'center': {'latitude': lat, 'longitude': lon},
            'radius': 2000.0,
          },
        },
      },
    );

    // Sonuç yoksa Google "places" alanını hiç göndermez ({}), bu hata değildir.
    final data = response.data;
    final List results = (data is Map ? data['places'] : null) as List? ?? [];
    final mosques = <Cami>[];
    for (final e in results) {
      try {
        mosques.add(Cami.fromJson(e as Map<String, dynamic>));
      } catch (_) {
        // Tek bir bozuk kayıt (beklenmeyen alan tipi/eksik konum) tüm
        // listeyi düşürmesin; sadece o kayıt atlanır.
      }
    }
    return mosques;
  }
}
