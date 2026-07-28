import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'settings_common.dart';

class VaktindeKilPage extends StatefulWidget {
  const VaktindeKilPage({super.key});
  @override
  State<VaktindeKilPage> createState() => _VaktindeKilPageState();
}

class _VaktindeKilPageState extends State<VaktindeKilPage> {
  Map<String, bool> namazDurumlari = {
    'Öğle': true,
    'İkindi': true,
    'Akşam': true,
    'Yatsı': true
  };

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
          title: Text(authService.translate("Vaktinde Kıl"),
              style: TextStyle(
                  color: getTextColor(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          backgroundColor: getBgColor(context),
          centerTitle: true,
          elevation: 0,
        ),
        body: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              decoration: BoxDecoration(
                  color: getCardColor(context),
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_off_rounded,
                            color: Colors.redAccent, size: 24),
                        const SizedBox(width: 14),
                        Expanded(
                            child: Text(
                                authService.translate("Sabah Ezanı [Kapalı]"),
                                style: const TextStyle(
                                    color: Colors.redAccent, fontSize: 16))),
                        Icon(Icons.error_outline_rounded,
                            color: Colors.redAccent.withValues(alpha: 0.7),
                            size: 20),
                      ],
                    ),
                  ),
                  Divider(
                      color: getDividerColor(context), height: 1, indent: 50),
                  _buildNamazRow("Öğle", Icons.wb_sunny_rounded, Colors.orange),
                  Divider(
                      color: getDividerColor(context), height: 1, indent: 50),
                  _buildNamazRow(
                      "İkindi", Icons.wb_twilight_rounded, Colors.amber),
                  Divider(
                      color: getDividerColor(context), height: 1, indent: 50),
                  _buildNamazRow("Akşam", Icons.brightness_4_rounded,
                      Colors.deepOrangeAccent),
                  Divider(
                      color: getDividerColor(context), height: 1, indent: 50),
                  _buildNamazRow("Yatsı", Icons.brightness_2_rounded,
                      Colors.lightBlueAccent),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                authService.translate(
                    "Namazların geciktirilmeden kılınması için; ilk uyarı gecikme süresinden sonra uyan sıklığına göre 2 defa hatırlatma yapan bir özelliktir. 'Haydi kalk! Vakit girdi, Namazını kıl' diyen hayırlı bir arkadaş gibidir."),
                style: TextStyle(
                    color: getSubTextColor(context), fontSize: 13, height: 1.4),
                textAlign: TextAlign.justify,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNamazRow(String title, IconData icon, Color iconColor) {
    bool isOn = namazDurumlari[title]!;
    final authService = context.watch<AuthService>();
    return InkWell(
      onTap: () {
        if (isOn) {
          context.push('/settings/vaktinde-kil/detay', extra: title);
        } else {
          setState(() => namazDurumlari[title] = true);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
                child: Text(authService.translate(title),
                    style:
                        TextStyle(color: getTextColor(context), fontSize: 16))),
            CupertinoSwitch(
                value: isOn,
                activeTrackColor: CupertinoColors.activeGreen,
                onChanged: (v) => setState(() => namazDurumlari[title] = v)),
            if (isOn) ...[
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios,
                  color: isDark(context) ? Colors.white24 : Colors.black26,
                  size: 14)
            ] else
              const SizedBox(width: 22)
          ],
        ),
      ),
    );
  }
}

