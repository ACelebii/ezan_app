// lib/features/kuran/data/kuran_arama_indeksi.dart

import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../../core/utils/arama_metni.dart';
import '../kuran_models.dart';

/// Meal aramasında bir sonuç.
class AramaSonucu {
  const AramaSonucu({
    required this.verseKey,
    required this.sureId,
    required this.ayetNo,
    required this.meal,
    required this.kaynak,
    this.terimler = const [],
  });

  final String verseKey;
  final int sureId;
  final int ayetNo;

  /// Aranan dildeki meal metni.
  final String meal;

  /// Mealin kaynak etiketi ("Diyanet", "Elmalılı", "Saheeh International").
  final String kaynak;

  /// Aramada kullanılan sadeleştirilmiş sözcük biçimleri (yazılan sözcük ve
  /// türetilmiş gövdeleri); mealde vurgulanacak yerleri bulmak içindir.
  /// Ayet anahtarı ("2:255") aramasında boştur.
  final List<String> terimler;
}

/// [KuranAramaIndeksi.ara] sonucu: gösterilecek ilk sonuçlar ve toplam sayı.
class AramaSayfasi {
  const AramaSayfasi(this.sonuclar, this.toplam, {this.yaklasik = false});

  static const bos = AramaSayfasi([], 0);

  /// En alakalıdan başlayarak (eşit alakada Mushaf sırasıyla) ilk sonuçlar.
  final List<AramaSonucu> sonuclar;
  final int toplam;

  /// Tam eşleşme çıkmadı; sözcüklerin sonu kırpılarak benzerleri bulundu.
  final bool yaklasik;
}

class _Kayit {
  _Kayit(this.ayet)
      : tr = aramaMetni(ayet.translation),
        en = aramaMetni(ayet.translationEn);

  final AyahModel ayet;

  /// Arama için sadeleştirilmiş Türkçe ve İngilizce meal.
  final String tr;
  final String en;
}

/// Bir sözcüğün aranan biçimi. [varyant]: sözcüğün kendisi değil, ondan
/// türetilmiş gövde (ünlü düşmesi ya da kırpılmış son); daha az puan alır.
class _Form {
  const _Form(this.metin, {this.varyant = false});

  final String metin;
  final bool varyant;
}

/// Türkçe ünlü düşmesi: sözcük eksiz haliyle "sabır", ek alınca "sabrı"
/// olur (akıl→aklı, şehir→şehri, ömür→ömrü). Sadeleştirilmiş sözcük
/// ünsüz+ı/i/u/ü+ünsüz ile bitiyorsa ünlüsüz gövdeyi ("sabr") verir.
@visibleForTesting
List<String> unluDusmesi(String kelime) {
  if (kelime.length < 4) return const [];
  final m = RegExp(r'^(.*[bcdfghjklmnprstvyz])[iu]([bcdfghjklmnprstvyz])$')
      .firstMatch(kelime);
  return m == null ? const [] : ['${m[1]}${m[2]}'];
}

/// Ünlü düşmesinin tersi: gövde iki ünsüzle bitiyorsa ("sabr") arada düşmüş
/// olabilecek ünlüyü geri koyar ("sabir", "sabur").
@visibleForTesting
List<String> unluEkleme(String kok) {
  if (kok.length < 4) return const [];
  const unsuz = 'bcdfghjklmnprstvyz';
  final son = kok[kok.length - 1], onceki = kok[kok.length - 2];
  if (!unsuz.contains(son) || !unsuz.contains(onceki)) return const [];
  final bas = kok.substring(0, kok.length - 1);
  return ['${bas}i$son', '${bas}u$son'];
}

/// Cihazdaki ayetlerin (okunmuş/indirilmiş sureler) bellekteki meal arama
/// dizini. Yalnızca dizine eklenmiş sureler aranır.
class KuranAramaIndeksi {
  /// Ekranda gösterilecek en çok sonuç (toplam sayı ayrıca verilir).
  static const enFazlaSonuc = 100;

  /// Yedek aramada bir sözcükten en çok kaç harf kırpılır / en az kaç harf kalır.
  static const _enFazlaKirpma = 3;
  static const _enAzGovde = 4;

  final _sureler = <int, List<_Kayit>>{};

  int get sureSayisi => _sureler.length;

  bool sureVar(int sureId) => _sureler.containsKey(sureId);

  /// [sureId] suresinin ayetlerini ekler (varsa yenisiyle değiştirir).
  void sureEkle(int sureId, List<AyahModel> ayetler) {
    _sureler[sureId] = [for (final a in ayetler) _Kayit(a)];
  }

  static final _ayetAnahtari = RegExp(r'^\d{1,3}:\d{1,3}$');
  static final _belirtecAyirici = RegExp(r"[^a-z0-9']+");

  /// [sorgu]: "2:255" gibi bir ayet anahtarı tam eşleşir. Aksi hâlde yazılan
  /// TÜM sözcükler mealde geçmelidir (sıra ve harf aksanı önemsiz). Türkçede
  /// ünlü düşmesi de bulunur ("sabır" -> "sabrı", "sabret"). Sonuçlar alakaya
  /// göre sıralanır: tam sözcük > sözcük başı > sözcük içi; yazılan sözcükler
  /// ardışık geçiyorsa bonus; eşitlikte Mushaf sırası. Hiç sonuç yoksa sözcüklerin
  /// sonu kırpılarak benzerleri aranır ([AramaSayfasi.yaklasik]).
  AramaSayfasi ara(String sorgu, {required bool ingilizce}) {
    final aranan = aramaMetni(sorgu).trim();
    if (aranan.isEmpty) return AramaSayfasi.bos;

    if (_ayetAnahtari.hasMatch(aranan)) return _anahtarAra(aranan, ingilizce);

    final sozcukler = aranan.split(RegExp(r'\s+'));
    final siki = _tara(aranan, sozcukler, ingilizce, gevsek: false);
    if (siki.toplam > 0 || !sozcukler.any((s) => s.length > _enAzGovde)) {
      return siki;
    }
    final gevsek = _tara(aranan, sozcukler, ingilizce, gevsek: true);
    return AramaSayfasi(gevsek.sonuclar, gevsek.toplam,
        yaklasik: gevsek.toplam > 0);
  }

  AramaSonucu _sonuc(_Kayit k, int sureId, bool ingilizce,
      [List<String> terimler = const []]) {
    final en = ingilizce && k.ayet.translationEn.isNotEmpty;
    return AramaSonucu(
      verseKey: k.ayet.verseKey,
      sureId: sureId,
      ayetNo: int.tryParse(k.ayet.verseKey.split(':').last) ?? 0,
      meal: en ? k.ayet.translationEn : k.ayet.translation,
      kaynak: en ? 'Saheeh International' : k.ayet.mealKaynagi,
      terimler: terimler,
    );
  }

  AramaSayfasi _anahtarAra(String anahtar, bool ingilizce) {
    for (final sureId in _sureler.keys) {
      for (final k in _sureler[sureId]!) {
        if (k.ayet.verseKey == anahtar) {
          return AramaSayfasi([_sonuc(k, sureId, ingilizce)], 1);
        }
      }
    }
    return AramaSayfasi.bos;
  }

  /// Bir sözcüğün aranacak biçimleri.
  List<_Form> _formlar(String kelime, bool ingilizce, {required bool gevsek}) {
    final formlar = <_Form>[_Form(kelime)];
    if (!ingilizce) {
      formlar.addAll(
          [for (final v in unluDusmesi(kelime)) _Form(v, varyant: true)]);
    }
    if (gevsek && kelime.length > _enAzGovde) {
      for (var k = 1; k <= _enFazlaKirpma; k++) {
        final govde = kelime.substring(0, kelime.length - k);
        if (govde.length < _enAzGovde) break;
        formlar.add(_Form(govde, varyant: true));
        if (!ingilizce) {
          formlar.addAll(
              [for (final v in unluEkleme(govde)) _Form(v, varyant: true)]);
        }
      }
    }
    return formlar;
  }

  AramaSayfasi _tara(String tamIfade, List<String> sozcukler, bool ingilizce,
      {required bool gevsek}) {
    final formlar = [
      for (final s in sozcukler) _formlar(s, ingilizce, gevsek: gevsek)
    ];
    final terimler = {
      for (final f in formlar)
        for (final x in f) x.metin
    }.toList();
    final adaylar = <({double puan, int sira, int sureId, _Kayit kayit})>[];
    var sira = 0;
    for (final sureId in _sureler.keys.toList()..sort()) {
      for (final k in _sureler[sureId]!) {
        sira++;
        final metin = ingilizce && k.en.isNotEmpty ? k.en : k.tr;
        if (!formlar.every((f) => f.any((x) => metin.contains(x.metin)))) {
          continue;
        }
        adaylar.add((
          puan: _puan(metin, formlar, tamIfade, sozcukler.length),
          sira: sira,
          sureId: sureId,
          kayit: k,
        ));
      }
    }
    adaylar.sort((a, b) {
      final c = b.puan.compareTo(a.puan);
      return c != 0 ? c : a.sira.compareTo(b.sira);
    });
    return AramaSayfasi([
      for (final a in adaylar.take(enFazlaSonuc))
        _sonuc(a.kayit, a.sureId, ingilizce, terimler),
    ], adaylar.length);
  }

  /// Bir ayetin alakası: her aranan sözcük için en iyi eşleşme (tam sözcük 4,
  /// sözcük başı 3, sözcük içi 1,5; türetilmiş biçimlerde biraz az), toplamı;
  /// birden çok sözcük ardışık geçiyorsa +2.
  double _puan(String metin, List<List<_Form>> kelimeFormlari, String tamIfade,
      int sozcukSayisi) {
    final belirtecler = metin.split(_belirtecAyirici);
    var toplam = 0.0;
    for (final formlar in kelimeFormlari) {
      var enIyi = 1.0; // metinde geçiyor (ayırıcıya rastlamış olsa bile)
      for (final f in formlar) {
        for (final t in belirtecler) {
          final double p;
          if (t == f.metin) {
            p = f.varyant ? 3 : 4;
          } else if (t.startsWith(f.metin)) {
            p = f.varyant ? 2.5 : 3;
          } else if (t.contains(f.metin)) {
            p = f.varyant ? 1 : 1.5;
          } else {
            continue;
          }
          if (p > enIyi) enIyi = p;
        }
      }
      toplam += enIyi;
    }
    if (sozcukSayisi > 1 && metin.contains(tamIfade)) toplam += 2;
    return toplam;
  }
}
