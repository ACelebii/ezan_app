import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/auth_service.dart';

class ListeliLayout extends StatelessWidget {
  final String siradakiVakit;
  final Duration remainingTime;
  final List<Map<String, String>> vakitler;
  final Function(Duration) formatDuration;
  final Function(BuildContext, Color, Color) buildWeatherHeader;
  final Function(Map<String, String>, bool, Color, bool) buildOriginalVakitCard;
  final Function(String) translate;

  const ListeliLayout({
    super.key,
    required this.siradakiVakit,
    required this.remainingTime,
    required this.vakitler,
    required this.formatDuration,
    required this.buildWeatherHeader,
    required this.buildOriginalVakitCard,
    required this.translate,
  });

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = AppTheme.getTextColor(context);
    Color accentColor = AppTheme.getAccentColor(context);

    final anaVakitler = vakitler.where((v) => v['vakit'] != 'Güneş').toList();

    return Scaffold(
      backgroundColor: AppTheme.getBgColor(context),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            buildWeatherHeader(context, textColor, accentColor),
            const SizedBox(height: 15),
            Text(formatDuration(remainingTime),
                style: TextStyle(
                    color: textColor,
                    fontSize: 75,
                    fontWeight: FontWeight.w300)),
            Text("${translate(siradakiVakit)} ${translate("vaktine kalan")}",
                style: TextStyle(
                    color: accentColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.only(left: 15, right: 15, bottom: 100),
                itemCount: anaVakitler.length,
                itemBuilder: (context, index) {
                  var item = anaVakitler[index];
                  bool isNext = item['vakit'] == siradakiVakit;
                  return buildOriginalVakitCard(
                      item, isNext, accentColor, isDark);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
