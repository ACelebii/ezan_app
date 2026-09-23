import '../../../core/vakit/vakit_modelleri.dart';
import '../../../core/vakit/vakit_tercihi.dart';

/// Bildirimleri planlamak için gereken her şeyin saklanabilir özeti.
///
/// Ön planda her planlamada kaydedilir; arka plan görevi (uygulama günlerce
/// açılmasa da bildirimleri yenileyen WorkManager işi) Firebase'e ve arayüze
/// ihtiyaç duymadan bu kayıttan aynı planlama yolunu çalıştırır. Ayarlar başka
/// bir cihazdan değiştirilirse kayıt, uygulama bir sonraki açılışında
/// yenilenene kadar eski kalır.
class BildirimGirdisi {
  const BildirimGirdisi({
    required this.konum,
    required this.tercih,
    required this.hatirlaticilar,
    required this.vakitEzanAyarlari,
    required this.vaktindeKilAyarlari,
    this.ramazan,
    this.ertelemeBitisi,
  });

  final Konum konum;
  final VakitTercihi tercih;
  final Map<String, dynamic> hatirlaticilar;
  final Map<String, dynamic> vakitEzanAyarlari;
  final Map<String, dynamic> vaktindeKilAyarlari;

  /// Yaklaşan/içinde bulunulan Ramazan aralığı (yalnızca Ramazan hatırlatıcısı
  /// açıksa dolu). Arka planda asset okumamak için kayıtla birlikte saklanır.
  final ({DateTime start, DateTime end})? ramazan;

  /// "Bildirimleri Ertele" bitiş anı (UTC).
  final DateTime? ertelemeBitisi;

  Map<String, dynamic> toJson() => {
        'konum': konum.toJson(),
        'tercih': tercih.toJson(),
        'hatirlaticilar': hatirlaticilar,
        'vakitEzan': vakitEzanAyarlari,
        'vaktindeKil': vaktindeKilAyarlari,
        if (ramazan != null)
          'ramazan': {
            'baslangic': gunAnahtari(_gun(ramazan!.start)),
            'bitis': gunAnahtari(_gun(ramazan!.end)),
          },
        if (ertelemeBitisi != null)
          'erteleme': ertelemeBitisi!.millisecondsSinceEpoch,
      };

  factory BildirimGirdisi.fromJson(Map<String, dynamic> json) {
    final ramazan = json['ramazan'] as Map<String, dynamic>?;
    final erteleme = (json['erteleme'] as num?)?.toInt();
    return BildirimGirdisi(
      konum: Konum.fromJson(json['konum'] as Map<String, dynamic>),
      tercih: VakitTercihi.fromJson(json['tercih'] as Map<String, dynamic>),
      hatirlaticilar: Map<String, dynamic>.from(json['hatirlaticilar'] as Map),
      vakitEzanAyarlari: Map<String, dynamic>.from(json['vakitEzan'] as Map),
      vaktindeKilAyarlari:
          Map<String, dynamic>.from(json['vaktindeKil'] as Map),
      ramazan: ramazan == null
          ? null
          : (
              start: gunAnahtariniCoz(ramazan['baslangic'] as String)!,
              end: gunAnahtariniCoz(ramazan['bitis'] as String)!,
            ),
      ertelemeBitisi: erteleme == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(erteleme, isUtc: true),
    );
  }

  static DateTime _gun(DateTime t) => DateTime.utc(t.year, t.month, t.day);
}
