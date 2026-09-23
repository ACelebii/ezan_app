// Uygulamadaki 81 ilin Diyanet ilçe kodları ve kayıtlı şehirden `Konum` üretimi.
//
// Kodlar EzanVakti API'den (ezanvakti.emushaf.net) 20.09.2026'da alındı: her
// ilde il adıyla aynı adı taşıyan merkez ilçe. Bkz. plans/faz1_dogruluk_plani.md.
// Hepsinin saat dilimi Europe/Istanbul'dur.

import 'package:timezone/timezone.dart' as tz;

import 'vakit_modelleri.dart';
import 'zaman_dilimi.dart';

/// İl adı (uygulamadaki yazım, `CityData.allCities`) → Diyanet ilçe kodu.
const diyanetIlceKodlari = <String, int>{
  'Adana': 9146,
  'Adıyaman': 9158,
  'Afyonkarahisar': 9167,
  'Ağrı': 9185,
  'Aksaray': 9193,
  'Amasya': 9198,
  'Ankara': 9206,
  'Antalya': 9225,
  'Ardahan': 9238,
  'Artvin': 9246,
  'Aydın': 9252,
  'Balıkesir': 9270,
  'Bartın': 9285,
  'Batman': 9288,
  'Bayburt': 9295,
  'Bilecik': 9297,
  'Bingöl': 9303,
  'Bitlis': 9311,
  'Bolu': 9315,
  'Burdur': 9327,
  'Bursa': 9335,
  'Çanakkale': 9352,
  'Çankırı': 9359,
  'Çorum': 9370,
  'Denizli': 9392,
  'Diyarbakır': 9402,
  'Düzce': 9414,
  'Edirne': 9419,
  'Elazığ': 9432,
  'Erzincan': 9440,
  'Erzurum': 9451,
  'Eskişehir': 9470,
  'Gaziantep': 9479,
  'Giresun': 9494,
  'Gümüşhane': 9501,
  'Hakkari': 9507,
  'Hatay': 20089,
  'Iğdır': 9522,
  'Isparta': 9528,
  'İstanbul': 9541,
  'İzmir': 9560,
  'Kahramanmaraş': 9577,
  'Karabük': 9581,
  'Karaman': 9587,
  'Kars': 9594,
  'Kastamonu': 9609,
  'Kayseri': 9620,
  'Kilis': 9629,
  'Kırıkkale': 9635,
  'Kırklareli': 9638,
  'Kırşehir': 9646,
  'Kocaeli': 9654,
  'Konya': 9676,
  'Kütahya': 9689,
  'Malatya': 9703,
  'Manisa': 9716,
  'Mardin': 9726,
  'Mersin': 9737,
  'Muğla': 9747,
  'Muş': 9755,
  'Nevşehir': 9760,
  'Niğde': 9766,
  'Ordu': 9782,
  'Osmaniye': 9788,
  'Rize': 9799,
  'Sakarya': 9807,
  'Samsun': 9819,
  'Şanlıurfa': 9831,
  'Siirt': 9839,
  'Sinop': 9847,
  'Şırnak': 9854,
  'Sivas': 9868,
  'Tekirdağ': 9879,
  'Tokat': 9887,
  'Trabzon': 9905,
  'Tunceli': 9914,
  'Uşak': 9919,
  'Van': 9930,
  'Yalova': 9935,
  'Yozgat': 9949,
  'Zonguldak': 9955,
};

/// `AuthService.kayitliSehirler` içindeki bir kaydı (`{isim, sehir, lat, lon,
/// konum, ...}`) [Konum]a çevirir; çeviremezse null döner.
///
/// Dünya listesinden eklenen yerin kaydı tam `konum` (bkz. [Konum.toJson])
/// taşır ve önceliklidir; saat dilimi geçersizse (bozuk kayıt) null döner ki
/// ana ekran çökmesin. Türkiye'deki il kayıtları yalnızca `isim` taşır: kod
/// tablodan bulunur. Koordinat (`lat`/`lon`) yalnızca varsayılan İstanbul
/// kaydında vardır; varsa yedek kaynak (Aladhan) onu kullanır.
Konum? kayittanKonum(Map<String, dynamic> kayit) {
  final ham = kayit['konum'];
  if (ham is Map) {
    try {
      final konum = Konum.fromJson(Map<String, dynamic>.from(ham));
      zamanDilimleriniHazirla();
      tz.getLocation(konum.saatDilimi);
      return konum;
    } catch (_) {
      return null;
    }
  }

  final ad = kayit['isim'];
  final ilceId = ad is String ? diyanetIlceKodlari[ad] : null;
  if (ad is! String || ilceId == null) return null;

  final enlem = kayit['lat'];
  final boylam = kayit['lon'];
  final koordinatVar = enlem is num && boylam is num;
  return Konum(
    ad: ad,
    saatDilimi: 'Europe/Istanbul',
    diyanetIlceId: ilceId,
    enlem: koordinatVar ? enlem.toDouble() : null,
    boylam: koordinatVar ? boylam.toDouble() : null,
  );
}
