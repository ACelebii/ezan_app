import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/gradient_feature_icon.dart';
import '../auth/auth_service.dart';

bool _isDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;
Color _getBgColor(BuildContext context) =>
    _isDark(context) ? Colors.black : const Color(0xFFF2F2F7);
Color _getCardColor(BuildContext context) =>
    _isDark(context) ? const Color(0xFF1C1C1E) : Colors.white;
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
        backgroundColor: Colors.teal.withValues(alpha: 0.8),
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
      {"t": "Kuran", "k": GradientFeatureIconKey.kuran},
      {"t": "Kütüphane", "k": GradientFeatureIconKey.kutuphane},
      {"t": "Haftanın Hutbesi", "k": GradientFeatureIconKey.hutbe},
      {"t": "Multimedya", "k": GradientFeatureIconKey.multimedya},
      {"t": "Dini Günler", "k": GradientFeatureIconKey.diniGunler},
      {"t": "Ana Sayfa", "k": GradientFeatureIconKey.anaSayfa},
      {"t": "Zikirmatik", "k": GradientFeatureIconKey.zikirmatik},
      {"t": "Yakın Camiler", "k": GradientFeatureIconKey.camiler},
      {"t": "Hatim", "k": GradientFeatureIconKey.hatim},
      {"t": "Kazalar", "k": GradientFeatureIconKey.kazalar},
      {"t": "Ajanda", "k": GradientFeatureIconKey.ajanda},
      {"t": "Ayarlar", "k": GradientFeatureIconKey.ayarlar},
      {"t": "İmsakiye", "k": GradientFeatureIconKey.imsakiye},
      {"t": "Pusula", "k": GradientFeatureIconKey.pusula},
      {"t": "Dualar", "k": GradientFeatureIconKey.dualar},
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
              onPressed: () => context.push('/settings'),
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
                    context.push('/settings');
                  } else if (item['t'] == 'Kuran') {
                    context.push('/kuran');
                  } else if (item['t'] == 'Ana Sayfa') {
                    context.push('/settings/theme');
                  } else if (item['t'] == 'İmsakiye') {
                    context.push('/imsakiye');
                  } else if (item['t'] == 'Pusula') {
                    context.push('/pusula');
                  } else if (item['t'] == 'Zikirmatik') {
                    context.push('/zikirmatik');
                  } else if (item['t'] == 'Dini Günler') {
                    context.push('/dini-gunler');
                  } else if (item['t'] == 'Haftanın Hutbesi') {
                    context.push('/hutbe');
                  } else if (item['t'] == 'Yakın Camiler') {
                    context.push('/camiler');
                  } else if (item['t'] == 'Dualar') {
                    context.push('/dualar');
                  } else if (item['t'] == 'Kazalar') {
                    context.push('/kazalar');
                  } else if (item['t'] == 'Hatim') {
                    context.push('/hatim');
                  } else if (item['t'] == 'Ajanda') {
                    Permission.calendarFullAccess.status.then((status) async {
                      if (status.isGranted) {
                        if (context.mounted) {
                          context.push('/ajanda');
                        }
                      } else {
                        final result =
                            await Permission.calendarFullAccess.request();

                        if (result.isGranted) {
                          if (context.mounted) {
                            context.push('/ajanda');
                          }
                        } else if (result.isPermanentlyDenied) {
                          if (context.mounted) {
                            _showSnack(context,
                                "Ayarlardan takvim izni vermeniz gerekiyor.");
                          }
                          Future.delayed(const Duration(seconds: 1), () {
                            openAppSettings();
                          });
                        } else {
                          if (context.mounted) {
                            _showSnack(context,
                                "Ajanda özelliğini kullanmak için izin gereklidir.");
                          }
                        }
                      }
                    });
                  } else if (item['t'] == 'Kütüphane') {
                    context.push('/kutuphane');
                  } else if (item['t'] == 'Multimedya') {
                    context.push('/multimedya');
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
                      GradientFeatureIcon(
                        iconKey: item['k'] as GradientFeatureIconKey,
                        size: 46,
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
