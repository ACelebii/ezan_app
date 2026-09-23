// Kullanıcının kaydettiği şehir (Ayarlar > Şehirler listesindeki bir satır).
//
// Şehirler eskiden `Map<String, dynamic>` olarak dolaşıyordu ve "seçili" bayrağı
// `"true"`/`"false"` METNİYLE tutuluyordu. Bu sınıf bellekteki temsili tiplendirir;
// DEPOLAMA BİÇİMİ (SharedPreferences ve Firestore) değişmedi, bu yüzden mevcut
// kullanıcıların kayıtları aynen okunur ([fromMap]/[toMap]).

import 'il_kodlari.dart';
import 'vakit_modelleri.dart';

class KayitliSehir {
  const KayitliSehir({
    required this.isim,
    required this.ulke,
    required this.konum,
    this.tur = '',
    this.secili = false,
  });

  /// Hiç ya da hiçbir geçerli kayıt yokken kullanılan şehir.
  static const varsayilan = KayitliSehir(
    isim: 'İstanbul',
    ulke: 'Türkiye',
    secili: true,
    konum: Konum(
      ad: 'İstanbul',
      saatDilimi: 'Europe/Istanbul',
      diyanetIlceId: 9541,
      enlem: 41.0082,
      boylam: 28.9784,
    ),
  );

  /// Ekranda görünen ad.
  final String isim;

  /// Adın altında yazan ülke ("Türkiye", "Amerika Birleşik Devletleri").
  final String ulke;

  /// Vakitlerin hesaplandığı yer: Diyanet ilçe kodu, koordinat, saat dilimi.
  final Konum konum;

  /// Şehir eklenirken seçili olan hesaplama yönteminin adı (eski kayıtlarda boş).
  final String tur;

  final bool secili;

  /// Şehri ayırt eden kimlik. Ad değil, yerin kendisi: aynı adlı iki yer
  /// (Birmingham/Alabama ve Birmingham/İngiltere) farklı çıkar.
  String get kimlik => konum.anahtar;

  KayitliSehir kopya({bool? secili}) => KayitliSehir(
        isim: isim,
        ulke: ulke,
        konum: konum,
        tur: tur,
        secili: secili ?? this.secili,
      );

  /// Depolanan biçimden okur; anlaşılamıyorsa (bozuk kayıt, bilinmeyen il) null.
  static KayitliSehir? fromMap(Map<String, dynamic> kayit) {
    final isim = kayit['isim'];
    final konum = kayittanKonum(kayit);
    if (isim is! String || konum == null) return null;
    final ulke = kayit['sehir'];
    final tur = kayit['tur'];
    final secili = kayit['secili'];
    return KayitliSehir(
      isim: isim,
      ulke: ulke is String ? ulke : konum.ulke,
      konum: konum,
      tur: tur is String ? tur : '',
      secili: secili == 'true' || secili == true,
    );
  }

  /// Eski depolama biçimi: `secili` metin, Türkiye'deki ilde yalnızca ad (koordinat
  /// varsa `lat`/`lon`), diğer yerlerde tam `konum`.
  Map<String, dynamic> toMap() {
    final il = diyanetIlceKodlari[isim] == konum.diyanetIlceId &&
        konum.saatDilimi == 'Europe/Istanbul';
    return {
      'isim': isim,
      'sehir': ulke,
      if (tur.isNotEmpty) 'tur': tur,
      'secili': secili ? 'true' : 'false',
      if (il && konum.koordinatVar) ...{
        'lat': konum.enlem,
        'lon': konum.boylam
      },
      if (!il) 'konum': konum.toJson(),
    };
  }

  /// Depolanan listeyi okur. Anlaşılamayan satırlar atlanır; hiç satır kalmazsa
  /// [varsayilan]. Sonuçta TAM BİR şehir seçilidir (hiç yoksa ilki, birden çoksa
  /// ilk seçili).
  static List<KayitliSehir> listeCoz(Object? ham) {
    final liste = <KayitliSehir>[];
    if (ham is List) {
      for (final e in ham) {
        if (e is! Map) continue;
        final sehir = fromMap(Map<String, dynamic>.from(e));
        if (sehir != null) liste.add(sehir);
      }
    }
    if (liste.isEmpty) return [varsayilan];
    final i = liste.indexWhere((s) => s.secili);
    final secilen = i < 0 ? 0 : i;
    return [
      for (var k = 0; k < liste.length; k++)
        liste[k].kopya(secili: k == secilen),
    ];
  }
}

/// Şehir listesi işlemleri. Hepsi YENİ bir liste döndürür.
extension KayitliSehirListesi on List<KayitliSehir> {
  KayitliSehir get seciliOlan =>
      firstWhere((s) => s.secili, orElse: () => first);

  /// [kimlik]teki şehri seçili yapar, diğerlerini kaldırır.
  List<KayitliSehir> secerek(String kimlik) =>
      [for (final s in this) s.kopya(secili: s.kimlik == kimlik)];

  /// [yeni]yi listeye ekleyip seçer. Aynı yer zaten varsa tekrar eklenmez,
  /// yalnızca o seçilir.
  List<KayitliSehir> ekleyipSecerek(KayitliSehir yeni) =>
      any((s) => s.kimlik == yeni.kimlik)
          ? secerek(yeni.kimlik)
          : [...map((s) => s.kopya(secili: false)), yeni.kopya(secili: true)];

  /// [kimlik]teki şehri çıkarır. Seçili şehir çıkarsa ilk şehir seçilir (aksi
  /// halde hiçbiri seçili görünmezdi). Son kalan şehir çıkarılamaz.
  List<KayitliSehir> cikararak(String kimlik) {
    if (length <= 1) return this;
    final kalan = where((s) => s.kimlik != kimlik).toList();
    return kalan.any((s) => s.secili)
        ? kalan
        : kalan.secerek(kalan.first.kimlik);
  }
}
