import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/auth_service.dart';

class TimelineLayout extends StatelessWidget {
  final String siradakiVakit;
  final Duration remainingTime;
  final List<Map<String, String>> vakitler;
  final Function(Duration) formatDuration;
  final Function(BuildContext, Color, Color) buildWeatherHeader;
  final Function(String) translate;

  const TimelineLayout({
    super.key,
    required this.siradakiVakit,
    required this.remainingTime,
    required this.vakitler,
    required this.formatDuration,
    required this.buildWeatherHeader,
    required this.translate,
  });

  @override
  Widget build(BuildContext context) {
    Color accentColor = Colors.tealAccent;
    Color textColor = AppTheme.getTextColor(context);

    final anaVakitler = vakitler.where((v) => v['vakit'] != 'Güneş').toList();

    return Scaffold(
      backgroundColor: AppTheme.getBgColor(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            buildWeatherHeader(context, textColor, accentColor),
            Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(translate(siradakiVakit),
                      style: TextStyle(
                          color: textColor,
                          fontSize: 32,
                          fontWeight: FontWeight.bold)),
                  Text(formatDuration(remainingTime),
                      style: TextStyle(
                          color: accentColor,
                          fontSize: 48,
                          fontWeight: FontWeight.w300)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                  padding:
                      const EdgeInsets.only(left: 30, right: 30, bottom: 100),
                  itemCount: anaVakitler.length,
                  itemBuilder: (context, index) {
                    final item = anaVakitler[index];
                    bool isNext = item['vakit'] == siradakiVakit;
                    return IntrinsicHeight(
                      child: Row(
                        children: [
                          Column(
                            children: [
                              Container(
                                  width: 2,
                                  height: 20,
                                  color: index == 0
                                      ? Colors.transparent
                                      : AppTheme.getDividerColor(context)),
                              Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                      color: isNext
                                          ? accentColor
                                          : AppTheme.getDividerColor(context),
                                      shape: BoxShape.circle)),
                              Expanded(
                                  child: Container(
                                      width: 2,
                                      color: index == anaVakitler.length - 1
                                          ? Colors.transparent
                                          : AppTheme.getDividerColor(context))),
                            ],
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(translate(item['vakit']!),
                                      style: TextStyle(
                                          color:
                                              isNext ? accentColor : textColor,
                                          fontSize: 20,
                                          fontWeight: isNext
                                              ? FontWeight.bold
                                              : FontWeight.w500)),
                                  Text(item['saat']!,
                                      style: TextStyle(
                                          color: isNext
                                              ? accentColor
                                              : AppTheme.getSubTextColor(
                                                  context),
                                          fontSize: 20,
                                          fontWeight: isNext
                                              ? FontWeight.bold
                                              : FontWeight.normal)),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    );
                  }),
            )
          ],
        ),
      ),
    );
  }
}
