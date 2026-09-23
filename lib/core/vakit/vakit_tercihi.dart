import 'vakit_modelleri.dart';

/// Kullanıcının vakit hesabıyla ilgili seçimleri (Ayarlar).
///
/// Varsayılan tercih: Diyanet'in yayınladığı saatler, ikindi asr-ı evvel,
/// düzeltme yok. Varsayılan tercihle her şey bu güne kadarki davranışla aynıdır.
class VakitTercihi {
  const VakitTercihi({
    this.aladhanYontemi,
    this.hanefiIkindi = false,
    this.duzeltme = const {},
  });

  /// Ayarlar'daki hesaplama yöntemi adı → Aladhan yöntem numarası (Aladhan'ın
  /// kendi listesinden doğrulandı). "Diyanet Takvimi" ve listeden kaldırılmış
  /// eski değerler ("Mısır (BIS)", "Temkinli Takvim") burada yoktur: Diyanet.
  static const Map<String, int> aladhanYontemleri = {
    "Ummül Kurra": 4,
    "Kuzey Amerika (ISNA)": 2,
    "Müslim World Lig": 3,
    "Mısır": 5,
    "Karaçi İslami İlimler Üniversitesi": 1,
    "Tahran Üniversitesi": 7,
    "ITNA Ashari, Caferi": 0,
    "UOIF Fransa İslam Organizasyon Birliği": 12,
    "JAKIM (Malezya)": 17,
  };

  /// Ayarlar ekranındaki değerlerden tercih üretir.
  ///
  /// [temkin] ve [varsayilanTemkin]: vakit adı ("İmsak", "Güneş", ...) →
  /// dakika. Temkin, Diyanet'in varsayılanına göre FARK olarak uygulanır:
  /// değerler değiştirilmediyse vakitler Diyanet'le birebir kalır.
  factory VakitTercihi.ayarlardan({
    required String yontem,
    required String ikindiHesabi,
    required Map<String, int> temkin,
    required Map<String, int> varsayilanTemkin,
  }) {
    final duzeltme = <Vakit, int>{};
    for (final vakit in Vakit.values) {
      final varsayilan = varsayilanTemkin[vakit.ad] ?? 0;
      // Eksik anahtar varsayılan sayılır: düzeltme üretmez.
      final fark = (temkin[vakit.ad] ?? varsayilan) - varsayilan;
      if (fark != 0) duzeltme[vakit] = fark;
    }
    return VakitTercihi(
      aladhanYontemi: aladhanYontemleri[yontem],
      hanefiIkindi: ikindiHesabi == 'Hanefi',
      duzeltme: duzeltme,
    );
  }

  Map<String, dynamic> toJson() => {
        if (aladhanYontemi != null) 'yontem': aladhanYontemi,
        'hanefi': hanefiIkindi,
        'duzeltme': {
          for (final e in duzeltme.entries)
            if (e.value != 0) e.key.name: e.value,
        },
      };

  factory VakitTercihi.fromJson(Map<String, dynamic> json) {
    final duzeltme = json['duzeltme'] as Map? ?? const {};
    return VakitTercihi(
      aladhanYontemi: (json['yontem'] as num?)?.toInt(),
      hanefiIkindi: json['hanefi'] as bool? ?? false,
      duzeltme: {
        for (final vakit in Vakit.values)
          if ((duzeltme[vakit.name] as num?)?.toInt() case final dk?) vakit: dk,
      },
    );
  }

  /// null: "Diyanet Takvimi" (Diyanet'in yayınladığı saatler). Doluysa vakitler
  /// Aladhan'dan bu hesap yöntemiyle (Aladhan yöntem numarası) hesaplanır.
  final int? aladhanYontemi;

  /// İkindi asr-ı sani (Hanefi) ile mi? Diyanet asr-ı sani yayınlamaz: bu
  /// durumda yalnızca ikindi Aladhan'ın `school=1` hesabından alınır.
  final bool hanefiIkindi;

  /// Vakit başına dakika düzeltmesi (temkin: kullanıcının değeri ile Diyanet
  /// varsayılanı arasındaki fark). Ham veriye sonradan uygulanır, önbelleğe
  /// girmez.
  final Map<Vakit, int> duzeltme;

  /// Önbellekteki HAM verinin anahtar eki. Varsayılan tercih için boştur, yani
  /// eski önbellekler geçerli kalır. Düzeltme dahil değildir.
  String get hamAnahtar =>
      '${aladhanYontemi == null ? '' : '_m$aladhanYontemi'}'
      '${hanefiIkindi ? '_hanefi' : ''}';

  /// Aladhan'a hangi yöntemle gidileceği: seçilmemişse Diyanet parametreleri.
  int get aladhanParametresi => aladhanYontemi ?? 13;

  /// Tercihin tamamının özeti (düzeltme dahil); değişip değişmediğini anlamak için.
  String get ozet {
    final duz = [
      for (final e in duzeltme.entries)
        if (e.value != 0) '${e.key.name}:${e.value}',
    ]..sort();
    return '$hamAnahtar|${duz.join(',')}';
  }
}
