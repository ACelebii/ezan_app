import 'package:timezone/timezone.dart' as tz;

import '../../../core/vakit/zaman_dilimi.dart';

/// Ayarlar > "Bildirimleri Ertele" seçiminin bitiş anı.
///
/// Seçenekler: "1 saat", "2 saat", "4 saat", "8 saat", "1 Gün", "7 Gün",
/// "10 Gün" ([simdi]den itibaren) ya da tarih seçicinin verdiği "7/10/2026"
/// (o günün başı, [saatDilimi]nde — telefonun bulunduğu yer değil, seçili
/// şehrin saat dilimi; projenin geri kalanı hep buna göre çalışıyor).
/// "Kapalı", tanınmayan bir seçim ya da geçmişte kalan bir tarih için null
/// döner: erteleme yok.
///
/// Dönen an UTC'dir. Bu ana kadar hiçbir bildirim çalmaz; sonrakiler çalar.
DateTime? ertelemeBitisi(String secim, DateTime simdi,
    {required String saatDilimi}) {
  final sure = RegExp(r'^\s*(\d+)\s*(saat|gün)\s*$', caseSensitive: false)
      .firstMatch(secim);
  if (sure != null) {
    final sayi = int.parse(sure.group(1)!);
    final saatMi = sure.group(2)!.toLowerCase() == 'saat';
    return simdi
        .toUtc()
        .add(saatMi ? Duration(hours: sayi) : Duration(days: sayi));
  }

  final tarih =
      RegExp(r'^\s*(\d{1,2})/(\d{1,2})/(\d{4})\s*$').firstMatch(secim);
  if (tarih != null) {
    final gun = int.parse(tarih.group(1)!);
    final ay = int.parse(tarih.group(2)!);
    final yil = int.parse(tarih.group(3)!);
    zamanDilimleriniHazirla();
    final bitis = tz.TZDateTime(tz.getLocation(saatDilimi), yil, ay, gun);
    // 31/02/2026 gibi taşan tarihleri reddet.
    if (bitis.month != ay || bitis.day != gun) return null;
    return bitis.toUtc().isAfter(simdi.toUtc()) ? bitis.toUtc() : null;
  }
  return null;
}
