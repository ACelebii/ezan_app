import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_button.dart';
import '../auth/auth_service.dart';
import 'providers/dini_gunler_provider.dart';
import 'dini_gunler_model.dart';

// ============================================================================
// 1. ANA LİSTE SAYFASI
// ============================================================================
class DiniGunlerPage extends StatelessWidget {
  const DiniGunlerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DiniGunlerProvider(),
      child: const _DiniGunlerPageContent(),
    );
  }
}

class _DiniGunlerPageContent extends StatefulWidget {
  const _DiniGunlerPageContent();

  @override
  State<_DiniGunlerPageContent> createState() => _DiniGunlerPageState();
}

class _DiniGunlerPageState extends State<_DiniGunlerPageContent> {
  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final authService = context.watch<AuthService>();
    final provider = context.watch<DiniGunlerProvider>();
    Color bgColor = AppTheme.getBgColor(context);
    Color textColor = AppTheme.getTextColor(context);

    // Seçili yıla göre veriyi filtrele ve aylara göre grupla
    var gruplanmisVeri = provider.gruplanmisVeri;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst Bar (Geri ve Takvim Butonu)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GlassButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context)),

                  // Yıl Seçici Popup Menü
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isDark ? Colors.white24 : Colors.black12),
                    ),
                    child: PopupMenuButton<int>(
                      icon: Icon(Icons.calendar_month_rounded,
                          color: textColor, size: 20),
                      offset: const Offset(0, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                      onSelected: (yil) => provider.setYil(yil),
                      itemBuilder: (context) => provider.yillar.map((yil) {
                        return PopupMenuItem<int>(
                          value: yil,
                          child: Row(
                            children: [
                              if (provider.seciliYil == yil)
                                const Icon(Icons.check,
                                    size: 18, color: Colors.blue)
                              else
                                const SizedBox(width: 18),
                              const SizedBox(width: 12),
                              Text(yil.toString(),
                                  style: TextStyle(
                                      color: textColor,
                                      fontWeight: provider.seciliYil == yil
                                          ? FontWeight.bold
                                          : FontWeight.normal)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Büyük Başlık
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Text(
                "${authService.translate("Dini Günler")} ${provider.seciliYil}",
                style: TextStyle(
                    color: textColor,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5),
              ),
            ),

            // Gruplanmış Liste
            Expanded(
              child: gruplanmisVeri.isEmpty
                  ? Center(
                      child: Text("Bu yıla ait veri bulunamadı.",
                          style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black54)))
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      itemCount: gruplanmisVeri.keys.length,
                      itemBuilder: (context, index) {
                        String ayAdi = gruplanmisVeri.keys.elementAt(index);
                        List<DiniGunlerModel> oAyinGunleri =
                            gruplanmisVeri[ayAdi]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Ay Başlığı (Ocak, Şubat vb.)
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 16.0, bottom: 12.0),
                              child: Text(
                                authService.translate(ayAdi),
                                style: TextStyle(
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.grey.shade600,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),

                            // O aya ait günlerin kartları
                            Container(
                              decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1C1C1E)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: isDark
                                      ? []
                                      : [
                                          BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.03),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4))
                                        ]),
                              child: Column(
                                children:
                                    oAyinGunleri.asMap().entries.map((entry) {
                                  int i = entry.key;
                                  DiniGunlerModel gun = entry.value;
                                  bool isLast = i == oAyinGunleri.length - 1;

                                  return Column(
                                    children: [
                                      InkWell(
                                        borderRadius: BorderRadius.circular(
                                            isLast ? 20 : 0),
                                        onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    DiniGunDetayPage(
                                                        gunData: gun))),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16.0, horizontal: 16.0),
                                          child: Row(
                                            children: [
                                              // SOL KISIM (Tarih ve Gün)
                                              SizedBox(
                                                width: 80,
                                                child: Column(
                                                  children: [
                                                    Text(gun.gunNo,
                                                        style: TextStyle(
                                                            color: textColor,
                                                            fontSize: 26,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            height: 1.0)),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                        authService.translate(
                                                            gun.gunAd),
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                            color: isDark
                                                                ? Colors.white54
                                                                : Colors.grey
                                                                    .shade500,
                                                            fontSize: 12)),
                                                  ],
                                                ),
                                              ),

                                              // DİKEY KESİK ÇİZGİ
                                              Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10),
                                                width: 1,
                                                height: 45,
                                                color: isDark
                                                    ? Colors.white24
                                                    : Colors.grey.shade300,
                                              ),

                                              // SAĞ KISIM (Başlık ve Hicri)
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                        authService.translate(
                                                            gun.baslik),
                                                        style: const TextStyle(
                                                            color: Color(
                                                                0xFF6B4C7A),
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600)),
                                                    const SizedBox(height: 4),
                                                    Text(gun.hicri,
                                                        style: TextStyle(
                                                            color: isDark
                                                                ? Colors.white54
                                                                : Colors.grey
                                                                    .shade500,
                                                            fontSize: 13)),
                                                  ],
                                                ),
                                              ),

                                              Icon(
                                                  Icons
                                                      .arrow_forward_ios_rounded,
                                                  color: isDark
                                                      ? Colors.white38
                                                      : Colors.grey.shade400,
                                                  size: 16),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (!isLast)
                                        Divider(
                                            color: isDark
                                                ? Colors.white10
                                                : Colors.grey.shade200,
                                            height: 1,
                                            indent: 110),
                                    ],
                                  );
                                }).toList(),
                              ),
                            )
                          ],
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 2. DETAY SAYFASI
// ============================================================================
class DiniGunDetayPage extends StatelessWidget {
  final DiniGunlerModel gunData;
  const DiniGunDetayPage({super.key, required this.gunData});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final authService = context.watch<AuthService>();
    Color bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
    Color textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Üst Bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  GlassButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context)),
                  Expanded(
                    child: Center(
                      child: Text(
                        authService.translate(gunData.baslik),
                        style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40), // Ortalamak için boşluk
                ],
              ),
            ),

            const SizedBox(height: 10),

            // İçerik Kartı
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: isDark
                        ? []
                        : [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, -2))
                          ]),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authService.translate(gunData.detay),
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.grey.shade800,
                          fontSize: 16,
                          height: 1.6, // Satır arası boşluk
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
