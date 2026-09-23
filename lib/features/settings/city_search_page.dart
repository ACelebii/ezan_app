import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:geolocator/geolocator.dart'
    show LocationAccuracy, LocationSettings;

import '../../core/models/city_list.dart';
import '../../core/services/konum_servisi.dart';
import '../../core/vakit/diyanet_kaynagi.dart' show DiyanetKaynagi, aramaMetni;
import '../../core/vakit/konum_esleyici.dart';
import '../../core/vakit/vakit_modelleri.dart';
import '../../core/vakit/yer_bulucu.dart';
import '../../locator.dart';
import 'settings_common.dart';

/// Türkiye'deki illerde arama; "Yurt Dışı" satırı dünya seçicisini açar. Hem
/// Ayarlar > Şehirler > Yeni Şehir Ekle hem de ana ekrandaki arama simgesi bunu
/// kullanır. Kapanırken `String` (il adı) ya da `Konum` (yurt dışı ya da GPS)
/// döndürür.
class CitySearchPage extends StatefulWidget {
  /// [konumBul] testte sahte bir "Konumumu kullan" vermek içindir; verilmezse
  /// gerçek GPS + Diyanet eşleştirmesi kullanılır.
  const CitySearchPage({super.key, this.konumBul});

  final Future<Konum> Function()? konumBul;

  @override
  State<CitySearchPage> createState() => _CitySearchPageState();
}

/// Cihazın konumunu alır ve Diyanet yerine (olmazsa koordinata) çevirir. Şehir
/// düzeyi yeterli olduğu için orta doğruluk istenir (kapalı mekânda da çalışır).
Future<Konum> _gercekKonumBul() async {
  final p = await KonumServisi().konumAl(
    ayar: const LocationSettings(
        accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 25)),
  );
  return KonumEsleyici(diyanet: locator<DiyanetKaynagi>())
      .bul(p.latitude, p.longitude);
}

class _CitySearchPageState extends State<CitySearchPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _konumAraniyor = false;

  /// Yazılan metne uyan iller. Türkçe harfler ve büyük/küçük harf fark etmez
  /// ("istanbul", "ISTANBUL" ve "İstanbul" aynıdır; "ığdır" ile "Iğdır" da).
  List<String> get _sonuclar {
    final aranan = aramaMetni(_searchController.text);
    if (aranan.isEmpty) return const [];
    return CityData.allCities
        .where((sehir) => aramaMetni(sehir).contains(aranan))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _konumumuKullan() async {
    if (_konumAraniyor) return;
    setState(() => _konumAraniyor = true);
    final authService = context.read<AuthService>();
    final mesajlar = ScaffoldMessenger.of(context);
    // Önceki denemenin uyarısı (ör. izin reddi) bu denemeden sonra asılı kalmasın:
    // sayfa kapanınca uyarı ana ekranda görünmeye devam ederdi.
    mesajlar.clearSnackBars();
    void uyar(String metin, {SnackBarAction? eylem}) {
      if (!mounted) return;
      setState(() => _konumAraniyor = false);
      mesajlar.showSnackBar(
          SnackBar(content: Text(authService.translate(metin)), action: eylem));
    }

    try {
      final konum = await (widget.konumBul ?? _gercekKonumBul)();
      mesajlar.clearSnackBars();
      if (mounted) context.pop(konum);
    } on KonumHatasi catch (h) {
      uyar(h.mesaj,
          eylem: h.sorun == KonumSorunu.izinKaliciReddedildi
              ? SnackBarAction(
                  label: authService.translate('Ayarlar'),
                  onPressed: () => KonumServisi().ayarlariAc())
              : null);
    } on YerBulucuHatasi catch (e) {
      debugPrint('Konum eşleştirilemedi: $e');
      uyar(
          'Bu konum için yer bulunamadı. İnternet bağlantınızı kontrol edip tekrar deneyin.');
    }
  }

  void _gonder(String metin) {
    final aranan = aramaMetni(metin);
    if (aranan.isEmpty) return;
    // Serbest metni doğrudan kabul etmek yerine, ancak listede gerçekten var
    // olan bir şehirle eşleşiyorsa (tam eşleşme ya da tek sonuç) kapat; aksi
    // halde yazım hataları olduğu gibi API'ye gitmesin.
    final tam = CityData.allCities.where((s) => aramaMetni(s) == aranan);
    if (tam.isNotEmpty) {
      context.pop(tam.first);
    } else if (_sonuclar.length == 1) {
      context.pop(_sonuclar.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final sonuclar = _sonuclar;
    return Directionality(
      textDirection: authService.uygulamaDili == "العربية"
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: getCardColor(context),
        appBar: AppBar(
            leading: buildBeautifulBackButton(context),
            backgroundColor: getCardColor(context),
            elevation: 0),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(authService.translate("Ara"),
                    style: TextStyle(
                        color: getTextColor(context),
                        fontSize: 34,
                        fontWeight: FontWeight.bold))),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: getTextColor(context)),
                autofocus: false,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                    hintText: authService.translate("Ara"),
                    hintStyle: TextStyle(color: getSubTextColor(context)),
                    prefixIcon:
                        Icon(Icons.search, color: getSubTextColor(context)),
                    filled: true,
                    fillColor: getTextFieldColor(context),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0)),
                onSubmitted: _gonder,
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: _konumAraniyor
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: getAccentColor(context)))
                  : Icon(Icons.my_location, color: getAccentColor(context)),
              title: Text(
                  authService.translate(_konumAraniyor
                      ? "Konum bulunuyor..."
                      : "Konumumu Kullan"),
                  style: TextStyle(color: getTextColor(context))),
              onTap: _konumAraniyor ? null : _konumumuKullan,
            ),
            Divider(color: getDividerColor(context), height: 1, indent: 16),
            ListTile(
              leading: Icon(Icons.public, color: getAccentColor(context)),
              title: Text(authService.translate("Yurt Dışı (Tüm Ülkeler)"),
                  style: TextStyle(color: getTextColor(context))),
              trailing:
                  Icon(Icons.chevron_right, color: getSubTextColor(context)),
              onTap: () async {
                final konum =
                    await context.push<Konum>('/settings/cities/dunya');
                if (konum != null && context.mounted) context.pop(konum);
              },
            ),
            Divider(color: getDividerColor(context), height: 1, indent: 16),
            Expanded(
              child: ListView.separated(
                itemCount: sonuclar.length,
                separatorBuilder: (context, index) => Divider(
                    color: getDividerColor(context), height: 1, indent: 16),
                itemBuilder: (context, index) => ListTile(
                    title: Text(sonuclar[index],
                        style: TextStyle(color: getTextColor(context))),
                    onTap: () => context.pop(sonuclar[index])),
              ),
            )
          ],
        ),
      ),
    );
  }
}
