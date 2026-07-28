import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'settings_common.dart';

// ============================================================================
// VAKİT DETAY SAYFASI
// ============================================================================
class VakitSettingsPage extends StatefulWidget {
  final String vakitAdi;
  const VakitSettingsPage({super.key, required this.vakitAdi});
  @override
  State<VakitSettingsPage> createState() => _VakitSettingsPageState();
}

class _VakitSettingsPageState extends State<VakitSettingsPage> {
  bool vakitDurumu = true;
  String vakitSesi = "Ezan Sultanahmet";
  bool vaktindeOku = false;
  bool onceDurumu = false;
  String onceSesi = "Melodi 1";
  String onceSuresi = "45 Dakika Önce";

  List<bool> gunler = [true, true, false, true, true, false, true];
  final List<String> gunIsimleriKisa = [
    "Paz",
    "Pzt",
    "Sal",
    "Çar",
    "Per",
    "Cum",
    "Cmt"
  ];
  final List<String> gunIsimleriUzun = [
    "Pazar",
    "Pazartesi",
    "Salı",
    "Çarşamba",
    "Perşembe",
    "Cuma",
    "Cumartesi"
  ];

  String kapaliGunlerText(AuthService authService) {
    List<String> kapaliOlanlar = [];
    for (int i = 0; i < gunler.length; i++) {
      if (!gunler[i]) {
        kapaliOlanlar.add(authService.translate(gunIsimleriUzun[i]));
      }
    }
    if (kapaliOlanlar.isEmpty) return authService.translate("Tüm Günler Açık");
    if (kapaliOlanlar.length == 7) {
      return authService.translate("Tüm Günler Kapalı");
    }
    return "${kapaliOlanlar.join(", ")} ${authService.translate("Kapalı")}";
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final authService = context.watch<AuthService>();
    return Padding(
        padding: const EdgeInsets.only(left: 12, bottom: 8),
        child: Text(authService.translate(title),
            style: TextStyle(
                color: getSubTextColor(context),
                fontSize: 14,
                fontWeight: FontWeight.w500)));
  }

  Widget _buildCard(BuildContext context, {required List<Widget> children}) =>
      Container(
          decoration: BoxDecoration(
              color: getCardColor(context),
              borderRadius: BorderRadius.circular(16)),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children));
  Widget _buildDivider(BuildContext context) => Divider(
      color: getDividerColor(context), height: 1, indent: 16, endIndent: 16);

  Widget _buildTile(BuildContext context,
      {IconData? icon,
      required String title,
      String? trailingText,
      Widget? trailingWidget,
      VoidCallback? onTap}) {
    final authService = context.watch<AuthService>();
    final tTitle = authService.translate(title);
    final tTrailing =
        trailingText != null ? authService.translate(trailingText) : null;

    return InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(16),
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              if (icon != null) ...[
                Icon(icon, color: getSubTextColor(context), size: 22),
                const SizedBox(width: 14)
              ],
              Expanded(
                  child: Text(tTitle,
                      style: TextStyle(
                          color: getTextColor(context), fontSize: 16))),
              Row(mainAxisSize: MainAxisSize.min, children: [
                if (tTrailing != null)
                  Text(tTrailing,
                      style: TextStyle(
                          color: getSubTextColor(context), fontSize: 15)),
                if (trailingWidget != null) ...[
                  if (tTrailing != null) const SizedBox(width: 5),
                  trailingWidget
                ],
                if (onTap != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_ios,
                      color: isDark(context) ? Colors.white24 : Colors.black26,
                      size: 14)
                ]
              ])
            ])));
  }

  Widget _buildSwitchTile(BuildContext context, String title, bool value,
      Function(bool) onChanged) {
    final authService = context.watch<AuthService>();
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(authService.translate(title),
              style: TextStyle(color: getTextColor(context), fontSize: 16)),
          CupertinoSwitch(
              value: value,
              activeTrackColor: CupertinoColors.activeGreen,
              onChanged: onChanged)
        ]));
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    String safeTitle = widget.vakitAdi.replaceAll(" Vakti", "");

    return Directionality(
      textDirection: authService.uygulamaDili == "العربية"
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: getBgColor(context),
        appBar: AppBar(
            leading: buildBeautifulBackButton(context),
            title: Text(authService.translate(safeTitle),
                style: TextStyle(
                    color: getTextColor(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 20)),
            backgroundColor: getBgColor(context),
            centerTitle: true),
        body: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle(
                context,
                safeTitle == "İmsak" || safeTitle == "Sabah"
                    ? "Sabah Ezanı"
                    : "$safeTitle Ezanı"),
            _buildCard(context, children: [
              _buildSwitchTile(context, "Durumu", vakitDurumu,
                  (v) => setState(() => vakitDurumu = v)),
              if (vakitDurumu) ...[
                _buildDivider(context),
                _buildTile(context,
                    icon: CupertinoIcons.speaker_2,
                    title: "Ses",
                    trailingText: vakitSesi, onTap: () async {
                  final secilenSes = await context.push<String>(
                      '/settings/ses-secimi',
                      extra: vakitSesi);
                  if (secilenSes != null) {
                    setState(() => vakitSesi = secilenSes);
                  }
                }),
                _buildDivider(context),
                _buildSwitchTile(context, "$safeTitle vaktinde oku",
                    vaktindeOku, (v) => setState(() => vaktindeOku = v)),
              ]
            ]),
            if (safeTitle == "İmsak" || safeTitle == "Sabah")
              Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 20, left: 12),
                  child: Text(
                      authService.translate("Güneş Vaktinden 60 Dakika Önce"),
                      style: TextStyle(
                          color: getSubTextColor(context), fontSize: 13)))
            else
              const SizedBox(height: 20),
            _sectionTitle(context, "$safeTitle Vaktinden Önce Uyarı"),
            _buildCard(context, children: [
              _buildSwitchTile(context, "Durumu", onceDurumu,
                  (v) => setState(() => onceDurumu = v)),
              if (onceDurumu) ...[
                _buildDivider(context),
                _buildTile(context,
                    icon: CupertinoIcons.speaker_2,
                    title: "Ses",
                    trailingText: onceSesi, onTap: () async {
                  final secilenSes = await context.push<String>(
                      '/settings/ses-secimi',
                      extra: onceSesi);
                  if (secilenSes != null) {
                    setState(() => onceSesi = secilenSes);
                  }
                }),
                _buildDivider(context),
                _buildTile(context,
                    icon: CupertinoIcons.arrow_2_circlepath,
                    title: "Uyarı Süresi",
                    trailingWidget: Row(children: [
                      Text(authService.translate(onceSuresi),
                          style: TextStyle(
                              color: getSubTextColor(context), fontSize: 15)),
                      const SizedBox(width: 4),
                      Icon(Icons.unfold_more_rounded,
                          color: getSubTextColor(context), size: 18)
                    ])),
              ]
            ]),
            const SizedBox(height: 30),
            _sectionTitle(context, "Günler"),
            _buildCard(context, children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(7, (index) {
                    bool isActive = gunler[index];
                    return GestureDetector(
                      onTap: () =>
                          setState(() => gunler[index] = !gunler[index]),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                            color: isActive
                                ? (isDark(context)
                                    ? Colors.white24
                                    : Colors.black12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: isActive
                                    ? Colors.transparent
                                    : (isDark(context)
                                        ? Colors.white12
                                        : Colors.black12))),
                        child: Text(
                            authService.translate(gunIsimleriKisa[index]),
                            style: TextStyle(
                                color: isActive
                                    ? getTextColor(context)
                                    : getSubTextColor(context),
                                fontSize: 13,
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                      ),
                    );
                  }),
                ),
              ),
            ]),
            Padding(
                padding: const EdgeInsets.only(top: 8, left: 12),
                child: Text(kapaliGunlerText(authService),
                    style: TextStyle(
                        color: getSubTextColor(context), fontSize: 13))),
          ],
        ),
      ),
    );
  }
}

