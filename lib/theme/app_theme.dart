import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Colors.teal;
  static const Color accentColor = Colors.orange;

  // Text Styles
  static const TextStyle titleStyle =
      TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
  static const TextStyle headerStyle =
      TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5);
  static const TextStyle subtitleStyle =
      TextStyle(fontSize: 14, color: Colors.grey);

  // Helper functions
  static Color getBgColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : const Color(0xFFF2F2F7);
  static Color getCardColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF151517)
          : Colors.white;
  static Color getTextColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : Colors.black87;
  static Color getSubTextColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white54
          : Colors.black54;
  static Color getDividerColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.08);
  static Color getAccentColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.yellow
          : Colors.orange.shade700;

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: const Color(0xFFF2F2F7),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF031F1F),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  );
}
