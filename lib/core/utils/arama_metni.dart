// Metin arama yardımcısı (Diyanet yer listeleri, Kur'an sureleri, şehir arama).

// Türkçe harfler ve düzeltme işaretliler (Fâtiha, Nisâ, Âl-i İmrân).
// + İngilizce mealdeki işaretli harfler (Allāh, Muḥammad, Ṣalāh) ve eğri
// kesme işareti (Allāh’s): "allah" yazınca "Allāh" bulunur.
const _turkce = 'çğıöşüâîûÇĞİÖŞÜÂÎÛIāĀīĪūŪḥḤṣṢṭṬḍḌẓẒ’';
const _ascii = "cgiosuaiucgiosuaiuiaaiiuuhhssttddzz'";

/// Tek bir harfin (UTF-16 birimi) sadeleştirilmişi; harf atılırsa boş döner.
/// Dart'ın `toLowerCase`i "İ"yi bozar ("i̇"), bu yüzden önce harfler elle çevrilir.
String _katla(String harf) {
  if (harf == 'ʿ' || harf == 'ʾ') return ''; // ayn/hemze işareti: harf değil
  final i = _turkce.indexOf(harf);
  return (i < 0 ? harf : _ascii[i]).toLowerCase();
}

/// Arama için sadeleştirir: küçük harf, Türkçe harfler, â/î/û ve ā/ḥ/ṣ gibi işaretli harfler ASCII
/// ("İSTANBUL", "istanbul" ve "Istanbul" aynı; "Fâtiha" ile "fatiha" aynı olur).
String aramaMetni(String metin) => metin.trim().split('').map(_katla).join();

/// [metin] içinde, [terimler]den birinin geçtiği yerlerin özgün metindeki
/// `[başlangıç, bitiş)` aralıkları; çakışan ya da bitişik aralıklar birleştirilir.
///
/// [terimler] [aramaMetni] ile sadeleştirilmiş olmalı (aramanın kullandığı
/// biçimler). Eşleşme sadeleştirilmiş metinde yapılır, konum özgün metne geri
/// eşlenir: atılan harfler (ʿ ʾ) yüzünden iki metnin uzunluğu farklı olabilir,
/// bu yüzden konum kaydırılmaz, harf harf eşlenir.
List<(int, int)> aramaEslesmeleri(String metin, Iterable<String> terimler) {
  final katli = StringBuffer();
  final kaynak = <int>[]; // katli[k] hangi özgün konumdan geldi
  for (var i = 0; i < metin.length; i++) {
    final k = _katla(metin[i]);
    for (var j = 0; j < k.length; j++) {
      kaynak.add(i);
    }
    katli.write(k);
  }
  final duz = katli.toString();

  final aralar = <(int, int)>[];
  for (final t in terimler) {
    if (t.isEmpty) continue;
    for (var yer = duz.indexOf(t); yer >= 0; yer = duz.indexOf(t, yer + 1)) {
      aralar.add((kaynak[yer], kaynak[yer + t.length - 1] + 1));
    }
  }
  aralar.sort((a, b) => a.$1.compareTo(b.$1));

  final birlesik = <(int, int)>[];
  for (final a in aralar) {
    if (birlesik.isNotEmpty && a.$1 <= birlesik.last.$2) {
      final son = birlesik.removeLast();
      birlesik.add((son.$1, a.$2 > son.$2 ? a.$2 : son.$2));
    } else {
      birlesik.add(a);
    }
  }
  return birlesik;
}
