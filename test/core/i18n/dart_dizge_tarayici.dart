// Dart kaynağındaki dizge sabitlerini (string literal) ve bağlamlarını bulur.
// Çeviri taraması için: bir dizgenin ekrana yazılan bir konumda olup olmadığını
// (Text(...) içinde ya da tooltip:/hintText:/title: gibi adlandırılmış argüman)
// belirler. Yorumlar atlanır; ham, üç tırnaklı ve ${...} içi iç içe dizgeler işlenir.

class DizgeGrubu {
  DizgeGrubu(this.bas, this.bit, this.parcalar, this.kapsayanCagri,
      this.oncekiAnahtar);

  /// Kaynaktaki konum aralığı (komşu dizgeler birleşik: 'a' 'b').
  final int bas;
  final int bit;
  final List<String> parcalar;

  /// Dizgenin bulunduğu en içteki açık parantezin öncesindeki ad ("Text",
  /// "t", "translate"...); parantez yoksa ya da köşeli/süslü ise boş.
  final String kapsayanCagri;

  /// Dizgeden hemen önceki adlandırılmış argüman adı ("tooltip"...); yoksa boş.
  final String oncekiAnahtar;

  DizgeGrubu birlestir(int yeniBit, String parca) => DizgeGrubu(
      bas, yeniBit, [...parcalar, parca], kapsayanCagri, oncekiAnahtar);

  /// Kaçışlar çözülmüş düz değer; `${...}` ve `$ad` olduğu gibi kalır.
  String get deger {
    final b = StringBuffer();
    for (final p in parcalar) {
      final ham = p.startsWith('r');
      final govde = ham ? p.substring(1) : p;
      final q = govde[0];
      final uc = govde.startsWith(q * 3);
      var ic = uc
          ? govde.substring(3, govde.length - 3)
          : govde.substring(1, govde.length - 1);
      if (!ham) {
        ic = ic
            .replaceAll(r'\n', '\n')
            .replaceAll(r"\'", "'")
            .replaceAll(r'\"', '"')
            .replaceAll(r'\\', r'\')
            .replaceAll(r'\$', r'$');
      }
      b.write(ic);
    }
    return b.toString();
  }

  /// Değerdeki `${...}` ve `$ad` parçaları [yerine] ile değiştirilmiş hâli.
  String degerYerine(String yerine) => deger
      .replaceAll(RegExp(r'\$\{[^}]*\}'), yerine)
      .replaceAll(RegExp(r'\$[A-Za-z_][A-Za-z0-9_]*'), yerine);
}

bool _kimlikKarakteri(String c) => RegExp(r'[A-Za-z0-9_]').hasMatch(c);

int _dizgeSonu(String s, int i) {
  final ham = s[i] == 'r';
  var j = ham ? i + 1 : i;
  final q = s[j];
  final uc = s.startsWith(q * 3, j);
  j += uc ? 3 : 1;
  final n = s.length;
  while (j < n) {
    final c = s[j];
    if (!ham && c == r'\') {
      j += 2;
      continue;
    }
    if (uc && s.startsWith(q * 3, j)) return j + 3;
    if (!uc && c == q) return j + 1;
    if (!uc && c == '\n') return j;
    if (!ham && c == r'$' && j + 1 < n && s[j + 1] == '{') {
      j = _suslu(s, j + 1);
      continue;
    }
    j++;
  }
  return n;
}

int _suslu(String s, int i) {
  var derinlik = 0;
  var j = i;
  final n = s.length;
  while (j < n) {
    final c = s[j];
    if (c == "'" || c == '"') {
      j = _dizgeSonu(s, j);
      continue;
    }
    if (c == '{') {
      derinlik++;
    } else if (c == '}') {
      derinlik--;
      if (derinlik == 0) return j + 1;
    }
    j++;
  }
  return n;
}

/// `(` öncesindeki ad (boşluklar atlanır); yoksa boş.
String _oncekiKimlik(String s, int i) {
  var j = i - 1;
  while (
      j >= 0 && (s[j] == ' ' || s[j] == '\n' || s[j] == '\t' || s[j] == '\r')) {
    j--;
  }
  final son = j;
  while (j >= 0 && _kimlikKarakteri(s[j])) {
    j--;
  }
  return s.substring(j + 1, son + 1);
}

/// Dizgeden hemen önceki `ad:` (yalnız `(` ya da `,` sonrasındaki adlandırılmış
/// argüman; üçlü koşuldaki `x ? y : "z"` sayılmaz).
String _oncekiAnahtar(String s, int i) {
  var j = i - 1;
  bool bosluk(String c) => c == ' ' || c == '\n' || c == '\t' || c == '\r';
  while (j >= 0 && bosluk(s[j])) {
    j--;
  }
  if (j < 0 || s[j] != ':') return '';
  j--;
  while (j >= 0 && bosluk(s[j])) {
    j--;
  }
  final son = j;
  while (j >= 0 && _kimlikKarakteri(s[j])) {
    j--;
  }
  final ad = s.substring(j + 1, son + 1);
  var k = j;
  while (k >= 0 && bosluk(s[k])) {
    k--;
  }
  if (ad.isEmpty || k < 0 || (s[k] != '(' && s[k] != ',')) return '';
  return ad;
}

List<DizgeGrubu> dizgeGruplari(String s) {
  final gruplar = <DizgeGrubu>[];
  final yigin = <String>[];
  final n = s.length;
  var i = 0;
  while (i < n) {
    final c = s[i];
    if (s.startsWith('//', i)) {
      while (i < n && s[i] != '\n') {
        i++;
      }
    } else if (s.startsWith('/*', i)) {
      final k = s.indexOf('*/', i + 2);
      i = k < 0 ? n : k + 2;
    } else if (c == '"' ||
        c == "'" ||
        (c == 'r' &&
            i + 1 < n &&
            (s[i + 1] == '"' || s[i + 1] == "'") &&
            (i == 0 || !_kimlikKarakteri(s[i - 1])))) {
      final bit = _dizgeSonu(s, i);
      final parca = s.substring(i, bit);
      if (gruplar.isNotEmpty &&
          s.substring(gruplar.last.bit, i).trim().isEmpty) {
        gruplar[gruplar.length - 1] = gruplar.last.birlestir(bit, parca);
      } else {
        gruplar.add(DizgeGrubu(i, bit, [parca], yigin.isEmpty ? '' : yigin.last,
            _oncekiAnahtar(s, i)));
      }
      i = bit;
    } else if (c == '(') {
      yigin.add(_oncekiKimlik(s, i));
      i++;
    } else if (c == '[' || c == '{') {
      yigin.add('');
      i++;
    } else if (c == ')' || c == ']' || c == '}') {
      if (yigin.isNotEmpty) yigin.removeLast();
      i++;
    } else {
      i++;
    }
  }
  return gruplar;
}

/// Ekrana yazılan bir konumda mı (Text içinde ya da görünen adlandırılmış argüman).
const _gorunenAnahtarlar = {
  'tooltip',
  'hintText',
  'labelText',
  'helperText',
  'text',
  'title',
  'subtitle',
  'label',
  'semanticLabel',
  'baslik',
  'metin',
  'hint',
};

bool goruntuKonumuMu(DizgeGrubu g) =>
    g.kapsayanCagri == 'Text' || _gorunenAnahtarlar.contains(g.oncekiAnahtar);
