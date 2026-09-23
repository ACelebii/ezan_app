// "Gökyüzü" ana ekranının hesabı: verilen ana göre gökyüzünün renkleri ve
// güneşin (geceleri ayın) yay üzerindeki yeri. Çizimden bağımsızdır, o yüzden
// ekran olmadan test edilir.
//
// Her vaktin bir gökyüzü rengi vardır (aşağıdaki tablo). İki vakit arasında renk,
// geçen zamana göre karışır; böylece gökyüzü vakitte "zıplamaz", gün boyunca
// akar. Yay: gündüz Güneş (gün doğumu) → Akşam (gün batımı), gece Akşam →
// ertesi günün Güneş vakti.

import 'dart:ui' show Color;

import '../../core/vakit/vakit_modelleri.dart';

/// Bir vaktin başladığı andaki gökyüzü: (üst renk, ufuk rengi).
const gokyuzuRenkleri = <Vakit, (Color, Color)>{
  Vakit.imsak: (Color(0xFF0B1026), Color(0xFF2B3A67)), // şafak öncesi
  Vakit.gunes: (Color(0xFF2E4A8A), Color(0xFFF2A65A)), // gün doğumu
  Vakit.ogle: (Color(0xFF3A86D9), Color(0xFF9CCBF2)), // öğle
  Vakit.ikindi: (Color(0xFF3F79C4), Color(0xFFF4D58D)), // ikindi: altın ışık
  Vakit.aksam: (Color(0xFF3A2F6B), Color(0xFFE8735A)), // gün batımı
  Vakit.yatsi: (Color(0xFF070B1E), Color(0xFF1B2450)), // gece
};

class GokyuzuDurumu {
  const GokyuzuDurumu({
    required this.ust,
    required this.ufuk,
    required this.gunduz,
    this.ilerleme,
  });

  /// Gökyüzünün üst ve ufuk (alt) rengi.
  final Color ust;
  final Color ufuk;

  /// true: yayda güneş var (Güneş → Akşam); false: ay var (Akşam → Güneş).
  final bool gunduz;

  /// Yayın neresinde: 0 = doğuş, 0.5 = tepe, 1 = batış. Bilinmiyorsa (yeterli
  /// vakit verisi yoksa) null.
  final double? ilerleme;
}

/// [gunler] dünden itibaren birkaç günlük vakit olmalı: gece yarısından sonra
/// dünün akşamı, akşamdan sonra yarının gün doğumu gerekir.
///
/// Verinin dışında kalan an için (ilk günden önce, son günden sonra) komşu gün,
/// ilk/son günün vakitleri bir gün kaydırılarak yaklaşıklanır (vakitler günde
/// en çok 1-2 dakika kayar). Böylece yay, veri eksik diye kaybolmaz. Hiç vakit
/// yoksa yay bilinmez ([GokyuzuDurumu.ilerleme] null).
GokyuzuDurumu gokyuzuDurumu(Iterable<GunlukVakit> gunler, DateTime simdi) {
  final liste = gunler.toList();
  const gun = Duration(days: 1);
  final anlar = <(Vakit, DateTime)>[
    for (final g in liste)
      for (final vakit in Vakit.values) (vakit, g.anlar[vakit]!),
    if (liste.isNotEmpty)
      for (final vakit in Vakit.values) ...[
        (vakit, liste.first.anlar[vakit]!.subtract(gun)),
        (vakit, liste.last.anlar[vakit]!.add(gun)),
      ],
  ]..sort((a, b) => a.$2.compareTo(b.$2));

  // Renk: içinde bulunulan iki vakit arasında karışım.
  (Vakit, DateTime)? onceki, sonraki;
  for (final a in anlar) {
    if (a.$2.isAfter(simdi)) {
      sonraki = a;
      break;
    }
    onceki = a;
  }
  final renk = _renkKaristir(onceki, sonraki, simdi);

  // Yay: son ve sıradaki gün doğumu/batımı olayları.
  (Vakit, DateTime)? oncekiOlay, sonrakiOlay;
  for (final a in anlar) {
    if (a.$1 != Vakit.gunes && a.$1 != Vakit.aksam) continue;
    if (a.$2.isAfter(simdi)) {
      sonrakiOlay = a;
      break;
    }
    oncekiOlay = a;
  }
  final yayVar = oncekiOlay != null &&
      sonrakiOlay != null &&
      oncekiOlay.$1 != sonrakiOlay.$1;

  return GokyuzuDurumu(
    ust: renk.$1,
    ufuk: renk.$2,
    gunduz: yayVar ? oncekiOlay.$1 == Vakit.gunes : _gunduzMu(onceki, sonraki),
    ilerleme: yayVar ? _oran(oncekiOlay.$2, sonrakiOlay.$2, simdi) : null,
  );
}

double _oran(DateTime bas, DateTime son, DateTime simdi) {
  final toplam = son.difference(bas).inMilliseconds;
  if (toplam <= 0) return 0;
  return (simdi.difference(bas).inMilliseconds / toplam).clamp(0.0, 1.0);
}

/// Yay bilinmiyorsa, en azından renklerden gündüz/gece tahmini: Güneş ile
/// Akşam vakitleri arasındaysak gündüz.
bool _gunduzMu((Vakit, DateTime)? onceki, (Vakit, DateTime)? sonraki) {
  final v = onceki?.$1 ?? sonraki?.$1;
  return v == Vakit.gunes || v == Vakit.ogle || v == Vakit.ikindi;
}

(Color, Color) _renkKaristir(
    (Vakit, DateTime)? onceki, (Vakit, DateTime)? sonraki, DateTime simdi) {
  if (onceki == null && sonraki == null) return gokyuzuRenkleri[Vakit.yatsi]!;
  if (onceki == null) return gokyuzuRenkleri[sonraki!.$1]!;
  if (sonraki == null) return gokyuzuRenkleri[onceki.$1]!;
  final t = _oran(onceki.$2, sonraki.$2, simdi);
  final a = gokyuzuRenkleri[onceki.$1]!;
  final b = gokyuzuRenkleri[sonraki.$1]!;
  return (Color.lerp(a.$1, b.$1, t)!, Color.lerp(a.$2, b.$2, t)!);
}
