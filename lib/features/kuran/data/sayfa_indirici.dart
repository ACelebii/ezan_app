// lib/features/kuran/data/sayfa_indirici.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

import '../../../core/local_db.dart';

/// Mushaf'ın sayfa sayısı (Medine Mushafı).
const kuranSayfaSayisi = 604;

/// [sayfa]nın görsel adresi (1-604).
String kuranSayfaAdresi(int sayfa) =>
    'https://android.quran.com/data/width_1024/page${sayfa.toString().padLeft(3, '0')}.png';

/// Hangi sayfa görsellerinin cihazda olduğunu tutan kayıt (SQLite `kuran_pages`).
abstract class SayfaKayitlari {
  /// Cihazda kayıtlı sayfalar: sayfa no -> dosya yolu.
  Future<Map<int, String>> indirilenler();

  Future<void> kaydet(int sayfa, String yol);
}

class SqfliteSayfaKayitlari implements SayfaKayitlari {
  Future<Database> get _db => LocalDatabase.instance.database;

  @override
  Future<Map<int, String>> indirilenler() async {
    final satirlar = await (await _db).query(
      'kuran_pages',
      columns: ['page_number', 'local_path'],
      where: 'is_downloaded = 1',
    );
    return {
      for (final s in satirlar)
        if (s['local_path'] != null)
          s['page_number']! as int: s['local_path']! as String,
    };
  }

  @override
  Future<void> kaydet(int sayfa, String yol) async {
    await (await _db).update(
      'kuran_pages',
      {'local_path': yol, 'is_downloaded': 1},
      where: 'page_number = ?',
      whereArgs: [sayfa],
    );
  }
}

class SayfaIndirmeHatasi implements Exception {
  const SayfaIndirmeHatasi(this.sayfa, this.neden);

  final int sayfa;
  final String neden;

  @override
  String toString() => 'Sayfa $sayfa indirilemedi: $neden';
}

/// Arayüzün (sağlayıcının) ihtiyaç duyduğu kısım; testte sahtesi verilir.
abstract class SayfaDeposu {
  /// Cihazda sağlam olarak duran sayfa sayısı.
  Future<int> indirilenSayisi();

  /// Cihazda olmayan (ya da dosyası bozuk/silinmiş) sayfaları indirir. İlk
  /// hatada durur ve hatayı fırlatır; tekrar çağrılınca kalandan sürer.
  /// [iptalMi] true dönerse hata vermeden durur. [sayfalar] verilirse yalnız
  /// o sayfalardan eksik olanlar indirilir (ör. açık surenin/cüzün/sayfanın
  /// görselleri); verilmezse kitabın tamamı.
  Future<void> eksikleriIndir({
    Iterable<int>? sayfalar,
    void Function(int biten, int toplam)? ilerleme,
    bool Function()? iptalMi,
  });
}

/// Mushaf sayfa görsellerini cihaza indirir ve sağlamlığını korur.
class SayfaIndirici implements SayfaDeposu {
  SayfaIndirici({
    required this.istemci,
    required this.klasor,
    required this.kayitlar,
    this.paralel = 4,
    this.toplam = kuranSayfaSayisi,
  });

  final http.Client istemci;
  final Future<Directory> Function() klasor;
  final SayfaKayitlari kayitlar;

  /// Aynı anda kaç sayfa indirilir.
  final int paralel;

  /// İndirilecek sayfa sayısı (1..[toplam]); testte küçültülür.
  final int toplam;

  static const _zamanAsimi = Duration(seconds: 30);

  Future<File> _dosya(int sayfa) async =>
      File('${(await klasor()).path}/kuran_page_$sayfa.png');

  /// Dosya var ve boş değil.
  Future<bool> _saglam(String yol) async {
    final f = File(yol);
    return await f.exists() && await f.length() > 0;
  }

  /// PNG imzası (89 50 4E 47): yanıt görsel mi, yoksa 200 ile dönen bir hata/
  /// yönlendirme (captive portal) sayfası mı?
  static bool _pngMi(Uint8List b) =>
      b.length > 8 &&
      b[0] == 0x89 &&
      b[1] == 0x50 &&
      b[2] == 0x4E &&
      b[3] == 0x47;

  /// [sayfa]yı indirip kaydeder. Görsel doğrulanır, dosya önce geçici adla
  /// yazılıp yerine taşınır (yarım dosya kalmaz), en son kayıt işlenir.
  Future<void> indir(int sayfa, {String? adres}) async {
    final yanit = await istemci
        .get(Uri.parse(adres ?? kuranSayfaAdresi(sayfa)),
            headers: const {'User-Agent': 'Mozilla/5.0'})
        .timeout(_zamanAsimi);
    if (yanit.statusCode != 200) {
      throw SayfaIndirmeHatasi(sayfa, 'HTTP ${yanit.statusCode}');
    }
    if (!_pngMi(yanit.bodyBytes)) {
      throw SayfaIndirmeHatasi(sayfa, 'yanıt bir PNG görseli değil');
    }
    final dosya = await _dosya(sayfa);
    final gecici = File('${dosya.path}.tmp');
    await gecici.writeAsBytes(yanit.bodyBytes, flush: true);
    await gecici.rename(dosya.path);
    await kayitlar.kaydet(sayfa, dosya.path);
  }

  List<int> get _tumSayfalar => [for (var s = 1; s <= toplam; s++) s];

  /// [hedef] sayfalarından cihazda olmayan ya da bozuk olanlar.
  Future<List<int>> _eksikSayfalar(Iterable<int> hedef) async {
    final mevcut = await kayitlar.indirilenler();
    final sonuc = <int>[];
    for (final s in hedef) {
      if (mevcut[s] == null || !await _saglam(mevcut[s]!)) sonuc.add(s);
    }
    return sonuc;
  }

  @override
  Future<int> indirilenSayisi() async =>
      toplam - (await _eksikSayfalar(_tumSayfalar)).length;

  @override
  Future<void> eksikleriIndir({
    Iterable<int>? sayfalar,
    void Function(int biten, int toplam)? ilerleme,
    bool Function()? iptalMi,
  }) async {
    final tamKitap = sayfalar == null;
    final hedef = tamKitap ? _tumSayfalar : sayfalar.toSet().toList();
    final eksikHedef = await _eksikSayfalar(hedef);
    // "biten/toplam" hep KİTABIN TAMAMINA göre bildirilir ("N / 604" sayacıyla
    // tutarlı olsun diye); kısmi indirmede de doğrudur, çünkü hedefteki eksik
    // bir sayfa kitabın tamamında da eksikti.
    var biten = tamKitap ? toplam - eksikHedef.length : await indirilenSayisi();
    ilerleme?.call(biten, toplam);

    var sonraki = 0;
    Object? hata;
    StackTrace? iz;
    Future<void> isci() async {
      while (hata == null &&
          !(iptalMi?.call() ?? false) &&
          sonraki < eksikHedef.length) {
        final sayfa = eksikHedef[sonraki++];
        try {
          await indir(sayfa);
          biten++;
          ilerleme?.call(biten, toplam);
        } catch (e, st) {
          hata ??= e;
          iz ??= st;
        }
      }
    }

    await Future.wait([for (var i = 0; i < paralel; i++) isci()]);
    if (hata != null) Error.throwWithStackTrace(hata!, iz!);
  }

  /// Periyodik senkron için: yalnızca kayıtlı ama dosyası silinmiş/bozuk
  /// sayfaları yeniden indirir. Sağlam sayfalara dokunmaz (görseller
  /// değişmez; eskiden her senkronda hepsi baştan iniyordu, 604 sayfada
  /// yaklaşık 57 MB). Ağ yoksa ya da indirme başarısızsa sessizce geçer.
  Future<void> yenile() async {
    final mevcut = await kayitlar.indirilenler();
    for (final e in mevcut.entries) {
      if (await _saglam(e.value)) continue;
      try {
        await indir(e.key);
      } catch (_) {
        // Bu sayfa bir sonraki senkronda yeniden denenir.
      }
    }
  }
}
