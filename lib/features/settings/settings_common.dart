import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_service.dart';

export 'package:provider/provider.dart';
export '../auth/auth_service.dart';

// ============================================================================
// TEMA YARDIMCILARI
// ============================================================================
// Tek kaynak `AppTheme` (Theme.of(context)). Bu adlar, onları çağıran yüzlerce
// yer değişmesin diye korundu; hepsi AppTheme'e yönlenir.

/// Gece modu seçiminin adı (Otomatik / Açık / Kapalı); yalnızca okunur, seçimi
/// `AppTheme.mod` tutar.
String get globalGeceModu => switch (AppTheme.mod.value) {
      ThemeMode.dark => "Açık",
      ThemeMode.light => "Kapalı",
      ThemeMode.system => "Otomatik",
    };

bool isDark(BuildContext context) => AppTheme.isDark(context);
Color getBgColor(BuildContext context) => AppTheme.getBgColor(context);
Color getCardColor(BuildContext context) => AppTheme.getCardColor(context);
Color getTextColor(BuildContext context) => AppTheme.getTextColor(context);
Color getSubTextColor(BuildContext context) =>
    AppTheme.getSubTextColor(context);
Color getDividerColor(BuildContext context) =>
    AppTheme.getDividerColor(context);
Color getAccentColor(BuildContext context) => AppTheme.getAccentColor(context);
Color getTextFieldColor(BuildContext context) =>
    AppTheme.getTextFieldColor(context);

// Ozel Tasarim Geri Butonu
Widget buildBeautifulBackButton(BuildContext context,
    {VoidCallback? onPressed}) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: InkWell(
      onTap: onPressed ?? () => context.pop(),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isDark(context)
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDark(context) ? Colors.white24 : Colors.black12),
        ),
        child: Icon(Icons.arrow_back_ios_new_rounded,
            color: getTextColor(context), size: 18),
      ),
    ),
  );
}

// ============================================================================
// ORTAK SWIPER MOTORU
// ============================================================================
void showSwiperPicker(BuildContext context, String title, List<String> options,
    String currentValue, Function(String) onSelected) {
  int selectedIndex = options.indexOf(currentValue);
  if (selectedIndex == -1) selectedIndex = 0;
  final authService = context.read<AuthService>();

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Directionality(
      textDirection: authService.uygulamaDili == "العربية"
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Container(
        height: 320,
        decoration: BoxDecoration(
          color: isDark(context) ? const Color(0xFF1E2124) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(authService.translate("İptal"),
                        style: TextStyle(
                            color: getSubTextColor(context), fontSize: 16)),
                  ),
                  Expanded(
                    child: Text(authService.translate(title),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: getTextColor(context),
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),
                  TextButton(
                    onPressed: () {
                      onSelected(options[selectedIndex]);
                      Navigator.pop(context);
                    },
                    child: Text(authService.translate("Bitti"),
                        style: TextStyle(
                            color: getAccentColor(context),
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: getDividerColor(context)),
            Expanded(
              child: CupertinoPicker(
                scrollController:
                    FixedExtentScrollController(initialItem: selectedIndex),
                itemExtent: 45,
                onSelectedItemChanged: (index) {
                  selectedIndex = index;
                },
                children: options
                    .map((opt) => Center(
                        child: Text(authService.translate(opt),
                            style: TextStyle(
                                color: getTextColor(context), fontSize: 20))))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
