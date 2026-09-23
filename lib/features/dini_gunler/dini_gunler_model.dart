// Diyanet'in resmi Dini Günler Listesi'nden bir gün.
//
// Veri `assets/json/dini_gunler.json`, `tools/dini_gunler_uret.py` ile Diyanet'in
// sayfalarından üretilir (satır satır doğrulanır). Kandil geceleri, listedeki
// miladi günün AKŞAMI başlar (ör. Miraç Kandili 4 Ocak 2027 = 4 Ocak akşamı).

import 'dart:convert';

const _trAylar = [
  '',
  'Ocak',
  'Şubat',
  'Mart',
  'Nisan',
  'Mayıs',
  'Haziran',
  'Temmuz',
  'Ağustos',
  'Eylül',
  'Ekim',
  'Kasım',
  'Aralık',
];
const _enAylar = [
  '',
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
const _trHafta = [
  '',
  'Pazartesi',
  'Salı',
  'Çarşamba',
  'Perşembe',
  'Cuma',
  'Cumartesi',
  'Pazar',
];
const _enHafta = [
  '',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// Hicri ay adları: uygulamadaki Türkçe yazım -> İngilizce.
const _hicriAyEn = {
  'Muharrem': 'Muharram',
  'Safer': 'Safar',
  'Rebiülevvel': "Rabi' al-awwal",
  'Rebiülahir': "Rabi' al-thani",
  'Cemaziyelevvel': 'Jumada al-awwal',
  'Cemaziyelahir': 'Jumada al-thani',
  'Recep': 'Rajab',
  'Şaban': "Sha'ban",
  'Ramazan': 'Ramadan',
  'Şevval': 'Shawwal',
  'Zilkade': "Dhu al-Qi'dah",
  'Zilhicce': 'Dhu al-Hijjah',
};

class DiniGunlerModel {
  DiniGunlerModel({
    required this.tarih,
    required this.tur,
    required this.hicri,
    required this.baslik,
    required this.baslikEn,
    required this.detay,
    required this.detayEn,
  });

  /// Listedeki miladi gün (UTC, saat yok).
  final DateTime tarih;

  /// Tür anahtarı, ör. `regaib`, `kurban_bayrami_2`.
  final String tur;

  /// Diyanet'in hicri tarihi, ör. "26 Recep 1447".
  final String hicri;

  final String baslik;
  final String baslikEn;
  final String detay;
  final String detayEn;

  int get yil => tarih.year;

  /// Türkçe ay adı; aylara gruplamada anahtar olarak da kullanılır.
  String get ay => _trAylar[tarih.month];

  String get gunNo => tarih.day.toString().padLeft(2, '0');

  String get haftaGunu => _trHafta[tarih.weekday];

  /// Gece olarak anılan günler (Diyanet bunları listedeki günün AKŞAMI
  /// başlayan gece olarak verir).
  bool get kandil =>
      const {'regaib', 'miraç', 'berat', 'kadir', 'mevlid'}.contains(tur);

  /// "4 Ocak 2027, Pazartesi" / "Monday, January 4, 2027".
  String tarihFor(bool ingilizce) => ingilizce
      ? '${haftaGunuFor(true)}, ${ayFor(true)} ${tarih.day}, $yil'
      : '${tarih.day} $ay $yil, $haftaGunu';

  /// Yalnızca kandil/gece günlerinde; diğerlerinde null.
  String? geceNotu(bool ingilizce) => !kandil
      ? null
      : (ingilizce
          ? 'The night begins on the evening of this day.'
          : 'Gece, bu günün akşamı başlar.');

  String baslikFor(bool ingilizce) => ingilizce ? baslikEn : baslik;

  String detayFor(bool ingilizce) => ingilizce ? detayEn : detay;

  String ayFor(bool ingilizce) => ayAdi(ay, ingilizce);

  String haftaGunuFor(bool ingilizce) =>
      ingilizce ? _enHafta[tarih.weekday] : haftaGunu;

  /// "26 Recep 1447" -> "26 Rajab 1447".
  String hicriFor(bool ingilizce) {
    if (!ingilizce) return hicri;
    final parcalar = hicri.split(' ');
    if (parcalar.length < 3) return hicri;
    final ay = parcalar.sublist(1, parcalar.length - 1).join(' ');
    return '${parcalar.first} ${_hicriAyEn[ay] ?? ay} ${parcalar.last}';
  }

  /// Türkçe ay adının ([trAy]) istenen dildeki karşılığı.
  static String ayAdi(String trAy, bool ingilizce) {
    if (!ingilizce) return trAy;
    final i = _trAylar.indexOf(trAy);
    return i < 0 ? trAy : _enAylar[i];
  }

  /// `dini_gunler.json` metnini gün listesine çevirir (tarih sırasıyla).
  /// Bozuk bir kayıt sessizce atlanmaz: veri hatası sayılır ve fırlatılır.
  static List<DiniGunlerModel> listeCoz(String metin) {
    final kok = jsonDecode(metin) as Map<String, dynamic>;
    final tanimlar = kok['tanimlar'] as Map<String, dynamic>;
    final gunler = <DiniGunlerModel>[];
    for (final ham in kok['gunler'] as List<dynamic>) {
      final gun = ham as Map<String, dynamic>;
      final tur = gun['tur'] as String;
      // "kurban_bayrami_2" -> tanım "kurban_bayrami", numara 2.
      final eslesme = RegExp(r'^(.*)_(\d)$').firstMatch(tur);
      final tanimAnahtari = eslesme?.group(1) ?? tur;
      final tanim = tanimlar[tanimAnahtari] as Map<String, dynamic>?;
      if (tanim == null) {
        throw FormatException('Dini gün türünün tanımı yok: $tur');
      }
      final no = eslesme?.group(2);
      final t = DateTime.parse(gun['tarih'] as String);
      gunler.add(DiniGunlerModel(
        tarih: DateTime.utc(t.year, t.month, t.day),
        tur: tur,
        hicri: gun['hicri'] as String,
        baslik: '${tanim['baslik']}${no == null ? '' : ' ($no. Gün)'}',
        baslikEn: '${tanim['baslikEn']}${no == null ? '' : ' (Day $no)'}',
        detay: tanim['detay'] as String,
        detayEn: tanim['detayEn'] as String,
      ));
    }
    gunler.sort((a, b) => a.tarih.compareTo(b.tarih));
    return gunler;
  }
}
