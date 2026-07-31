import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'kazalar_provider.dart';

class KazalarPage extends StatelessWidget {
  const KazalarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => KazalarProvider(),
      child: const KazalarView(),
    );
  }
}

class KazalarView extends StatelessWidget {
  const KazalarView({super.key});

  void _showManuelGirisDialog(BuildContext context, String vakit,
      int mevcutDeger, KazalarProvider provider) {
    final TextEditingController controller =
        TextEditingController(text: mevcutDeger.toString());
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            "$vakit Kazası",
            style: TextStyle(
                color: isDark ? Colors.white : Colors.black, fontSize: 18),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autofocus: true,
            style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? Colors.black26 : Colors.grey.shade100,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  Text("İptal", style: TextStyle(color: Colors.grey.shade500)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                int yeniDeger = int.tryParse(controller.text) ?? mevcutDeger;
                provider.topluDegerGir(vakit, yeniDeger);
                Navigator.pop(context);
              },
              child: const Text("Bitti",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KazalarProvider>();
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
    Color cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    Color textColor = isDark ? Colors.white : Colors.black;
    Color subTextColor = isDark ? Colors.white54 : Colors.black54;

    // Görseldeki İkonların Tam Karşılıkları
    final List<Map<String, dynamic>> namazVakitleri = [
      {"vakit": "Sabah", "icon": Icons.wb_twilight_rounded},
      {"vakit": "Öğle", "icon": Icons.light_mode_rounded},
      {"vakit": "İkindi", "icon": Icons.wb_sunny_rounded},
      {"vakit": "Akşam", "icon": Icons.nights_stay_rounded},
      {"vakit": "Yatsı", "icon": Icons.nightlight_round},
      {"vakit": "Vitr", "icon": Icons.nightlight_round},
    ];

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
          "Kazalar",
          style: TextStyle(
              color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: namazVakitleri.map((item) {
                  return _buildKazaSatiri(
                      context,
                      item["vakit"],
                      Icon(item["icon"], color: subTextColor, size: 26),
                      provider,
                      item == namazVakitleri.last,
                      isDark,
                      textColor,
                      subTextColor);
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                "Toplu kaza girişi için rakamların üzerine dokununuz.\n(*) Son Kayıt Tarihi",
                style:
                    TextStyle(color: subTextColor, fontSize: 13, height: 1.4),
              ),
            ),
            const SizedBox(height: 24),

            // ORUÇ KARTI (İlk baştaki sade ikon ile)
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: _buildKazaSatiri(
                  context,
                  "Oruç",
                  Icon(Icons.restaurant_menu_rounded,
                      color: Colors.teal.shade400, size: 26),
                  provider,
                  true,
                  isDark,
                  textColor,
                  subTextColor),
            ),
            const SizedBox(height: 24),

            // ÖZEL PRO / İKONDA GÖSTER TASARIMI
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Cami ikonlu PRO Badge tasarımı
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.deepOrange, Colors.orangeAccent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.mosque_rounded,
                                color: Colors.white, size: 26),
                          ),
                          Positioned(
                            top: -6,
                            left: -6,
                            child: Text(
                              "Pro",
                              style: TextStyle(
                                  color: Colors.amber.shade300,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FontStyle.italic),
                            ),
                          ),
                          if (provider.toplamKazaSayisi > 0)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                    color: Colors.red, shape: BoxShape.circle),
                                child: Text(
                                    provider.toplamKazaSayisi > 99
                                        ? "99+"
                                        : "${provider.toplamKazaSayisi}",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                              ),
                            )
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text("Kaza sayısını iconda göster",
                            style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w500)),
                      ),
                      Switch(
                        value: provider.ikondaGoster,
                        onChanged: (val) =>
                            provider.ikonGosteriminiDegistir(val),
                        activeThumbColor: Colors.white,
                        activeTrackColor: Colors.white30,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.white12,
                      )
                    ],
                  ),
                  if (provider.ikondaGoster && !provider.badgeDestekleniyor)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 60),
                      child: Text(
                        "Bu cihazın ana ekranı sayısal rozetleri desteklemiyor; "
                        "yalnızca bildirim noktası gösterilebilir.",
                        style: TextStyle(color: subTextColor, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildKazaSatiri(
      BuildContext context,
      String vakit,
      Widget iconWidget,
      KazalarProvider provider,
      bool isLast,
      bool isDark,
      Color textColor,
      Color subTextColor) {
    int deger = provider.kazaSayilari[vakit] ?? 0;
    String tarih = provider.sonKayitTarihleri[vakit] ?? "";

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              // İkon
              SizedBox(width: 32, height: 32, child: Center(child: iconWidget)),
              const SizedBox(width: 16),

              // Başlık ve Tarih
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vakit,
                        style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(tarih.isEmpty ? "Henüz kayıt yok" : tarih,
                        style: TextStyle(color: subTextColor, fontSize: 12)),
                  ],
                ),
              ),

              // Rakam (Tıklanabilir)
              GestureDetector(
                onTap: () =>
                    _showManuelGirisDialog(context, vakit, deger, provider),
                child: Container(
                  width: 45,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: Colors.transparent,
                  alignment: Alignment.center,
                  child: Text(
                    deger.toString(),
                    style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // + / - Butonları (Kapsül Tasarım)
              Container(
                height: 38,
                decoration: BoxDecoration(
                  color:
                      isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => provider.azalt(vakit),
                      borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Icon(Icons.remove, color: textColor, size: 20),
                      ),
                    ),
                    Container(
                        width: 1,
                        height: 20,
                        color: subTextColor.withValues(alpha: 0.3)),
                    InkWell(
                      onTap: () => provider.artir(vakit),
                      borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Icon(Icons.add, color: textColor, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
              height: 1,
              indent: 64,
              endIndent: 16,
              color: subTextColor.withValues(alpha: 0.15)),
      ],
    );
  }
}
