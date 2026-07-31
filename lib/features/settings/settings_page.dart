import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../main.dart';
import '../../core/theme/app_theme.dart';
import 'settings_common.dart';
import '../hatirlaticilar/data/reminder_scheduler.dart';
import '../hatirlaticilar/data/reminder_sound.dart';

// ============================================================================
// 1. ANA AYARLAR SAYFASI
// ============================================================================
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _temkinlerExpanded = false;
  Map<String, dynamic>? _vakitZamanlari;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _vakitZamanlariniYukle());
  }

  Future<void> _vakitZamanlariniYukle() async {
    final authService = context.read<AuthService>();
    final city = authService.seciliSehir['isim'] as String? ?? 'İstanbul';
    final timings = await ReminderScheduler.timingsFor(authService, city);
    if (mounted && timings != null) {
      setState(() => _vakitZamanlari = timings);
    }
  }

  final List<String> hesaplamaSecenekleri = [
    "Diyanet Takvimi",
    "Kuzey Amerika (ISNA)",
    "Müslim World Lig",
    "Mısır",
    "Karaçi İslami İlimler Üniversitesi",
    "Ummül Kurra",
    "Tahran Üniversitesi",
    "ITNA Ashari, Caferi",
    "UOIF Fransa İslam Organizasyon Birliği",
    "Mısır (BIS)",
    "Temkinli Takvim",
    "JAKIM (Malezya)"
  ];
  final List<String> ikindiSecenekleri = [
    "Şafi, Maliki, Hanbeli, Türkiye",
    "Hanefi"
  ];
  final List<String> dilSecenekleri = [
    "Türkçe",
    "English",
    "العربية",
    "Deutsch",
    "Français"
  ];

  void _showGeceModuMenu() {
    final authService = context.read<AuthService>();
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Directionality(
        textDirection: authService.uygulamaDili == "العربية"
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: CupertinoActionSheet(
          title: Text(authService.translate('Gece Modu'),
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: getSubTextColor(context))),
          message: Text(
              authService.translate('Uygulama görünüm temasını seçin'),
              style: TextStyle(color: getSubTextColor(context))),
          actions: <CupertinoActionSheetAction>[
            CupertinoActionSheetAction(
              child: Text(authService.translate('Otomatik'),
                  style: TextStyle(
                      color: globalGeceModu == "Otomatik"
                          ? getAccentColor(context)
                          : getTextColor(context))),
              onPressed: () {
                setState(() => globalGeceModu = "Otomatik");
                themeNotifier.value = ThemeMode.system;
                Navigator.pop(context);
              },
            ),
            CupertinoActionSheetAction(
              child: Text(authService.translate('Açık (Karanlık Tema)'),
                  style: TextStyle(
                      color: globalGeceModu == "Açık"
                          ? getAccentColor(context)
                          : getTextColor(context))),
              onPressed: () {
                setState(() => globalGeceModu = "Açık");
                themeNotifier.value = ThemeMode.dark;
                Navigator.pop(context);
              },
            ),
            CupertinoActionSheetAction(
              child: Text(authService.translate('Kapalı (Aydınlık Tema)'),
                  style: TextStyle(
                      color: globalGeceModu == "Kapalı"
                          ? getAccentColor(context)
                          : getTextColor(context))),
              onPressed: () {
                setState(() => globalGeceModu = "Kapalı");
                themeNotifier.value = ThemeMode.light;
                Navigator.pop(context);
              },
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(context),
              child: Text(authService.translate('Vazgeç'),
                  style:
                      const TextStyle(color: CupertinoColors.destructiveRed))),
        ),
      ),
    );
  }

  void _showErteleMenu() async {
    final authService = context.read<AuthService>();
    final options = [
      "Kapalı",
      "1 saat",
      "2 saat",
      "4 saat",
      "8 saat",
      "1 Gün",
      "7 Gün",
      "10 Gün",
      "Tarih Seç"
    ];
    final value = await showDialog(
        context: context,
        builder: (context) => Directionality(
              textDirection: authService.uygulamaDili == "العربية"
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: Dialog(
                backgroundColor: getCardColor(context),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(authService.translate("Ertele"),
                          style: TextStyle(
                              color: getTextColor(context),
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ),
                    Divider(height: 1, color: getDividerColor(context)),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        children: options
                            .map((opt) => ListTile(
                                title: Center(
                                    child: Text(authService.translate(opt),
                                        style: TextStyle(
                                            color: opt == "Kapalı"
                                                ? Colors.redAccent
                                                : (opt ==
                                                        authService
                                                            .bildirimErteleDurumu
                                                    ? getAccentColor(context)
                                                    : getTextColor(context)),
                                            fontSize: 16,
                                            fontWeight: opt ==
                                                    authService
                                                        .bildirimErteleDurumu
                                                ? FontWeight.bold
                                                : FontWeight.normal))),
                                onTap: () => Navigator.pop(context, opt)))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ));
    if (value != null) {
      if (!mounted) return;
      if (value == "Tarih Seç") {
        final selectedDate = await context.push<String>('/settings/tarih-sec');
        if (selectedDate != null) {
          authService.updateSetting('bildirim_ertele', selectedDate);
        }
      } else {
        authService.updateSetting('bildirim_ertele', value);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final isUserLoggedIn = authService.user != null;
    final hesapBasligi = isUserLoggedIn ? authService.user!.email! : "Hesabım";
    final seciliSehirIsmi = authService.seciliSehir['isim'] ?? "Şehir Seçin";

    return Directionality(
      textDirection: authService.uygulamaDili == "العربية"
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppTheme.getBgColor(context),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: buildBeautifulBackButton(context),
          title: Text(authService.translate("Ayarlar"),
              style: TextStyle(
                  color: AppTheme.getTextColor(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          backgroundColor: AppTheme.getBgColor(context),
          centerTitle: true,
          elevation: 0,
        ),
        body: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          children: [
            Container(
              height: 170,
              margin: const EdgeInsets.only(bottom: 25),
              decoration: BoxDecoration(
                color: AppTheme.getCardColor(context),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8))
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  children: [
                    Positioned(
                        right: -20,
                        top: -20,
                        child: Icon(Icons.style_rounded,
                            size: 150,
                            color: AppTheme.getAccentColor(context)
                                .withValues(alpha: 0.05))),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                                color: AppTheme.getAccentColor(context),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color: AppTheme.getAccentColor(context)
                                          .withValues(alpha: 0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5))
                                ]),
                            child: Icon(Icons.check_rounded,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.black
                                    : Colors.white,
                                size: 32),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(authService.translate("AKTİF GÖRÜNÜM"),
                                    style: TextStyle(
                                        color: AppTheme.getAccentColor(context),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.2)),
                                const SizedBox(height: 4),
                                Text(
                                    authService
                                        .translate(authService.anaSayfaStili),
                                    style: TextStyle(
                                        color: AppTheme.getTextColor(context),
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 18),
                                Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white10
                                          : Colors.black12,
                                      borderRadius: BorderRadius.circular(10)),
                                  child: FractionallySizedBox(
                                      widthFactor: 0.8,
                                      child: Container(
                                          decoration: BoxDecoration(
                                              gradient: LinearGradient(colors: [
                                                AppTheme.getAccentColor(
                                                    context),
                                                Colors.orange.shade400
                                              ]),
                                              borderRadius:
                                                  BorderRadius.circular(10)))),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildCard(context, children: [
              _buildTile(context,
                  icon: Icons.location_on_rounded,
                  iconBgColor: Colors.blue,
                  title: "Şehirler",
                  trailingText: seciliSehirIsmi,
                  onTap: () => context.push('/settings/cities')),
              _buildDivider(context),
              _buildTile(context,
                  icon: Icons.mosque_rounded,
                  iconBgColor: Colors.purple,
                  title: "Hesaplama Yöntemi",
                  subtitle: authService.hesaplamaYontemi,
                  onTap: () => _showSelectionDialog(
                      "Hesaplama Yöntemi",
                      hesaplamaSecenekleri,
                      authService.hesaplamaYontemi,
                      (val) =>
                          authService.updateSetting('hesaplama_yontemi', val))),
              _buildDivider(context),
              _buildTile(context,
                  icon: CupertinoIcons.sun_haze_fill,
                  iconBgColor: Colors.orange,
                  title: "İkindi Hesabı",
                  subtitle: authService.ikindiHesabi,
                  onTap: () => _showSelectionDialog(
                      "İkindi Hesabı",
                      ikindiSecenekleri,
                      authService.ikindiHesabi,
                      (val) =>
                          authService.updateSetting('ikindi_hesabi', val))),
              _buildDivider(context),
              _buildTile(context,
                  icon: Icons.tune_rounded,
                  iconBgColor: Colors.redAccent,
                  title: "Temkinler",
                  subtitle: _temkinlerExpanded
                      ? null
                      : authService.temkinDegerleri.values.join(", "),
                  hideArrow: true,
                  onTap: () =>
                      setState(() => _temkinlerExpanded = !_temkinlerExpanded)),
              if (_temkinlerExpanded) _buildTemkinlerList(context),
            ]),
            const SizedBox(height: 25),
            _buildCard(context, children: [
              _buildTile(context,
                  icon: Icons.notifications_active_rounded,
                  iconBgColor: Colors.red,
                  title: "Hatırlatıcılar",
                  onTap: () => context.push('/settings/hatirlaticilar')),
              _buildDivider(context, indent: 50),
              _buildTile(context,
                  icon: Icons.snooze_rounded,
                  iconBgColor: Colors.teal,
                  title: "Bildirimleri Ertele",
                  trailingText: authService.bildirimErteleDurumu,
                  hideArrow: true,
                  onTap: _showErteleMenu),
              _buildDivider(context, indent: 50),
              _buildTile(context,
                  icon: Icons.access_time_filled_rounded,
                  iconBgColor: Colors.green,
                  title: "Vaktinde Kıl",
                  onTap: () => context.push('/settings/vaktinde-kil')),
              _buildDivider(context, indent: 50),
              _buildTile(context,
                  icon: Icons.settings_suggest_rounded,
                  iconBgColor: Colors.indigo,
                  title: "Bildirim İzinleri", onTap: () async {
                await openAppSettings();
              }),
            ]),
            const SizedBox(height: 30),
            _buildVakitAlarmSection(context, "imsak",
                Icons.nights_stay_rounded, Colors.indigoAccent),
            _buildVakitAlarmSection(context, "sabah",
                Icons.wb_twilight_rounded, Colors.orangeAccent),
            _buildVakitAlarmSection(
                context, "ogle", Icons.wb_sunny_rounded, getAccentColor(context)),
            _buildVakitAlarmSection(
                context, "ikindi", Icons.wb_twilight_rounded, Colors.amber),
            _buildVakitAlarmSection(context, "aksam",
                Icons.brightness_4_rounded, Colors.deepOrangeAccent),
            _buildVakitAlarmSection(context, "yatsi",
                Icons.brightness_2_rounded, Colors.lightBlueAccent),
            const SizedBox(height: 25),
            _buildCard(context, children: [
              _buildTile(context,
                  icon: Icons.language_rounded,
                  iconBgColor: Colors.cyan,
                  title: "Uygulama Dili",
                  trailingText: authService.uygulamaDili, onTap: () {
                showSwiperPicker(
                    context,
                    authService.translate("Uygulama Dili"),
                    dilSecenekleri,
                    authService.uygulamaDili, (val) {
                  authService.updateSetting('uygulama_dili', val);
                });
              }),
              _buildDivider(context, indent: 50),
              _buildTile(context,
                  icon: Icons.location_on_rounded,
                  iconBgColor: Colors.blue,
                  title: "Konum İzinleri", onTap: () async {
                await openAppSettings();
              }),
              _buildDivider(context, indent: 50),
              _buildTile(context,
                  icon: Icons.dark_mode_rounded,
                  iconBgColor: Colors.grey.shade800,
                  title: "Gece Modu",
                  trailingText:
                      authService.translate(globalGeceModu.split(" ")[0]),
                  onTap: _showGeceModuMenu),
              _buildDivider(context, indent: 50),
              _buildTile(context,
                  icon: Icons.bolt_rounded,
                  iconBgColor: Colors.deepOrange,
                  title: "Canlı Etkinlik",
                  trailingText: "Başlat",
                  hideArrow: true),
            ]),
            const SizedBox(height: 25),
            _buildCard(context, children: [
              _buildTile(context,
                  icon: Icons.palette_rounded,
                  iconBgColor: Colors.pinkAccent,
                  title: "Ana Sayfa Stili",
                  trailingText:
                      authService.translate(authService.anaSayfaStili),
                  onTap: () => context.push('/settings/theme')),
              _buildDivider(context, indent: 50),
              _buildTile(context,
                  icon: Icons.account_circle_rounded,
                  iconBgColor: isUserLoggedIn ? Colors.green : Colors.blueGrey,
                  title: hesapBasligi,
                  onTap: () => context.push('/settings/hesabim')),
            ]),
            const SizedBox(height: 30),
            _sectionTitle(context, "KUR'AN-I KERİM YAZI BOYUTU"),
            _buildCard(context, children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(authService.translate("Boyut Ayarla"),
                            style: TextStyle(
                                color: getTextColor(context), fontSize: 16)),
                        Text("${authService.kuranYaziBoyutu.toInt()} px",
                            style: TextStyle(
                                color: getSubTextColor(context), fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Slider(
                        value: authService.kuranYaziBoyutu,
                        min: 14,
                        max: 40,
                        activeColor: getAccentColor(context),
                        inactiveColor:
                            isDark(context) ? Colors.white24 : Colors.black12,
                        onChanged: (v) =>
                            authService.updateSetting('kuran_font_size', v)),
                    const SizedBox(height: 10),
                    Center(
                        child: Text("بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيمِ",
                            style: TextStyle(
                                color: getAccentColor(context),
                                fontSize: authService.kuranYaziBoyutu,
                                fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center)),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
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
  Widget _buildDivider(BuildContext context, {double indent = 50}) => Divider(
      color: getDividerColor(context),
      height: 1,
      indent: indent,
      endIndent: 16);

  Widget _buildTile(BuildContext context,
      {IconData? icon,
      Color? iconBgColor,
      required String title,
      String? titleSpan,
      String? subtitle,
      String? trailingText,
      Widget? trailingWidget,
      bool hideArrow = false,
      VoidCallback? onTap}) {
    final authService = context.watch<AuthService>();
    final tTitle = authService.translate(title);
    final tSubtitle = subtitle != null ? authService.translate(subtitle) : null;
    final tTrailing =
        trailingText != null ? authService.translate(trailingText) : null;

    return InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(16),
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              if (icon != null) ...[
                Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                        color: iconBgColor ?? Colors.grey,
                        borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, color: Colors.white, size: 20)),
                const SizedBox(width: 14)
              ],
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(children: [
                      Expanded(
                          child: Text(tTitle,
                              style: TextStyle(
                                  color: getTextColor(context), fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)),
                      if (titleSpan != null) ...[
                        const SizedBox(width: 8),
                        Text(authService.translate(titleSpan),
                            style: TextStyle(
                                color: getSubTextColor(context), fontSize: 14))
                      ]
                    ]),
                    if (tSubtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(tSubtitle,
                          style: TextStyle(
                              color: getSubTextColor(context), fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis)
                    ]
                  ])),
              Row(mainAxisSize: MainAxisSize.min, children: [
                if (tTrailing != null)
                  Container(
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.35),
                    child: Text(tTrailing,
                        style: TextStyle(
                            color: getSubTextColor(context), fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right),
                  ),
                if (trailingWidget != null) ...[
                  if (tTrailing != null) const SizedBox(width: 5),
                  trailingWidget
                ],
                if (!hideArrow) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_ios,
                      color: isDark(context) ? Colors.white24 : Colors.black26,
                      size: 14)
                ]
              ])
            ])));
  }

  void _showSelectionDialog(String title, List<String> options,
      String currentValue, Function(String) onSelected) {
    final authService = context.read<AuthService>();
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: authService.uygulamaDili == "العربية"
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: Dialog(
            backgroundColor: getCardColor(context),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  bool isSelected = options[index] == currentValue;
                  return ListTile(
                    leading: isSelected
                        ? Icon(Icons.check,
                            color: getAccentColor(context), size: 20)
                        : const SizedBox(width: 20),
                    title: Text(authService.translate(options[index]),
                        style: TextStyle(
                            color: isSelected
                                ? getAccentColor(context)
                                : getTextColor(context),
                            fontSize: 16)),
                    onTap: () {
                      onSelected(options[index]);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVakitAlarmSection(
      BuildContext context, String vakitKey, IconData icon, Color iconColor) {
    final authService = context.watch<AuthService>();
    final label = ReminderScheduler.vakitLabels[vakitKey]!;
    final displayName = ReminderScheduler.vakitDisplayNames[vakitKey]!;
    final ayar = Map<String, dynamic>.from(
        authService.vakitEzanAyarlari[vakitKey] as Map);
    final field = ReminderScheduler.vakitAladhanField[vakitKey]!;
    final rawSaat = _vakitZamanlari?[field] as String?;
    final saat = rawSaat != null ? rawSaat.split(' ').first : '--:--';

    final onceEnabled = ayar['onceEnabled'] == true;
    final onceDakika = (ayar['onceDakika'] as int?) ?? 45;
    final onceSound = ReminderSounds.byKey(
            (ayar['onceSound'] as String?) ?? 'uyari')
        .displayName;
    final enabled = ayar['enabled'] == true;
    final vakitSound = ReminderSounds.byKey(
            (ayar['sound'] as String?) ?? 'ezan_kisa')
        .displayName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, label),
        _buildCard(context, children: [
          _buildTile(context,
              icon: Icons.alarm,
              iconBgColor: Colors.redAccent,
              title: onceEnabled
                  ? "$onceDakika Dakika Önce"
                  : "Vaktinden Önce Uyarı Kapalı",
              trailingText: onceEnabled ? onceSound : null,
              onTap: () => context.push('/settings/vakit', extra: label)),
          _buildDivider(context, indent: 50),
          _buildTile(context,
              icon: icon,
              iconBgColor: iconColor,
              title: displayName,
              titleSpan: saat,
              trailingText: enabled ? vakitSound : "Kapalı",
              onTap: () => context.push('/settings/vakit', extra: label)),
        ]),
        const SizedBox(height: 20),
      ],
    );
  }

  void _updateTemkin(AuthService authService, String key, int value) {
    final guncel = Map<String, int>.from(authService.temkinDegerleri);
    guncel[key] = value;
    authService.updateSetting('temkinler', guncel);
  }

  Widget _buildTemkinlerList(BuildContext context) {
    final authService = context.watch<AuthService>();
    return Column(
      children: authService.temkinDegerleri.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(authService.translate(entry.key),
                      style: TextStyle(
                          color: getTextColor(context), fontSize: 14)),
                  Text("${entry.value} ${authService.translate("Dakika")}",
                      style: TextStyle(
                          color: getSubTextColor(context), fontSize: 12)),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                    color: isDark(context)
                        ? const Color(0xFF2C2C2E)
                        : const Color(0xFFE5E5EA),
                    borderRadius: BorderRadius.circular(6)),
                child: Row(
                  children: [
                    InkWell(
                        onTap: () => _updateTemkin(
                            authService, entry.key, entry.value - 1),
                        child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            child: Icon(Icons.remove,
                                color: getTextColor(context), size: 16))),
                    Container(
                        width: 1, height: 16, color: getDividerColor(context)),
                    InkWell(
                        onTap: () => _updateTemkin(
                            authService, entry.key, entry.value + 1),
                        child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            child: Icon(Icons.add,
                                color: getTextColor(context), size: 16))),
                  ],
                ),
              )
            ],
          ),
        );
      }).toList(),
    );
  }
}
