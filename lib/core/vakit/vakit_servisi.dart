// Uygulamanın vakit alma noktası: önce Diyanet, olmazsa Aladhan, sonuç önbellekte.
//
// Saat dilimi verisini kendisi hazırlar (`zamanDilimleriniHazirla`); başlangıç
// sırasına bağlı değildir.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'aladhan_kaynagi.dart';
import 'diyanet_kaynagi.dart';
import 'vakit_modelleri.dart';
import 'vakit_tercihi.dart';
import 'zaman_dilimi.dart';

/// Ne ağdan ne önbellekten vakit bulunamadığında fırlatılır.
class VakitHatasi implements Exception {
  VakitHatasi(this.mesaj);

  final String mesaj;

  @override
  String toString() => 'VakitHatasi: $mesaj';
}

class VakitServisi {
  VakitServisi({
    DiyanetKaynagi? diyanet,
    AladhanKaynagi? aladhan,
    DateTime Function()? simdi,
  })  : _diyanet = diyanet ?? DiyanetKaynagi(),
        _aladhan = aladhan ?? AladhanKaynagi(),
        _simdi = simdi ?? DateTime.now;

  final DiyanetKaynagi _diyanet;
  final AladhanKaynagi _aladhan;
  final DateTime Function() _simdi;

  /// Bildirimlerin ve geri sayımın rahat çalışması için bugünden itibaren
  /// elde bulunması gereken gün sayısı.
  static const enAzGun = 14;

  final _devamEdenler = <String, Future<List<GunlukVakit>>>{};

  /// [konum] için dünden itibaren vakitleri verir (dünün yatsısı, gece
  /// yarısından sonraki "içinde bulunulan vakit" için gerekir).
  ///
  /// [tercih]: Diyanet Takvimi (varsayılan) ya da seçilen Aladhan yöntemi,
  /// Hanefi ikindi ve temkin düzeltmesi. Önbellekte bugünden itibaren
  /// [enAzGun] gün varsa ağa gitmez. Ağdan yeterli veri alınamazsa eldeki
  /// bayat veriyi döner; hiçbiri yoksa [VakitHatasi] fırlatır.
  Future<List<GunlukVakit>> vakitleriGetir(Konum konum,
      [VakitTercihi tercih = const VakitTercihi()]) async {
    return _duzelt(await _hamGetir(konum, tercih), tercih);
  }

  Future<List<GunlukVakit>> _hamGetir(Konum konum, VakitTercihi tercih) {
    // Ana ekran ve bildirim kurucusu aynı anda isterse tek istek atılır.
    final anahtar = '${konum.anahtar}${tercih.hamAnahtar}';
    return _devamEdenler[anahtar] ??= _getir(konum, tercih).whenComplete(() {
      // Süslü parantez şart: `remove` Future'ın kendisini döndürür ve
      // `whenComplete` döndürülen Future'ı bekler, yani kendini beklerdi.
      _devamEdenler.remove(anahtar);
    });
  }

  List<GunlukVakit> _duzelt(List<GunlukVakit> gunler, VakitTercihi tercih) =>
      [for (final gun in gunler) gun.duzelt(tercih.duzeltme)];

  Future<List<GunlukVakit>> _getir(Konum konum, VakitTercihi tercih) async {
    final bugun = this.bugun(konum);
    final onbellek = await _oku(konum, tercih, bugun);
    if (onbellek != null && _taze(onbellek, tercih, bugun)) {
      return onbellek.gunler;
    }

    var gunler = <GunlukVakit>[];
    var ikindiTamam = true; // Hanefi ikindisi uygulanabildi mi?
    if (tercih.aladhanYontemi == null) {
      try {
        gunler = _dundenItibaren(await _diyanet.vakitleriGetir(konum), bugun);
      } on DiyanetHatasi {
        // Yedeğe geç.
      }
      if (tercih.hanefiIkindi && _yeterli(gunler, bugun)) {
        final hanefi = await _hanefiIkindiUygula(konum, gunler, bugun);
        if (hanefi == null) {
          ikindiTamam = false;
        } else {
          gunler = hanefi;
        }
      }
    }
    if (!_yeterli(gunler, bugun)) {
      try {
        final yedek = _dundenItibaren(
            await _aladhan.vakitleriGetir(konum, bugun,
                yontem: tercih.aladhanParametresi, hanefi: tercih.hanefiIkindi),
            bugun);
        if (yedek.length > gunler.length) {
          gunler = yedek;
          ikindiTamam = true; // Aladhan ikindiyi zaten tercihe göre hesaplar.
        }
      } on AladhanHatasi {
        // Elde ne varsa onunla devam.
      }
    }

    if (_yeterli(gunler, bugun)) {
      // Hanefi ikindisi eksik kaldıysa önbelleğe alma: bir sonraki çağrıda
      // yeniden denensin.
      if (ikindiTamam) await _yaz(konum, tercih, gunler, bugun);
      return gunler;
    }
    // Ağdan yeterli veri gelmedi: elimizdekilerin uzun olanı.
    final eski = onbellek?.gunler ?? const <GunlukVakit>[];
    final secilen = gunler.length > eski.length ? gunler : eski;
    if (secilen.isEmpty) {
      throw VakitHatasi('${konum.ad} için vakit alınamadı: '
          'Diyanet ve Aladhan\'a ulaşılamadı, önbellek boş.');
    }
    if (identical(secilen, gunler)) await _yaz(konum, tercih, gunler, bugun);
    return secilen;
  }

  /// Diyanet günlerinde yalnızca ikindiyi Aladhan'ın asr-ı sani (Hanefi)
  /// hesabıyla değiştirir. Bugünden sonraki [enAzGun] günün hepsi için Aladhan
  /// verisi yoksa null döner: yarım Hanefi/yarım Şafi karışık bir liste olmasın.
  Future<List<GunlukVakit>?> _hanefiIkindiUygula(
      Konum konum, List<GunlukVakit> gunler, DateTime bugun) async {
    final Map<DateTime, GunlukVakit> hanefi;
    try {
      hanefi = {
        for (final gun
            in await _aladhan.vakitleriGetir(konum, bugun, hanefi: true))
          gun.tarih: gun,
      };
    } on AladhanHatasi {
      return null;
    }
    for (var i = 0; i < enAzGun; i++) {
      if (!hanefi.containsKey(bugun.add(Duration(days: i)))) return null;
    }
    return [
      for (final gun in gunler)
        hanefi[gun.tarih] == null
            ? gun
            : gun.vakitiAl(Vakit.ikindi, hanefi[gun.tarih]!),
    ];
  }

  /// [yil]/[ay] ayının günleri (imsakiye, ajanda). Diyanet'in elindeki günler
  /// (yaklaşık dünden 30 gün sonrasına) olduğu gibi kullanılır; ayın geri kalanı
  /// Aladhan'dan (Diyanet parametreleriyle hesaplanmış, Diyanet'ten 1-2 dk
  /// sapabilir) tamamlanır. Hangi günün nereden geldiği [GunlukVakit.kaynak]ta
  /// yazar. Hiç gün bulunamazsa [VakitHatasi] fırlatır.
  Future<List<GunlukVakit>> ayVakitleri(Konum konum, int yil, int ay,
      [VakitTercihi tercih = const VakitTercihi()]) async {
    var diyanet = <GunlukVakit>[];
    try {
      diyanet = await _hamGetir(konum, tercih);
    } on VakitHatasi {
      // Diyanet ve önbellek yok; ay Aladhan'dan denenecek.
    }
    final elde = {
      for (final gun in diyanet)
        if (gun.tarih.year == yil && gun.tarih.month == ay) gun.tarih: gun,
    };
    final gunSayisi = DateTime.utc(yil, ay + 1, 0).day;

    var hesaplanan = <DateTime, GunlukVakit>{};
    if (elde.length < gunSayisi) {
      try {
        hesaplanan = {
          for (final gun in await _aladhanAyi(konum, yil, ay, tercih))
            gun.tarih: gun,
        };
      } on AladhanHatasi {
        // Elde ne varsa onu göster.
      }
    }

    final gunler = [
      for (var gun = 1; gun <= gunSayisi; gun++)
        if ((elde[DateTime.utc(yil, ay, gun)] ??
                hesaplanan[DateTime.utc(yil, ay, gun)])
            case final bulunan?)
          bulunan,
    ];
    if (gunler.isEmpty) {
      throw VakitHatasi('${konum.ad} için $yil-$ay vakitleri alınamadı.');
    }
    return _duzelt(gunler, tercih);
  }

  // ponytail: Aladhan ayları hesaplanmış, değişmeyen veridir; bu yüzden süresiz
  // saklanır (~9 KB/ay). Gezilen her ay bir anahtar bırakır; Faz 3'te konum
  // silinirken `vakit_ay_<anahtar>_*` da silinmeli.
  Future<List<GunlukVakit>> _aladhanAyi(
      Konum konum, int yil, int ay, VakitTercihi tercih) async {
    final prefs = await SharedPreferences.getInstance();
    final anahtar = 'vakit_ay_${konum.anahtar}${tercih.hamAnahtar}_$yil-$ay';
    final kayitli = prefs.getString(anahtar);
    if (kayitli != null) {
      try {
        return [
          for (final gun in jsonDecode(kayitli) as List)
            GunlukVakit.fromJson(gun as Map<String, dynamic>),
        ];
      } catch (_) {
        // Bozuk kayıt: yeniden alınır ve üzerine yazılır.
      }
    }
    final gunler = await _aladhan.ayiGetir(konum, yil, ay,
        yontem: tercih.aladhanParametresi, hanefi: tercih.hanefiIkindi);
    await prefs.setString(
        anahtar, jsonEncode([for (final gun in gunler) gun.toJson()]));
    return gunler;
  }

  /// Konumun kendi saat dilimine göre bugün (telefonun saat diliminden bağımsız).
  DateTime bugun(Konum konum) {
    zamanDilimleriniHazirla();
    final yerel =
        tz.TZDateTime.from(_simdi(), tz.getLocation(konum.saatDilimi));
    return DateTime.utc(yerel.year, yerel.month, yerel.day);
  }

  List<GunlukVakit> _dundenItibaren(List<GunlukVakit> gunler, DateTime bugun) {
    final dun = bugun.subtract(const Duration(days: 1));
    return [
      for (final gun in gunler)
        if (!gun.tarih.isBefore(dun)) gun,
    ];
  }

  /// Bugün ve sonraki 13 günün hepsi var mı? (Aralarda boşluk olmamalı.)
  bool _yeterli(List<GunlukVakit> gunler, DateTime bugun) {
    final mevcut = {for (final gun in gunler) gunAnahtari(gun.tarih)};
    return List.generate(
            enAzGun, (i) => gunAnahtari(bugun.add(Duration(days: i))))
        .every(mevcut.contains);
  }

  /// Önbellek yeterli ve Diyanet kaynaklıysa taze sayılır. Diyanet Takvimi
  /// seçiliyken Aladhan (yedek) kaynaklı önbellek yalnızca alındığı gün taze
  /// sayılır; ertesi gün Diyanet yeniden denenir, böylece yedekte takılı
  /// kalınmaz. Kullanıcı bir Aladhan yöntemi seçtiyse Aladhan zaten asıl
  /// kaynaktır: yeterli önbellek taze sayılır.
  bool _taze(_Onbellek onbellek, VakitTercihi tercih, DateTime bugun) {
    if (!_yeterli(onbellek.gunler, bugun)) return false;
    return tercih.aladhanYontemi != null ||
        onbellek.gunler.first.kaynak == VakitKaynagi.diyanet ||
        onbellek.alindi == bugun;
  }

  // ponytail: eski konumların önbelleği silinmez (~15 KB/konum). Faz 3'te
  // konum silinirken `vakit_onbellek_<anahtar>*` da silinmeli.
  static String _anahtar(Konum konum, VakitTercihi tercih) =>
      'vakit_onbellek_${konum.anahtar}${tercih.hamAnahtar}';

  Future<_Onbellek?> _oku(
      Konum konum, VakitTercihi tercih, DateTime bugun) async {
    final prefs = await SharedPreferences.getInstance();
    final metin = prefs.getString(_anahtar(konum, tercih));
    if (metin == null) return null;
    try {
      final veri = jsonDecode(metin) as Map<String, dynamic>;
      final gunler = _dundenItibaren([
        for (final gun in veri['gunler'] as List)
          GunlukVakit.fromJson(gun as Map<String, dynamic>),
      ], bugun);
      final alindi = gunAnahtariniCoz(veri['alindi'] as String)!;
      return gunler.isEmpty ? null : _Onbellek(alindi, gunler);
    } catch (_) {
      // Bozuk önbellek uygulamayı düşürmemeli; yok sayılır ve üzerine yazılır.
      return null;
    }
  }

  Future<void> _yaz(Konum konum, VakitTercihi tercih, List<GunlukVakit> gunler,
      DateTime bugun) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _anahtar(konum, tercih),
        jsonEncode({
          'alindi': gunAnahtari(bugun),
          'gunler': [for (final gun in gunler) gun.toJson()],
        }));
  }
}

class _Onbellek {
  const _Onbellek(this.alindi, this.gunler);

  /// Verinin ağdan alındığı gün (konumun takvimine göre).
  final DateTime alindi;
  final List<GunlukVakit> gunler;
}
