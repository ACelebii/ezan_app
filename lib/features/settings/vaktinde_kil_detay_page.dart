import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'settings_common.dart';

class VaktindeKilDetayPage extends StatefulWidget {
  final String vakitAdi;
  const VaktindeKilDetayPage({super.key, required this.vakitAdi});
  @override
  State<VaktindeKilDetayPage> createState() => _VaktindeKilDetayPageState();
}

class _VaktindeKilDetayPageState extends State<VaktindeKilDetayPage> {
  String ilkUyari = "30 Dakika";
  String ses = "Melodi 19";
  String siklik = "10 Dakika";

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
          title: Text(authService.translate(widget.vakitAdi),
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
                  _buildDetayRow("İlk Uyarı Gecikmesi", ilkUyari, true,
                      onTap: () => showSwiperPicker(
                          context,
                          authService.translate("İlk Uyarı Gecikmesi"),
                          [
                            "10 Dakika",
                            "20 Dakika",
                            "30 Dakika",
                            "40 Dakika",
                            "50 Dakika"
                          ],
                          ilkUyari,
                          (v) => setState(() => ilkUyari = v))),
                  Divider(
                      color: getDividerColor(context), height: 1, indent: 16),
                  _buildDetayRow("Ses", ses, false, onTap: () async {
                    final secilen = await context.push<String>(
                        '/settings/ses-secimi',
                        extra: ses);
                    if (secilen != null) setState(() => ses = secilen);
                  }),
                  Divider(
                      color: getDividerColor(context), height: 1, indent: 16),
                  _buildDetayRow("Uyarı Sıklığı", siklik, true,
                      onTap: () => showSwiperPicker(
                          context,
                          authService.translate("Uyarı Sıklığı"),
                          ["5 Dakika", "10 Dakika", "15 Dakika", "20 Dakika"],
                          siklik,
                          (v) => setState(() => siklik = v))),
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

