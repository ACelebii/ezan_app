// Ekranlardaki (lib/ altındaki) çevrilmemiş Türkçe metinleri bulur.
//
// Kural: ekrana yazılan her dizge sabiti (Text(...) içinde ya da tooltip:/
// hintText:/title:... argümanı) çeviri çağrısına (context.t, translate)
// SARILI olmalı ve `Ceviri`de İngilizce karşılığı olmalıdır; aksi hâlde
// İngilizce arayüzde Türkçe görünür. (Bir widget içeriden çevirse bile çağrı
// yerinde de sarmak zararsızdır: çeviri tekrarlanınca değişmez.)
//
// Tüm lib/ için SIFIR tolerans: yeni bir çevrilmemiş metin eklenirse test kırılır.
// Bilerek çevrilmeyecek (dilden bağımsız) metinler [muaf]a eklenir.

import 'dart:io';

import 'package:ezan_vakti_uygulamasi/core/i18n/ceviri.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dart_dizge_tarayici.dart';

/// Çevirisi olmasa da hatalı sayılmayan, dilden bağımsız metinler (özel adlar).
const muaf = {
  'Diyanet',
  'Elmalılı',
  'Saheeh International',
  'Abdul Basit',
  'Mishary Alafasy',
  'Husary',
  'Google',
  'Apple',
  'Manrope',
  'Mozilla/5.0',
  'Pro', // marka
  'YouTube', // marka
  r'${authService.kuranYaziBoyutu.toInt()} px', // birim
  // Yalnız hata ayıklama derlemesinde görünen önizleme çubuğu (sürümde yok).
  'önizleme (hata ayıklama)',
  r'önizleme +${saat}sa ${dk}dk',
};

final _harf = RegExp(r'[A-Za-zÇĞİÖŞÜçğıöşüâîû]{2,}');

/// Bir kaynak metindeki çevrilmemiş, ekrana yazılan dizgeler (değerleri).
List<String> cevrilmemisler(String kaynak) {
  final sonuc = <String>[];
  for (final g in dizgeGruplari(kaynak)) {
    // Ekrana yazılan konum YA DA çeviri çağrısına sarılı (sarılı ama sözlükte
    // karşılığı yoksa o da Türkçe kalır).
    final sarili = g.kapsayanCagri == 't' || g.kapsayanCagri == 'translate';
    if (!goruntuKonumuMu(g) && !sarili) continue;
    final ornek = g.degerYerine('1'); // ${...} yerine örnek sayı
    final statik = g.degerYerine('');
    if (!_harf.hasMatch(statik)) continue; // harf yok: sayı/simge
    if (muaf.contains(g.deger)) continue;
    // Sarılı ise sözlükte karşılığı olmalı; sarılı DEĞİLSE ekrana Türkçe çıkar
    // (sözlükte karşılığı olsa bile: Text çeviri yapmaz).
    if (sarili &&
        (Ceviri.cevrilebilir(g.deger) || Ceviri.cevrilebilir(ornek))) {
      continue;
    }
    sonuc.add(g.deger);
  }
  return sonuc;
}

Set<String> tumCevrilmemisler() {
  final cikti = <String>{};
  for (final f in Directory('lib').listSync(recursive: true)) {
    if (f is! File || !f.path.endsWith('.dart')) continue;
    final yol = f.path.replaceAll('\\', '/');
    if (yol.startsWith('lib/core/i18n/') ||
        yol.endsWith('firebase_options.dart')) {
      continue;
    }
    for (final d in cevrilmemisler(f.readAsStringSync())) {
      cikti.add('$yol|${d.replaceAll('\n', r'\n')}');
    }
  }
  return cikti;
}

void main() {
  group('tarayıcının kendisi', () {
    test(
        'Text içindeki çevrilmemiş Türkçe metin bulunur; çevrilmiş olan bulunmaz',
        () {
      const kaynak = '''
        Text("Bu çevrilmemiş bir cümle"),
        Text(context.t("Vazgeç")),
        Text(authService.translate("Vazgeç")),
      ''';
      expect(cevrilmemisler(kaynak), ['Bu çevrilmemiş bir cümle']);
    });

    test('adlandırılmış argümanlar (tooltip, hintText, title) taranır', () {
      const kaynak = '''
        IconButton(tooltip: "Kalem simgesi", onPressed: f),
        TextField(decoration: InputDecoration(hintText: "Bir şeyler yazın")),
        Tile(title: "Başlık burada"),
      ''';
      expect(cevrilmemisler(kaynak),
          ['Kalem simgesi', 'Bir şeyler yazın', 'Başlık burada']);
    });

    test('üçlü koşuldaki iki dal da taranır; sarılı üçlü koşul taranmaz', () {
      const kaynak = '''
        Text(x ? "Birinci dal metni" : "İkinci dal metni"),
        Text(context.t(x ? "Vazgeç" : "Sil")),
      ''';
      expect(cevrilmemisler(kaynak), ['Birinci dal metni', 'İkinci dal metni']);
    });

    test('çevrilebilir kalıp (sayı içeren) hata sayılmaz', () {
      const kaynak = r'''
        Text(context.t("${s.versesCount} ayet")),
        Text(context.t("$n. Cüz")),
      ''';
      expect(cevrilmemisler(kaynak), isEmpty);
    });

    test('ekrana yazılmayan konumlar taranmaz (debugPrint, anahtar, yorum)',
        () {
      const kaynak = '''
        debugPrint("Bu bir günlük iletisi");
        final anahtar = "kaydedilen_deger_türkçe";
        // Text("Yorum satırındaki metin")
        /* Text("Blok yorumdaki metin") */
      ''';
      expect(cevrilmemisler(kaynak), isEmpty);
    });

    test('sözlükte karşılığı olsa da SARILI olmayan Text bulunur', () {
      const kaynak = '''
        Text("Vazgeç"),
        Text(context.t("Vazgeç")),
      ''';
      expect(cevrilmemisler(kaynak), ['Vazgeç']);
    });

    test('çeviri çağrısına sarılı ama sözlükte olmayan metin de bulunur', () {
      const kaynak = '''
        Text(context.t("Sözlükte olmayan bir cümle")),
        Text(authService.translate("Sözlükte olmayan başka cümle")),
        Text(context.t("Vazgeç")),
      ''';
      expect(cevrilmemisler(kaynak),
          ['Sözlükte olmayan bir cümle', 'Sözlükte olmayan başka cümle']);
    });

    test('yalnız sayı/simge ve muaf özel adlar hata sayılmaz', () {
      const kaynak = r'''
        Text("100"),
        Text("${a}/${b}"),
        Text("x"),
        Text("Diyanet"),
      ''';
      expect(cevrilmemisler(kaynak), isEmpty);
    });

    test(
        'birleşik (komşu) dizgeler tek metin sayılır; ham ve üç tırnaklı işlenir',
        () {
      const kaynak = r"""
        Text("Bu uzun cümle " "iki parçadan oluşuyor"),
        Text(r'ham $dizge çevrilmemiş'),
        Text('''üç tırnaklı
          çevrilmemiş metin'''),
      """;
      expect(cevrilmemisler(kaynak), hasLength(3));
    });
  });

  test('lib/ altındaki hiçbir ekranda çevrilmemiş Türkçe metin yok', () {
    final kacaklar = tumCevrilmemisler().toList()..sort();

    expect(kacaklar, isEmpty,
        reason: 'Bu metinleri context.t(...) ile sarın ve İngilizcesini '
            'Ceviri/ek_ceviriler.dart sözlüğüne ekleyin (dilden bağımsızsa muafa).');
  });
}
