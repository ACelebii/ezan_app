import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../core/vakit/zaman_dilimi.dart';
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
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    // Cihazın bulunduğu yer değil, seçili şehrin "bugün"ü: erteleme de o
    // şehrin saat dilimine göre hesaplanıyor (ertelemeBitisi).
    zamanDilimleriniHazirla();
    final authService = Provider.of<AuthService>(context, listen: false);
    _selectedDate = tz.TZDateTime.now(
        tz.getLocation(authService.seciliSehir.konum.saatDilimi));
  }

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
                firstDate: _selectedDate,
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

