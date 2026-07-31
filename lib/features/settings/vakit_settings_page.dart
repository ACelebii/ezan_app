import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'settings_common.dart';
import '../hatirlaticilar/data/reminder_scheduler.dart';
import '../hatirlaticilar/data/reminder_sound.dart';

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
  final List<String> onceSureSecenekleri = [
    "15 Dakika Önce",
    "30 Dakika Önce",
    "45 Dakika Önce",
    "60 Dakika Önce",
    "75 Dakika Önce",
    "90 Dakika Önce",
  ];

  late final String vakitKey;
  late final String displayName;

  @override
  void initState() {
    super.initState();
    vakitKey = ReminderScheduler.vakitKeyFromLabel(widget.vakitAdi) ?? 'imsak';
    displayName = ReminderScheduler.vakitDisplayNames[vakitKey] ?? widget.vakitAdi;
  }

  void _guncelle(AuthService authService,
      Map<String, dynamic> Function(Map<String, dynamic> mevcut) degistir) {
    final guncelAyarlar =
        Map<String, dynamic>.from(authService.vakitEzanAyarlari);
    guncelAyarlar[vakitKey] =
        degistir(Map<String, dynamic>.from(guncelAyarlar[vakitKey] as Map));
    authService.updateSetting('vakit_ezan_ayarlari', guncelAyarlar);
    ReminderScheduler.rescheduleAll(authService);
  }

  List<bool> _gunlerOf(Map<String, dynamic> ayar) {
    final raw = ayar['gunler'] as List?;
    if (raw == null || raw.length != 7) return List.filled(7, true);
    return raw.map((e) => e == true).toList();
  }

  String kapaliGunlerText(AuthService authService, List<bool> gunler) {
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
    final ayar = Map<String, dynamic>.from(
        authService.vakitEzanAyarlari[vakitKey] as Map);
    final vakitDurumu = ayar['enabled'] == true;
    final vakitSesKey = (ayar['sound'] as String?) ?? 'ezan_kisa';
    final vaktindeOku = ayar['vaktindeOku'] == true;
    final onceDurumu = ayar['onceEnabled'] == true;
    final onceSesKey = (ayar['onceSound'] as String?) ?? 'uyari';
    final onceDakika = (ayar['onceDakika'] as int?) ?? 45;
    final onceSuresi = "$onceDakika Dakika Önce";
    final gunler = _gunlerOf(ayar);

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
                    fontSize: 20)),
            backgroundColor: getBgColor(context),
            centerTitle: true),
        body: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle(
                context,
                vakitKey == "imsak" || vakitKey == "sabah"
                    ? "Sabah Ezanı"
                    : "$displayName Ezanı"),
            _buildCard(context, children: [
              _buildSwitchTile(context, "Durumu", vakitDurumu,
                  (v) => _guncelle(authService, (m) => {...m, 'enabled': v})),
              if (vakitDurumu) ...[
                _buildDivider(context),
                _buildTile(context,
                    icon: CupertinoIcons.speaker_2,
                    title: "Ses",
                    trailingText:
                        ReminderSounds.byKey(vakitSesKey).displayName,
                    onTap: () async {
                  final secilenKey = await context.push<String>(
                      '/settings/ses-secimi',
                      extra: vakitSesKey);
                  if (secilenKey != null) {
                    _guncelle(authService, (m) => {...m, 'sound': secilenKey});
                  }
                }),
                _buildDivider(context),
                _buildSwitchTile(
                    context,
                    "$displayName vaktinde oku",
                    vaktindeOku,
                    (v) => _guncelle(
                        authService, (m) => {...m, 'vaktindeOku': v})),
              ]
            ]),
            if (vakitKey == "imsak" || vakitKey == "sabah")
              Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 20, left: 12),
                  child: Text(
                      authService.translate("Güneş Vaktinden 60 Dakika Önce"),
                      style: TextStyle(
                          color: getSubTextColor(context), fontSize: 13)))
            else
              const SizedBox(height: 20),
            _sectionTitle(context, "$displayName Vaktinden Önce Uyarı"),
            _buildCard(context, children: [
              _buildSwitchTile(
                  context,
                  "Durumu",
                  onceDurumu,
                  (v) => _guncelle(
                      authService, (m) => {...m, 'onceEnabled': v})),
              if (onceDurumu) ...[
                _buildDivider(context),
                _buildTile(context,
                    icon: CupertinoIcons.speaker_2,
                    title: "Ses",
                    trailingText: ReminderSounds.byKey(onceSesKey).displayName,
                    onTap: () async {
                  final secilenKey = await context.push<String>(
                      '/settings/ses-secimi',
                      extra: onceSesKey);
                  if (secilenKey != null) {
                    _guncelle(
                        authService, (m) => {...m, 'onceSound': secilenKey});
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
                    ]),
                    onTap: () => showSwiperPicker(
                        context,
                        authService.translate("Uyarı Süresi"),
                        onceSureSecenekleri,
                        onceSuresi, (secilen) {
                      final dakika =
                          int.parse(secilen.split(' ').first);
                      _guncelle(authService,
                          (m) => {...m, 'onceDakika': dakika});
                    })),
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
                      onTap: () => _guncelle(authService, (m) {
                        final yeniGunler = List<bool>.from(gunler);
                        yeniGunler[index] = !yeniGunler[index];
                        return {...m, 'gunler': yeniGunler};
                      }),
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
                child: Text(kapaliGunlerText(authService, gunler),
                    style: TextStyle(
                        color: getSubTextColor(context), fontSize: 13))),
          ],
        ),
      ),
    );
  }
}
