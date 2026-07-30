import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../auth/auth_service.dart';

export 'package:provider/provider.dart';
export '../auth/auth_service.dart';

// ============================================================================
// GLOBAL DEĞİŞKENLER VE TEMA YARDIMCILARI
// ============================================================================
String globalGeceModu = "Otomatik";

bool isDark(BuildContext context) {
  if (globalGeceModu == "Açık") return true;
  if (globalGeceModu == "Kapalı") return false;
  return MediaQuery.of(context).platformBrightness == Brightness.dark;
}

Color getBgColor(BuildContext context) =>
    isDark(context) ? Colors.black : const Color(0xFFF2F2F7);
Color getCardColor(BuildContext context) =>
    isDark(context) ? const Color(0xFF151517) : Colors.white;
Color getTextColor(BuildContext context) =>
    isDark(context) ? Colors.white : Colors.black87;
Color getSubTextColor(BuildContext context) =>
    isDark(context) ? Colors.white54 : Colors.black54;
Color getDividerColor(BuildContext context) => isDark(context)
    ? Colors.white.withValues(alpha: 0.05)
    : Colors.black.withValues(alpha: 0.08);
Color getAccentColor(BuildContext context) =>
    isDark(context) ? Colors.yellow : Colors.orange.shade700;
Color getTextFieldColor(BuildContext context) =>
    isDark(context) ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);

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
void showSwiperPicker(BuildContext context, String title,
    List<String> options, String currentValue, Function(String) onSelected) {
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
