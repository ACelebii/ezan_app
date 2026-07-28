import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'settings_common.dart';

// ============================================================================
// DİĞER ALT SAYFALAR (TarihSec, VaktindeKil vb.)
// ============================================================================
class TarihSecPage extends StatefulWidget {
  const TarihSecPage({super.key});
  @override
  State<TarihSecPage> createState() => _TarihSecPageState();
}

class _TarihSecPageState extends State<TarihSecPage> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    return Directionality(
      textDirection: authService.uygulamaDili == "العربية"
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: getBgColor(context),
        appBar: AppBar(
          leading: buildBeautifulBackButton(context),
          title: Text(authService.translate("Tarih Seç"),
              style: TextStyle(
                  color: getTextColor(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          backgroundColor: getBgColor(context),
          centerTitle: true,
          elevation: 0,
          actions: [
            TextButton(
                onPressed: () {
                  String formatted =
                      "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}";
                  context.pop(formatted);
                },
                child: Text(authService.translate("Bitti"),
                    style: TextStyle(
                        color: getAccentColor(context),
                        fontSize: 16,
                        fontWeight: FontWeight.bold)))
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
                color: getCardColor(context),
                borderRadius: BorderRadius.circular(16)),
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: isDark(context)
                    ? ColorScheme.dark(
                        primary: getAccentColor(context),
                        surface: getCardColor(context))
                    : ColorScheme.light(primary: getAccentColor(context)),
              ),
              child: CalendarDatePicker(
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime(2030),
                onDateChanged: (date) => setState(() => _selectedDate = date),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

