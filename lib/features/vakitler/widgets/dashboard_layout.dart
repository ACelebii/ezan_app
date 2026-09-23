import '../../../core/i18n/cevir.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gradient_feature_icon.dart';

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

    final icons = [
      {"k": GradientFeatureIconKey.kuran, "t": "Kuran", "path": "/kuran"},
      {
        "k": GradientFeatureIconKey.kutuphane,
        "t": "Kütüphane",
        "path": "/kutuphane"
      },
      {"k": GradientFeatureIconKey.pusula, "t": "Pusula", "path": "/pusula"},
      {
        "k": GradientFeatureIconKey.imsakiye,
        "t": "İmsakiye",
        "path": "/imsakiye"
      },
      {
        "k": GradientFeatureIconKey.zikirmatik,
        "t": "Zikirmatik",
        "path": "/zikirmatik"
      },
      {"k": GradientFeatureIconKey.camiler, "t": "Camiler", "path": "/camiler"},
      {"k": GradientFeatureIconKey.dualar, "t": "Dualar", "path": "/dualar"},
      {
        "k": GradientFeatureIconKey.ayarlar,
        "t": "Ayarlar",
        "path": "/settings"
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
                          if (item["path"] != null) {
                            context.push(item["path"] as String);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  context.t(
                                      "${translate(item["t"] as String)} yakında eklenecek..."),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                              backgroundColor:
                                  accentColor.withValues(alpha: 0.8),
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
                            GradientFeatureIcon(
                              iconKey: item["k"] as GradientFeatureIconKey,
                              size: 40,
                            ),
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
