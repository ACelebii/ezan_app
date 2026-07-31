import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../auth/auth_service.dart';
import 'ajanda_provider.dart';

// 1. ADIM: SAYFA SARICI (PROVIDER BURADA OLUŞTURULUYOR)
class AjandaTimelinePage extends StatelessWidget {
  const AjandaTimelinePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Tıpkı Dualar sayfasında yaptığın gibi, sadece bu sayfa için Provider oluşturuyoruz
    return ChangeNotifierProvider(
      create: (_) => AjandaProvider(),
      child: const AjandaTimelineView(),
    );
  }
}

// 2. ADIM: ASIL ARAYÜZ (GÖRÜNÜM)
class AjandaTimelineView extends StatefulWidget {
  const AjandaTimelineView({super.key});

  @override
  State<AjandaTimelineView> createState() => _AjandaTimelineViewState();
}

class _AjandaTimelineViewState extends State<AjandaTimelineView> {
  final double hourHeight = 60.0;

  // Aynı gün/şehir/yöntem için tekrar ağ isteği atmamak adına basit bellek içi önbellek.
  final Map<String, List<Map<String, dynamic>>> _cache = {};

  List<Map<String, dynamic>>? _vakitler;
  bool _isLoading = true;
  bool _hasError = false;

  DateTime? _sonCekilenTarih;
  String? _sonCekilenSehir;
  int? _sonCekilenYontem;

  // Kullanıcı gün değiştirme okuna hızlı basarsa eski bir isteğin geç gelen
  // yanıtı, daha yeni bir isteğin sonucunun üzerine yazmasın diye.
  int _istekSayaci = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.watch<AjandaProvider>();
    final authService = context.watch<AuthService>();
    final sehir = authService.seciliSehir['isim'] as String? ?? 'İstanbul';
    final yontem = authService.apiMethod;

    if (_sonCekilenTarih != provider.seciliTarih ||
        _sonCekilenSehir != sehir ||
        _sonCekilenYontem != yontem) {
      _sonCekilenTarih = provider.seciliTarih;
      _sonCekilenSehir = sehir;
      _sonCekilenYontem = yontem;
      _vakitleriGetir(provider.seciliTarih, sehir, yontem);
    }
  }

  String _cacheAnahtari(DateTime tarih, String sehir, int yontem) =>
      '${tarih.year}-${tarih.month}-${tarih.day}_${sehir}_$yontem';

  Future<void> _vakitleriGetir(
      DateTime tarih, String sehir, int yontem) async {
    final anahtar = _cacheAnahtari(tarih, sehir, yontem);
    final istekNo = ++_istekSayaci;
    final onbellek = _cache[anahtar];
    if (onbellek != null) {
      setState(() {
        _vakitler = onbellek;
        _isLoading = false;
        _hasError = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final tarihStr = '${tarih.day.toString().padLeft(2, '0')}-'
          '${tarih.month.toString().padLeft(2, '0')}-${tarih.year}';
      final url = Uri.parse(
          'https://api.aladhan.com/v1/timingsByCity/$tarihStr?city=${Uri.encodeComponent(sehir)}&country=Turkey&method=$yontem');
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final timings =
          json.decode(response.body)['data']['timings'] as Map<String, dynamic>;
      final vakitler = _timingsToList(timings);
      _cache[anahtar] = vakitler;
      // Bu istek beklerken kullanıcı başka bir güne geçmiş olabilir; sadece
      // hâlâ en güncel istek buysa sonucu uygula.
      if (!mounted || istekNo != _istekSayaci) return;
      setState(() {
        _vakitler = vakitler;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted || istekNo != _istekSayaci) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  ({int saat, int dakika}) _saatParcala(Map<String, dynamic> timings, String key) {
    final raw = (timings[key] as String).split(' ').first;
    final parcalar = raw.split(':');
    return (saat: int.parse(parcalar[0]), dakika: int.parse(parcalar[1]));
  }

  ({int saat, int dakika}) _dakikaEkle(({int saat, int dakika}) t, int dakika) {
    final toplam = ((t.saat * 60 + t.dakika + dakika) % 1440 + 1440) % 1440;
    return (saat: toplam ~/ 60, dakika: toplam % 60);
  }

  List<Map<String, dynamic>> _timingsToList(Map<String, dynamic> timings) {
    Map<String, dynamic> girdi(String isim, ({int saat, int dakika}) t) => {
          "isim": isim,
          "saat": t.saat,
          "dakika": t.dakika,
          "renk": Colors.redAccent,
        };

    final gunes = _saatParcala(timings, 'Sunrise');
    // Aladhan İşrak/Duha döndürmez; bu iki vakit yaygın kabul edilen sabit
    // ofsetlerle Güneş vaktinden türetilir (İşrak: +45 dk, Duha: +65 dk).
    final israk = _dakikaEkle(gunes, 45);
    final duha = _dakikaEkle(gunes, 65);

    return [
      girdi("İmsak", _saatParcala(timings, 'Fajr')),
      girdi("Güneş", gunes),
      girdi("İşrak", israk),
      girdi("Duha", duha),
      girdi("Öğle", _saatParcala(timings, 'Dhuhr')),
      girdi("İkindi", _saatParcala(timings, 'Asr')),
      girdi("Akşam", _saatParcala(timings, 'Maghrib')),
      girdi("Yatsı", _saatParcala(timings, 'Isha')),
    ];
  }

  String _formatDate(DateTime date) {
    const aylar = [
      "",
      "Ocak",
      "Şubat",
      "Mart",
      "Nisan",
      "Mayıs",
      "Haziran",
      "Temmuz",
      "Ağustos",
      "Eylül",
      "Ekim",
      "Kasım",
      "Aralık"
    ];
    const gunler = [
      "",
      "Pazartesi",
      "Salı",
      "Çarşamba",
      "Perşembe",
      "Cuma",
      "Cumartesi",
      "Pazar"
    ];
    return "${date.day} ${aylar[date.month]} ${gunler[date.weekday]}";
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AjandaProvider>();
    final authService = context.watch<AuthService>();
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
    Color textColor = isDark ? Colors.white : Colors.black;
    Color dividerColor = isDark ? Colors.white10 : Colors.black12;
    Color subTextColor = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _formatDate(provider.seciliTarih),
          style: TextStyle(
              color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_hasError)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off_rounded,
                        size: 56, color: subTextColor),
                    const SizedBox(height: 16),
                    Text(
                      authService.translate(
                          "Vakitler yüklenemedi. Lütfen internet bağlantınızı kontrol edin."),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: subTextColor, height: 1.4),
                    ),
                  ],
                ),
              ),
            )
          else
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 100),
                child: Stack(
                  children: [
                    Column(
                      children: List.generate(24, (index) {
                        return SizedBox(
                          height: hourHeight,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 60,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 16.0),
                                  child: Text(
                                    "${index.toString().padLeft(2, '0')}:00",
                                    style: TextStyle(
                                        color: subTextColor, fontSize: 13),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Divider(
                                        color: dividerColor,
                                        height: 1,
                                        thickness: 1),
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
                      }),
                    ),
                    ...(_vakitler ?? []).map((vakit) {
                      double topPosition = (vakit["saat"] * hourHeight) +
                          (vakit["dakika"] * (hourHeight / 60));

                      return Positioned(
                        top: topPosition - 8,
                        left: 60,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Text(
                                "${vakit["saat"].toString().padLeft(2, '0')}:${vakit["dakika"].toString().padLeft(2, '0')}",
                                style: TextStyle(
                                    color: vakit["renk"],
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                authService.translate(vakit["isim"]),
                                style: TextStyle(
                                    color: vakit["renk"],
                                    fontSize: 15,
                                    fontWeight: FontWeight.normal),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FloatingActionButton(
                  heroTag: "prev",
                  backgroundColor:
                      isDark ? const Color(0xFF2C2C2E) : Colors.white,
                  elevation: 2,
                  onPressed: () => provider.oncekiGun(),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      color: textColor, size: 18),
                ),
                if (!provider.isBugun)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isDark ? const Color(0xFF2C2C2E) : Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12)),
                    onPressed: () => provider.buguneDon(),
                    child: Text(
                      authService.translate("Bugün"),
                      style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ),
                FloatingActionButton(
                  heroTag: "next",
                  backgroundColor:
                      isDark ? const Color(0xFF2C2C2E) : Colors.white,
                  elevation: 2,
                  onPressed: () => provider.sonrakiGun(),
                  child: Icon(Icons.arrow_forward_ios_rounded,
                      color: textColor, size: 18),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
