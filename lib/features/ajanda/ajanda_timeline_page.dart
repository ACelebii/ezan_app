import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
class AjandaTimelineView extends StatelessWidget {
  const AjandaTimelineView({super.key});

  final double hourHeight = 60.0;

  List<Map<String, dynamic>> _getGunlukVakitler(DateTime tarih) {
    return [
      {"isim": "İmsak", "saat": 4, "dakika": 11, "renk": Colors.redAccent},
      {"isim": "Güneş", "saat": 5, "dakika": 51, "renk": Colors.redAccent},
      {"isim": "İşrak", "saat": 6, "dakika": 36, "renk": Colors.redAccent},
      {"isim": "Duha", "saat": 6, "dakika": 56, "renk": Colors.redAccent},
      {"isim": "Öğle", "saat": 13, "dakika": 5, "renk": Colors.redAccent},
      {"isim": "İkindi", "saat": 16, "dakika": 57, "renk": Colors.redAccent},
      {"isim": "Akşam", "saat": 20, "dakika": 11, "renk": Colors.redAccent},
      {"isim": "Yatsı", "saat": 21, "dakika": 45, "renk": Colors.redAccent},
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

    // Varsayılan renkleri tema yapına göre düzenleyebilirsin
    Color bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
    Color textColor = isDark ? Colors.white : Colors.black;
    Color dividerColor = isDark ? Colors.white10 : Colors.black12;
    Color subTextColor = isDark ? Colors.white54 : Colors.black54;

    final vakitler = _getGunlukVakitler(provider.seciliTarih);

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
        actions: [
          IconButton(
            icon: Icon(Icons.menu_rounded, color: textColor),
            onPressed: () {},
          )
        ],
      ),
      body: Stack(
        children: [
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
                  ...vakitler.map((vakit) {
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
