import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/auth_service.dart';

class AnalogSaatLayout extends StatefulWidget {
  final String siradakiVakit;
  final Duration remainingTime;
  final Function(Duration) formatDuration;
  final Function(BuildContext, Color, Color) buildWeatherHeader;
  final Function(Color) buildCountdown;
  final Function(Color, bool) buildBoxGrid;
  final List<Map<String, String>> vakitler;

  const AnalogSaatLayout({
    super.key,
    required this.siradakiVakit,
    required this.remainingTime,
    required this.formatDuration,
    required this.buildWeatherHeader,
    required this.buildCountdown,
    required this.buildBoxGrid,
    required this.vakitler,
  });

  @override
  State<AnalogSaatLayout> createState() => _AnalogSaatLayoutState();
}

class _AnalogSaatLayoutState extends State<AnalogSaatLayout> {
  late DateTime _currentTime;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color accentColor = AppTheme.accentColor;
    Color textColor = AppTheme.getTextColor(context);

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
                widget.buildWeatherHeader(context, textColor, accentColor),
                const SizedBox(height: 40),
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white10, width: 4),
                      color: AppTheme.getCardColor(context),
                      boxShadow: [
                        BoxShadow(
                            color: accentColor.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 5)
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ...List.generate(12, (index) {
                          double angle = (index * 30) * pi / 180;
                          final romaRakamlari = [
                            "XII",
                            "I",
                            "II",
                            "III",
                            "IV",
                            "V",
                            "VI",
                            "VII",
                            "VIII",
                            "IX",
                            "X",
                            "XI"
                          ];
                          return Transform.rotate(
                            angle: angle,
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Container(
                                        width: index % 3 == 0 ? 4 : 2,
                                        height: 10,
                                        color: index % 3 == 0
                                            ? accentColor
                                            : Colors.white24),
                                  ),
                                  const SizedBox(height: 2),
                                  Transform.rotate(
                                    angle: -angle,
                                    child: Text(romaRakamlari[index],
                                        style: TextStyle(
                                            color: index % 3 == 0
                                                ? accentColor.withOpacity(0.8)
                                                : Colors.white54,
                                            fontSize: index % 3 == 0 ? 16 : 12,
                                            fontWeight: FontWeight.bold,
                                            height: 1.0)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        Transform.rotate(
                          angle: (_currentTime.hour % 12 +
                                  _currentTime.minute / 60) *
                              30 *
                              pi /
                              180,
                          child: Align(
                              alignment: Alignment.center,
                              child: Transform.translate(
                                  offset: const Offset(0, -30),
                                  child: Container(
                                      width: 7,
                                      height: 70,
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(4))))),
                        ),
                        Transform.rotate(
                          angle:
                              (_currentTime.minute + _currentTime.second / 60) *
                                  6 *
                                  pi /
                                  180,
                          child: Align(
                              alignment: Alignment.center,
                              child: Transform.translate(
                                  offset: const Offset(0, -45),
                                  child: Container(
                                      width: 5,
                                      height: 100,
                                      decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.7),
                                          borderRadius:
                                              BorderRadius.circular(2))))),
                        ),
                        Transform.rotate(
                          angle: _currentTime.second * 6 * pi / 180,
                          child: Align(
                              alignment: Alignment.center,
                              child: Transform.translate(
                                  offset: const Offset(0, -50),
                                  child: Container(
                                      width: 2,
                                      height: 120,
                                      decoration: BoxDecoration(
                                          color: accentColor,
                                          borderRadius:
                                              BorderRadius.circular(1))))),
                        ),
                        Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                                color: accentColor,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                widget.buildCountdown(accentColor),
                const SizedBox(height: 40),
                widget.buildBoxGrid(accentColor, false),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
