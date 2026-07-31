import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'settings_common.dart';
import '../hatirlaticilar/data/reminder_scheduler.dart';
import '../hatirlaticilar/data/reminder_sound.dart';

class VaktindeKilDetayPage extends StatefulWidget {
  final String vakitKey;
  const VaktindeKilDetayPage({super.key, required this.vakitKey});
  @override
  State<VaktindeKilDetayPage> createState() => _VaktindeKilDetayPageState();
}

class _VaktindeKilDetayPageState extends State<VaktindeKilDetayPage> {
  final List<String> ilkUyariSecenekleri = [
    "10 Dakika",
    "20 Dakika",
    "30 Dakika",
    "40 Dakika",
    "50 Dakika"
  ];
  final List<String> siklikSecenekleri = [
    "5 Dakika",
    "10 Dakika",
    "15 Dakika",
    "20 Dakika"
  ];

  void _guncelle(AuthService authService,
      Map<String, dynamic> Function(Map<String, dynamic> mevcut) degistir) {
    final guncelAyarlar =
        Map<String, dynamic>.from(authService.vaktindeKilAyarlari);
    guncelAyarlar[widget.vakitKey] = degistir(
        Map<String, dynamic>.from(guncelAyarlar[widget.vakitKey] as Map));
    authService.updateSetting('vaktinde_kil_ayarlari', guncelAyarlar);
    ReminderScheduler.rescheduleAll(authService);
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final ayar = Map<String, dynamic>.from(
        authService.vaktindeKilAyarlari[widget.vakitKey] as Map);
    final ilkUyariDakika = (ayar['ilkUyariDakika'] as int?) ?? 30;
    final siklikDakika = (ayar['siklikDakika'] as int?) ?? 10;
    final sesKey = (ayar['sound'] as String?) ?? 'melodi_19';
    final displayName =
        ReminderScheduler.vakitDisplayNames[widget.vakitKey] ?? widget.vakitKey;

    return Directionality(
      textDirection: authService.uygulamaDili == "العربية"
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: getBgColor(context),
        appBar: AppBar(
          leading: buildBeautifulBackButton(context),
          title: Text(authService.translate(displayName),
              style: TextStyle(
                  color: getTextColor(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          backgroundColor: getBgColor(context),
          centerTitle: true,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              decoration: BoxDecoration(
                  color: getCardColor(context),
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _buildDetayRow(
                      "İlk Uyarı Gecikmesi", "$ilkUyariDakika Dakika", true,
                      onTap: () => showSwiperPicker(
                          context,
                          authService.translate("İlk Uyarı Gecikmesi"),
                          ilkUyariSecenekleri,
                          "$ilkUyariDakika Dakika",
                          (secilen) => _guncelle(
                              authService,
                              (m) => {
                                    ...m,
                                    'ilkUyariDakika':
                                        int.parse(secilen.split(' ').first)
                                  }))),
                  Divider(
                      color: getDividerColor(context), height: 1, indent: 16),
                  _buildDetayRow(
                      "Ses", ReminderSounds.byKey(sesKey).displayName, false,
                      onTap: () async {
                    final secilenKey = await context.push<String>(
                        '/settings/ses-secimi',
                        extra: sesKey);
                    if (secilenKey != null) {
                      _guncelle(
                          authService, (m) => {...m, 'sound': secilenKey});
                    }
                  }),
                  Divider(
                      color: getDividerColor(context), height: 1, indent: 16),
                  _buildDetayRow(
                      "Uyarı Sıklığı", "$siklikDakika Dakika", true,
                      onTap: () => showSwiperPicker(
                          context,
                          authService.translate("Uyarı Sıklığı"),
                          siklikSecenekleri,
                          "$siklikDakika Dakika",
                          (secilen) => _guncelle(
                              authService,
                              (m) => {
                                    ...m,
                                    'siklikDakika':
                                        int.parse(secilen.split(' ').first)
                                  }))),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDetayRow(String title, String value, bool isSelector,
      {VoidCallback? onTap}) {
    final authService = context.watch<AuthService>();
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(authService.translate(title),
                style: TextStyle(color: getTextColor(context), fontSize: 16)),
            Row(
              children: [
                Text(authService.translate(value),
                    style: TextStyle(
                        color: getSubTextColor(context), fontSize: 15)),
                const SizedBox(width: 8),
                Icon(
                    isSelector
                        ? Icons.unfold_more_rounded
                        : Icons.arrow_forward_ios,
                    color: isDark(context) ? Colors.white54 : Colors.black45,
                    size: isSelector ? 20 : 14)
              ],
            )
          ],
        ),
      ),
    );
  }
}
