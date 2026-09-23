// Namaz vakitleriyle ilgili veri modelleri.
//
// Bu dosyada Flutter'a ait hiçbir şey yok, yalnızca saf Dart var. Bu sayede
// modeller telefona gerek kalmadan, birim testleriyle saniyeler içinde
// denenebilir (bkz. test/core/vakit/vakit_modelleri_test.dart).

/// Günün altı vakti, Diyanet takvimindeki sırasıyla.
enum Vakit {
  imsak('İmsak'),
  gunes('Güneş'),
  ogle('Öğle'),
  ikindi('İkindi'),
  aksam('Akşam'),
  yatsi('Yatsı');

  const Vakit(this.ad);

  /// Ekranda gösterilecek Türkçe ad.
  final String ad;
}

/// Vakitlerin nereden geldiği.
enum VakitKaynagi {
  /// Diyanet'in yayınladığı saatler (EzanVakti API üzerinden).
  diyanet,

  /// Aladhan'ın hesapladığı saatler. Diyanet'e ulaşılamadığında yedek olarak
  /// kullanılır; Diyanet'ten 1-2 dakika farklı olabilir.
  aladhan,
}

/// Vakitlerin gösterildiği yer.
///
/// Diyanet saatleri için [diyanetIlceId] gerekir. Yedek hesaplama (Aladhan)
/// koordinat varsa koordinatla, yoksa şehir adıyla ([ad] + [ulke]) yapılır.
class Konum {
  const Konum({
    required this.ad,
    required this.saatDilimi,
    this.ulke = 'Türkiye',
    this.diyanetIlceId,
    this.enlem,
    this.boylam,
  }) : assert(diyanetIlceId != null || (enlem != null && boylam != null),
            'Konumun ya Diyanet ilçe kodu ya da koordinatı olmalı.');

  /// Ekranda görünen ad, ör. "İstanbul".
  final String ad;

  /// Ülke adı, ör. "Türkiye".
  final String ulke;

  /// IANA saat dilimi, ör. "Europe/Istanbul". Vakitlerin gerçek anını
  /// (geri sayım ve bildirim için) hesaplarken kullanılır.
  final String saatDilimi;

  /// Diyanet'in ilçe kodu, ör. İstanbul için 9541.
  final int? diyanetIlceId;

  final double? enlem;
  final double? boylam;

  bool get koordinatVar => enlem != null && boylam != null;

  /// Önbellekte bu yeri tanımlayan metin. Aynı yer için hep aynıdır.
  String get anahtar => diyanetIlceId != null
      ? 'diyanet-$diyanetIlceId'
      : 'koordinat-${enlem!.toStringAsFixed(3)},${boylam!.toStringAsFixed(3)}';

  Map<String, dynamic> toJson() => {
        'ad': ad,
        'ulke': ulke,
        'saatDilimi': saatDilimi,
        if (diyanetIlceId != null) 'diyanetIlceId': diyanetIlceId,
        if (enlem != null) 'enlem': enlem,
        if (boylam != null) 'boylam': boylam,
      };

  factory Konum.fromJson(Map<String, dynamic> json) => Konum(
        ad: json['ad'] as String,
        ulke: json['ulke'] as String? ?? 'Türkiye',
        saatDilimi: json['saatDilimi'] as String,
        diyanetIlceId: (json['diyanetIlceId'] as num?)?.toInt(),
        enlem: (json['enlem'] as num?)?.toDouble(),
        boylam: (json['boylam'] as num?)?.toDouble(),
      );
}

/// Bir günün altı vakti.
class GunlukVakit {
  GunlukVakit({
    required this.tarih,
    required Map<Vakit, String> saatler,
    required Map<Vakit, DateTime> anlar,
    required this.kaynak,
    this.hicriTarih,
  })  : assert(tarih.isUtc && tarih.hour == 0 && tarih.minute == 0,
            'tarih, DateTime.utc(yıl, ay, gün) biçiminde olmalı.'),
        assert(Vakit.values.every(saatler.containsKey) &&
            Vakit.values.every(anlar.containsKey)),
        saatler = Map.unmodifiable(saatler),
        anlar = Map.unmodifiable({
          for (final e in anlar.entries) e.key: e.value.toUtc(),
        });

  /// O yerin takvimine göre gün. Saat taşımaz: `DateTime.utc(yıl, ay, gün)`.
  final DateTime tarih;

  /// Ekranda gösterilecek saatler, o yerin yerel saatiyle ("05:15").
  final Map<Vakit, String> saatler;

  /// Her vaktin gerçek anı (UTC). Geri sayım ve bildirimler bunu kullanır;
  /// böylece telefon başka bir saat dilimindeyken bile doğru çalışır.
  final Map<Vakit, DateTime> anlar;

  final VakitKaynagi kaynak;

  /// Hicri tarih, ör. "8 Rebiulahir 1448".
  final String? hicriTarih;

  /// Vakitleri dakika kaydırılmış yeni gün (temkin düzeltmesi). Ekranda görünen
  /// saat metinleri de aynı miktarda kayar.
  GunlukVakit duzelt(Map<Vakit, int> dakika) {
    if (dakika.values.every((d) => d == 0)) return this;
    return GunlukVakit(
      tarih: tarih,
      kaynak: kaynak,
      hicriTarih: hicriTarih,
      saatler: {
        for (final v in Vakit.values)
          v: _saatKaydir(saatler[v]!, dakika[v] ?? 0),
      },
      anlar: {
        for (final v in Vakit.values)
          v: anlar[v]!.add(Duration(minutes: dakika[v] ?? 0)),
      },
    );
  }

  /// [vakit]in saatini ve anını [baska] günden alır (ör. Hanefi ikindisi).
  GunlukVakit vakitiAl(Vakit vakit, GunlukVakit baska) => GunlukVakit(
        tarih: tarih,
        kaynak: kaynak,
        hicriTarih: hicriTarih,
        saatler: {...saatler, vakit: baska.saatler[vakit]!},
        anlar: {...anlar, vakit: baska.anlar[vakit]!},
      );

  Map<String, dynamic> toJson() => {
        'tarih': gunAnahtari(tarih),
        'kaynak': kaynak.name,
        if (hicriTarih != null) 'hicri': hicriTarih,
        'saatler': {for (final v in Vakit.values) v.name: saatler[v]},
        'anlar': {
          for (final v in Vakit.values) v.name: anlar[v]!.millisecondsSinceEpoch
        },
      };

  factory GunlukVakit.fromJson(Map<String, dynamic> json) {
    final saatler = json['saatler'] as Map<String, dynamic>;
    final anlar = json['anlar'] as Map<String, dynamic>;
    return GunlukVakit(
      tarih: gunAnahtariniCoz(json['tarih'] as String)!,
      kaynak: VakitKaynagi.values.byName(json['kaynak'] as String),
      hicriTarih: json['hicri'] as String?,
      saatler: {for (final v in Vakit.values) v: saatler[v.name] as String},
      anlar: {
        for (final v in Vakit.values)
          v: DateTime.fromMillisecondsSinceEpoch((anlar[v.name] as num).toInt(),
              isUtc: true),
      },
    );
  }
}

/// "05:15" metnini [dakika] kadar kaydırır (gün sınırında 24 saate sarar).
String _saatKaydir(String saat, int dakika) {
  final s = saatDakikaCoz(saat)!;
  final toplam = ((s.saat * 60 + s.dakika + dakika) % 1440 + 1440) % 1440;
  return '${(toplam ~/ 60).toString().padLeft(2, '0')}:'
      '${(toplam % 60).toString().padLeft(2, '0')}';
}

/// Belirli bir andaki durum: içinde bulunulan vakit ve sıradaki vakit.
class VakitDurumu {
  const VakitDurumu({
    required this.siradaki,
    required this.siradakiAn,
    this.simdiki,
    this.simdikiBaslangic,
  });

  /// Sıradaki vakit ve başlayacağı an (UTC).
  final Vakit siradaki;
  final DateTime siradakiAn;

  /// İçinde bulunulan vakit ve başladığı an. Veri, içinde bulunulan vaktin
  /// başlangıcını kapsamıyorsa null olabilir.
  final Vakit? simdiki;
  final DateTime? simdikiBaslangic;

  /// Sıradaki vakte kalan süre.
  Duration kalan(DateTime simdi) => siradakiAn.difference(simdi);

  /// İçinde bulunulan vaktin ne kadarının geçtiği (0.0 ile 1.0 arası).
  double ilerleme(DateTime simdi) {
    final baslangic = simdikiBaslangic;
    if (baslangic == null) return 0;
    final toplam = siradakiAn.difference(baslangic).inSeconds;
    if (toplam <= 0) return 0;
    final gecen = simdi.difference(baslangic).inSeconds;
    return (gecen / toplam).clamp(0.0, 1.0).toDouble();
  }
}

/// [gunler] içindeki vakitlere bakarak [simdi] anındaki durumu bulur.
///
/// Gün sınırlarını kendiliğinden aşar: yatsıdan sonra sıradaki vakit, listede
/// varsa ertesi günün imsakidir. Sıradaki vakti bulmaya yetecek veri yoksa
/// null döner.
VakitDurumu? vakitDurumu(Iterable<GunlukVakit> gunler, DateTime simdi) {
  final anlar = <(Vakit, DateTime)>[
    for (final gun in gunler)
      for (final vakit in Vakit.values) (vakit, gun.anlar[vakit]!),
  ]..sort((a, b) => a.$2.compareTo(b.$2));

  for (var i = 0; i < anlar.length; i++) {
    if (anlar[i].$2.isAfter(simdi)) {
      final onceki = i > 0 ? anlar[i - 1] : null;
      return VakitDurumu(
        siradaki: anlar[i].$1,
        siradakiAn: anlar[i].$2,
        simdiki: onceki?.$1,
        simdikiBaslangic: onceki?.$2,
      );
    }
  }
  return null;
}

/// "05:15" ya da Aladhan biçimindeki "05:15 (+03)" metnini saat ve dakikaya
/// çevirir. Geçersiz bir metinse null döner.
({int saat, int dakika})? saatDakikaCoz(String metin) {
  final eslesme = RegExp(r'^\s*(\d{1,2}):(\d{2})').firstMatch(metin);
  if (eslesme == null) return null;
  final saat = int.parse(eslesme.group(1)!);
  final dakika = int.parse(eslesme.group(2)!);
  if (saat > 23 || dakika > 59) return null;
  return (saat: saat, dakika: dakika);
}

/// Bir günü "2026-09-19" biçiminde metne çevirir (önbellek anahtarı için).
String gunAnahtari(DateTime tarih) =>
    '${tarih.year.toString().padLeft(4, '0')}-'
    '${tarih.month.toString().padLeft(2, '0')}-'
    '${tarih.day.toString().padLeft(2, '0')}';

/// "2026-09-19" metnini `DateTime.utc(2026, 9, 19)` değerine çevirir.
/// Geçersiz bir metinse null döner.
DateTime? gunAnahtariniCoz(String metin) {
  final eslesme = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(metin);
  if (eslesme == null) return null;
  final yil = int.parse(eslesme.group(1)!);
  final ay = int.parse(eslesme.group(2)!);
  final gun = int.parse(eslesme.group(3)!);
  final tarih = DateTime.utc(yil, ay, gun);
  // 2026-02-31 gibi taşan tarihleri reddet.
  if (tarih.month != ay || tarih.day != gun) return null;
  return tarih;
}
