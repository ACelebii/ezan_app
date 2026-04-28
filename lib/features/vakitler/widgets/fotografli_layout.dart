import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/assets_constants.dart';
import '../../auth/auth_service.dart';

class FotografliLayout extends StatelessWidget {
  final String siradakiVakit;
  final Duration remainingTime;
  final List<Map<String, String>> vakitler;
  final Function(BuildContext, Color, Color) buildWeatherHeader;
  final Function(int) getMonthName;
  final Function(int) getDayName;

  const FotografliLayout({
    super.key,
    required this.siradakiVakit,
    required this.remainingTime,
    required this.vakitler,
    required this.buildWeatherHeader,
    required this.getMonthName,
    required this.getDayName,
  });

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    Color accentColor = Colors.redAccent.shade200;
    String mosqueBg = Assets.fotografCamiteMa;

    String hours = remainingTime.inHours.toString().padLeft(2, '0');
    String minutes = (remainingTime.inMinutes % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Transform.scale(
            scale: 1.06,
            child: Image.asset(mosqueBg,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (c, e, s) =>
                    Container(color: AppTheme.getBgColor(context))),
          ),
          Container(color: Colors.black.withOpacity(0.35)),
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 5,
              bottom: MediaQuery.of(context).padding.bottom + 90,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  buildWeatherHeader(context, Colors.white, Colors.white),
                  const SizedBox(height: 25),
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(hours,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 75,
                                  fontWeight: FontWeight.w300,
                                  height: 1.0)),
                          const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 4.0, vertical: 10.0),
                            child: Text(":",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 50,
                                    fontWeight: FontWeight.w300)),
                          ),
                          Text(minutes,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 75,
                                  fontWeight: FontWeight.w300,
                                  height: 1.0)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                          "${authService.translate(siradakiVakit)} ${authService.translate("vaktine kalan")}",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5)),
                    ],
                  ),
                  const SizedBox(height: 35),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 11,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: vakitler.map((item) {
                                bool isNext = item['vakit'] == siradakiVakit;
                                Color textColor =
                                    isNext ? accentColor : Colors.white70;
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                          authService.translate(item['vakit']!),
                                          style: TextStyle(
                                              color: textColor,
                                              fontSize: 18,
                                              fontWeight: isNext
                                                  ? FontWeight.bold
                                                  : FontWeight.w500)),
                                      Text(item['saat']!,
                                          style: TextStyle(
                                              color: textColor,
                                              fontSize: 18,
                                              fontWeight: isNext
                                                  ? FontWeight.bold
                                                  : FontWeight.w500)),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          flex: 6,
                          child: Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  children: [
                                    Text(DateTime.now().day.toString(),
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 34,
                                            fontWeight: FontWeight.w400)),
                                    Text(
                                        authService.translate(
                                            getMonthName(DateTime.now().month)),
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 16)),
                                    Text(
                                        authService.translate(
                                            getDayName(DateTime.now().weekday)),
                                        style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 15),
                              Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Text("9 Shawwal\n1447",
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          height: 1.1),
                                      textAlign: TextAlign.center),
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}


