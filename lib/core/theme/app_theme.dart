import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  static const Color primaryColor = Colors.teal;
  static const Color accentColor = Colors.orange;

  /// Uygulamanın yazı tipi (`assets/fonts/`, değişken ağırlıklı). Latin ve
  /// Türkçe harfleri kapsar, Arapça'yı kapsamaz: Arapça metin (Kur'an, Arapça
  /// arayüz) sistemin Arapça yazı tipiyle çizilmeye devam eder. `FontWeight`
  /// yazı tipinin ağırlık eksenine doğrudan uygulanır (testle ölçüldü).
  static const String fontFamily = 'Manrope';

  // Text Styles
  static const TextStyle titleStyle =
      TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
  static const TextStyle headerStyle =
      TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5);
  static const TextStyle subtitleStyle =
      TextStyle(fontSize: 14, color: Colors.grey);

  /// Gece/gündüz seçimi (Ayarlar > Gece Modu). Tek kaynak: `MaterialApp`in
  /// `themeMode`u ve aşağıdaki bütün renk yardımcıları buradan (Theme'den) okur.
  static final ValueNotifier<ThemeMode> mod = ValueNotifier(ThemeMode.system);

  static const _modAnahtari = 'gece_modu';
  static VoidCallback? _modDinleyici;

  /// Kayıtlı gece/gündüz seçimini yükler ve bundan sonraki her değişikliği
  /// telefona (SharedPreferences) yazar. `runApp`ten önce bir kez çağrılır;
  /// ilk kare doğru temayla açılır. Kayıt yoksa ya da bozuksa Otomatik.
  static Future<void> modYukle() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      mod.value = ThemeMode.values.asNameMap()[prefs.getString(_modAnahtari)] ??
          ThemeMode.system;
      if (_modDinleyici != null) mod.removeListener(_modDinleyici!);
      _modDinleyici = () => prefs.setString(_modAnahtari, mod.value.name);
      mod.addListener(_modDinleyici!);
    } catch (e) {
      debugPrint('Gece modu kaydı okunamadı: $e'); // Otomatik ile devam
    }
  }

  // Helper functions
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
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
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.08);
  static Color getAccentColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.yellow
          : Colors.orange.shade700;

  static Color getTextFieldColor(BuildContext context) =>
      isDark(context) ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    fontFamily: fontFamily,
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
    fontFamily: fontFamily,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF031F1F),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  );
}
