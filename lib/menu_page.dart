import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_service.dart';
import 'settings_page.dart';
import 'kuran_page.dart';
import 'imsakiye_page.dart';
import 'pusula_page.dart';
import 'theme_selector_page.dart';
import 'zikirmatik_page.dart';
import 'dini_gunler_page.dart';
import 'hutbe_page.dart';

bool _isDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;
Color _getBgColor(BuildContext context) =>
    _isDark(context) ? Colors.black : const Color(0xFFF2F2F7);
Color _getCardColor(BuildContext context) =>
    _isDark(context) ? const Color(0xFF1C1C1E) : Colors.white;
Color _getIconBoxColor(BuildContext context) =>
    _isDark(context) ? const Color(0xFF2C2C2E) : Colors.grey.shade100;
Color _getTextColor(BuildContext context) =>
    _isDark(context) ? Colors.white : Colors.black87;

class MenuPage extends StatelessWidget {
  final VoidCallback onClose;
  const MenuPage({super.key, required this.onClose});

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.teal.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    // Menüdeki toplam 15 öğe (3 sütundan 5 satır tam oturması için ideal)
    final List<Map<String, dynamic>> menuItems = [
      {"t": "Kuran", "i": Icons.menu_book_rounded, "c": Colors.cyan.shade600},
      {
        "t": "Kütüphane",
        "i": Icons.library_books_rounded,
        "c": Colors.cyan.shade600
      },
      {
        "t": "Haftanın Hutbesi",
        "i": Icons.mic_external_on_rounded,
        "c": Colors.deepOrange.shade400
      },
      {
        "t": "Multimedya",
        "i": Icons.play_circle_filled_rounded,
        "c": Colors.deepOrange.shade400
      },
      {
        "t": "Dini Günler",
        "i": Icons.event_note_rounded,
        "c": Colors.cyan.shade600
      },
      {
        "t": "Ana Sayfa",
        "i": Icons.style_rounded,
        "c": Colors.deepOrange.shade400
      },
      {
        "t": "Zikirmatik",
        "i": Icons.touch_app_rounded,
        "c": Colors.cyan.shade600
      },
      {
        "t": "Yakın Camiler",
        "i": Icons.mosque_rounded,
        "c": Colors.cyan.shade600
      },
      {
        "t": "Hatim",
        "i": Icons.check_circle_outline_rounded,
        "c": Colors.cyan.shade600
      },
      {
        "t": "Kazalar",
        "i": Icons.fact_check_rounded,
        "c": Colors.cyan.shade600
      },
      {
        "t": "Ajanda",
        "i": Icons.edit_calendar_rounded,
        "c": Colors.cyan.shade600
      },
      {
        "t": "Ayarlar",
        "i": Icons.settings_rounded,
        "c": Colors.deepOrange.shade400
      },
      {
        "t": "İmsakiye",
        "i": Icons.calendar_month_rounded,
        "c": Colors.cyan.shade600
      },
      {
        "t": "Pusula",
        "i": Icons.explore_rounded,
        "c": Colors.deepOrange.shade400
      },
      {"t": "Dualar", "i": Icons.favorite_rounded, "c": Colors.cyan.shade600},
    ];

    return Directionality(
      textDirection: authService.uygulamaDili == "العربية"
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _getBgColor(context),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(authService.translate("Menü"),
              style: TextStyle(
                  color: _getTextColor(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 22)),
          backgroundColor: _getBgColor(context),
          centerTitle: false,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.tune_rounded, color: _getTextColor(context)),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsPage()));
              },
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    color: _isDark(context) ? Colors.white24 : Colors.black12,
                    shape: BoxShape.circle),
                child: Icon(Icons.close_rounded,
                    size: 16, color: _getTextColor(context)),
              ),
              onPressed: onClose,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: GridView.builder(
          physics: const BouncingScrollPhysics(),
          padding:
              const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: menuItems.length,
          itemBuilder: (context, index) {
            final item = menuItems[index];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  // SAYFA YÖNLENDİRMELERİ
                  if (item['t'] == 'Ayarlar') {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SettingsPage()));
                  } else if (item['t'] == 'Kuran') {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const KuranPage()));
                  } else if (item['t'] == 'Ana Sayfa') {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ThemeSelectorPage()));
                  } else if (item['t'] == 'İmsakiye') {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ImsakiyePage()));
                  } else if (item['t'] == 'Pusula') {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const PusulaPage()));
                  } else if (item['t'] == 'Zikirmatik') {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ZikirmatikPage()));
                  } else if (item['t'] == 'Dini Günler') {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const DiniGunlerPage()));
                  } else if (item['t'] == 'Haftanın Hutbesi') {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const HaftaninHutbesiPage()));
                  } else {
                    _showSnack(context,
                        "${authService.translate(item['t'])} yakında eklenecek...");
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                      color: _getCardColor(context),
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: _getIconBoxColor(context),
                            borderRadius: BorderRadius.circular(14)),
                        child: Icon(item['i'], color: item['c'], size: 30),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          authService.translate(item['t']),
                          style: TextStyle(
                              color: _getTextColor(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
