import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import '../../auth/auth_service.dart';
import '../../kuran/kuran_page.dart';
import '../../pusula/pusula_page.dart';
import '../../imsakiye/imsakiye_page.dart';
import '../../settings/settings_page.dart';
import '../../zikirmatik/zikirmatik_page.dart';

class DashboardLayout extends StatelessWidget {
  final String siradakiVakit;
  final Duration remainingTime;
  final Function(BuildContext, Color, Color) buildWeatherHeader;
  final Function(Color) buildCountdown;
  final Function(Color, bool) buildBoxGrid;
  final Function(String) translate;

  const DashboardLayout({
    super.key,
    required this.siradakiVakit,
    required this.remainingTime,
    required this.buildWeatherHeader,
    required this.buildCountdown,
    required this.buildBoxGrid,
    required this.translate,
  });

  @override
  Widget build(BuildContext context) {
    Color accentColor = AppTheme.primaryColor;
    final authService = context.read<AuthService>();

    final icons = [
      {"i": Icons.menu_book_rounded, "t": "Kuran", "page": const KuranPage()},
      {"i": Icons.library_books_rounded, "t": "Kütüphane", "page": null},
      {"i": Icons.explore_rounded, "t": "Pusula", "page": const PusulaPage()},
      {
        "i": Icons.calendar_month_rounded,
        "t": "İmsakiye",
        "page": const ImsakiyePage()
      },
      {
        "i": Icons.touch_app_rounded,
        "t": "Zikirmatik",
        "page": ZikirmatikPage()
      },
      {"i": Icons.mosque_rounded, "t": "Camiler", "page": null},
      {"i": Icons.favorite_rounded, "t": "Dualar", "page": null},
      {
        "i": Icons.settings_rounded,
        "t": "Ayarlar",
        "page": const SettingsPage()
      },
    ];

    return Scaffold(
      backgroundColor: AppTheme.getBgColor(context),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              children: [
                const SizedBox(height: 20),
                buildWeatherHeader(
                    context, AppTheme.getTextColor(context), accentColor),
                const SizedBox(height: 30),
                buildCountdown(accentColor),
                const SizedBox(height: 40),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 25,
                      crossAxisSpacing: 15),
                  itemCount: icons.length,
                  itemBuilder: (c, i) {
                    final item = icons[i];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          if (item["page"] != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => item["page"] as Widget),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  "${translate(item["t"] as String)} yakında eklenecek...",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                              backgroundColor: accentColor.withOpacity(0.8),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 1),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ));
                          }
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(item["i"] as IconData,
                                color: accentColor, size: 30),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Text(translate(item["t"] as String),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: AppTheme.getSubTextColor(context),
                                      fontSize: 11)),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                buildBoxGrid(accentColor, false),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
