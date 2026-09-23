import 'package:timezone/data/latest.dart' as tz_data;

bool _hazir = false;

/// `timezone` veritabanını (IANA saat dilimleri) bir kez yükler; tekrar
/// çağrılması bedavadır. Saat dilimini kullanan her yer, kullanmadan önce bunu
/// çağırmalıdır: yoksa `tz.getLocation`, veritabanı yüklenmediği için hata
/// verir. Uygulama başlangıcındaki sıraya güvenilmez (ana ekran, bildirim
/// servisinden önce vakit yükleyebilir).
void zamanDilimleriniHazirla() {
  if (_hazir) return;
  tz_data.initializeTimeZones();
  _hazir = true;
}
