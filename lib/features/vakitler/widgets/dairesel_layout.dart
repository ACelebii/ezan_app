import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/assets_constants.dart';

class DaireselLayout extends StatelessWidget {
  final double timeProgress;
  final String siradakiVakit;
  final Duration remainingTime;
  final Function(Duration) formatDuration;
  final Function(String) translate;
  final Widget weatherHeader;
  final Widget countdown;
  final Widget boxGrid;

  const DaireselLayout({
    super.key,
    required this.timeProgress,
    required this.siradakiVakit,
    required this.remainingTime,
    required this.formatDuration,
    required this.translate,
    required this.weatherHeader,
    required this.countdown,
    required this.boxGrid,
  });

  @override
  Widget build(BuildContext context) {
    Color accentColor = AppTheme.primaryColor;
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
                weatherHeader,
                const SizedBox(height: 40),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: CircularProgressIndicator(
                        value: timeProgress,
                        strokeWidth: 12,
                        backgroundColor: AppTheme.getDividerColor(context),
                        color: accentColor,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),
                        Text(translate(siradakiVakit),
                            style: TextStyle(
                                color: textColor,
                                fontSize: 26,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(translate("Vaktine"),
                            style: TextStyle(
                                color: AppTheme.getSubTextColor(context),
                                fontSize: 14)),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 40),
                countdown,
                const SizedBox(height: 40),
                boxGrid,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
