// lib/features/zikirmatik/zikir.dart

/// Bir zikir ve sayacı. Depolama biçimi eski `Map` biçimiyle AYNIDIR (anahtar
/// adları değişmedi), bu yüzden kullanıcıların kayıtlı zikirleri bozulmaz.
class Zikir {
  Zikir({
    required this.ad,
    required this.hedef,
    this.id,
    this.sayi = 0,
    this.tur = 0,
    this.imame,
    this.arapca = '',
    this.okunusu = '',
    this.anlami = '',
    this.varsayilan = false,
  });

  /// Yalnızca kullanıcının kendi eklediği zikirlerde dolu (uygulamanın hazır
  /// zikirleri ve varsayılan "Zikirmatik" id taşımaz).
  final String? id;

  String ad;

  /// Sayaç: 0 <= sayi < hedef (hedefe ulaşınca sıfırlanır, [tur] artar).
  int sayi;

  /// Hedef (bir turdaki adet), en az 1.
  int hedef;

  /// Tamamlanan tur sayısı.
  int tur;

  /// İmame boncuğu: her [imame] adette bir işaret (yoksa null).
  int? imame;

  String arapca;
  String okunusu;
  String anlami;

  /// Varsayılan "Zikirmatik" sayacı: silinemez ve düzenlenemez.
  final bool varsayilan;

  /// Kendi eklediğin zikir: hazır listesinden kalıcı silinebilir.
  bool get kendiEkledigim => id != null;

  bool get metniVar =>
      arapca.trim().isNotEmpty ||
      okunusu.trim().isNotEmpty ||
      anlami.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'ad': ad,
        'sayi': sayi,
        'hedef': hedef,
        'loop': tur,
        if (imame != null) 'imame': imame,
        'arapca': arapca,
        'okunusu': okunusu,
        'anlami': anlami,
        'isDefault': varsayilan,
      };

  /// Bozuk kayıt için null döner. Hedef en az 1; sayaç geçersizse 0.
  static Zikir? fromJson(Object? j) {
    if (j is! Map) return null;
    final ad = j['ad']?.toString().trim() ?? '';
    if (ad.isEmpty) return null;
    int? tamsayi(Object? v) => v is num ? v.toInt() : int.tryParse('$v');
    final hedef = tamsayi(j['hedef']);
    final sayi = tamsayi(j['sayi']) ?? 0;
    final gecerliHedef = hedef != null && hedef >= 1 ? hedef : 99;
    final imame = tamsayi(j['imame']);
    return Zikir(
      id: j['id']?.toString(),
      ad: ad,
      hedef: gecerliHedef,
      sayi: sayi >= 0 && sayi < gecerliHedef ? sayi : 0,
      tur: (tamsayi(j['loop']) ?? 0).clamp(0, 1 << 30),
      imame: imame != null && imame > 0 ? imame : null,
      arapca: j['arapca']?.toString() ?? '',
      okunusu: j['okunusu']?.toString() ?? '',
      anlami: j['anlami']?.toString() ?? '',
      varsayilan: j['isDefault'] == true,
    );
  }
}
