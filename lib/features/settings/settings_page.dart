import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../main.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_service.dart';
import 'theme_selector_page.dart';

// ============================================================================
// GLOBAL DEĞİŞKENLER VE TEMA YARDIMCILARI
// ============================================================================
final Set<String> globalIndirilenSesler = {
  "Melodi 1",
  "Melodi 3",
  "Ezan Sultanahmet"
};
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
    ? Colors.white.withOpacity(0.05)
    : Colors.black.withOpacity(0.08);
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
      onTap: onPressed ?? () => Navigator.pop(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isDark(context)
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
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
void _showSwiperPicker(BuildContext context, String title, List<String> options,
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

// ============================================================================
// 1. ANA AYARLAR SAYFASI
// ============================================================================
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double fontSize = 24.0;
  bool _temkinlerExpanded = false;
  String _erteleDurumu = "Kapalı";

  final Map<String, int> _temkinDegerleri = {
    "İmsak": 0,
    "Güneş": -7,
    "Öğle": 5,
    "İkindi": 4,
    "Akşam": 7,
    "Yatsı": 0
  };

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

  void _showErteleMenu() {
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
    showDialog(
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
                                                : (opt == _erteleDurumu
                                                    ? getAccentColor(context)
                                                    : getTextColor(context)),
                                            fontSize: 16,
                                            fontWeight: opt == _erteleDurumu
                                                ? FontWeight.bold
                                                : FontWeight.normal))),
                                onTap: () => Navigator.pop(context, opt)))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            )).then((value) {
      if (value != null) {
        if (value == "Tarih Seç") {
          Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const TarihSecPage()))
              .then((selectedDate) {
            if (selectedDate != null)
              setState(() => _erteleDurumu = selectedDate);
          });
        } else {
          setState(() => _erteleDurumu = value);
        }
      }
    });
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
                      color: Colors.black.withOpacity(0.06),
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
                                .withOpacity(0.05))),
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
                                          .withOpacity(0.3),
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
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CitiesPage()))),
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
                      : _temkinDegerleri.values.join(", "),
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
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HatirlaticilarPage()))),
              _buildDivider(context, indent: 50),
              _buildTile(context,
                  icon: Icons.snooze_rounded,
                  iconBgColor: Colors.teal,
                  title: "Bildirimleri Ertele",
                  trailingText: _erteleDurumu,
                  hideArrow: true,
                  onTap: _showErteleMenu),
              _buildDivider(context, indent: 50),
              _buildTile(context,
                  icon: Icons.access_time_filled_rounded,
                  iconBgColor: Colors.green,
                  title: "Vaktinde Kıl",
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const VaktindeKilPage()))),
              _buildDivider(context, indent: 50),
              _buildTile(context,
                  icon: Icons.settings_suggest_rounded,
                  iconBgColor: Colors.indigo,
                  title: "Bildirim İzinleri", onTap: () async {
                await openAppSettings();
              }),
            ]),
            const SizedBox(height: 30),
            _buildVakitAlarmSection(context, "İmsak Vakti", "05:26",
                Icons.nights_stay_rounded, Colors.indigoAccent),
            _buildVakitAlarmSection(context, "Sabah Ezanı", "06:52",
                Icons.wb_twilight_rounded, Colors.orangeAccent,
                isSabahEzani: true),
            _buildVakitAlarmSection(context, "Öğle Vakti", "13:15",
                Icons.wb_sunny_rounded, getAccentColor(context)),
            _buildVakitAlarmSection(context, "İkindi Vakti", "16:43",
                Icons.wb_twilight_rounded, Colors.amber),
            _buildVakitAlarmSection(context, "Akşam Vakti", "19:28",
                Icons.brightness_4_rounded, Colors.deepOrangeAccent),
            _buildVakitAlarmSection(context, "Yatsı Vakti", "20:48",
                Icons.brightness_2_rounded, Colors.lightBlueAccent),
            const SizedBox(height: 25),
            _buildCard(context, children: [
              _buildTile(context,
                  icon: Icons.language_rounded,
                  iconBgColor: Colors.cyan,
                  title: "Uygulama Dili",
                  trailingText: authService.uygulamaDili, onTap: () {
                _showSwiperPicker(
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
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ThemeSelectorPage()))),
              _buildDivider(context, indent: 50),
              _buildTile(context,
                  icon: Icons.account_circle_rounded,
                  iconBgColor: isUserLoggedIn ? Colors.green : Colors.blueGrey,
                  title: hesapBasligi,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HesabimLoginPage()))),
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
                        Text("${fontSize.toInt()} px",
                            style: TextStyle(
                                color: getSubTextColor(context), fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Slider(
                        value: fontSize,
                        min: 14,
                        max: 40,
                        activeColor: getAccentColor(context),
                        inactiveColor:
                            isDark(context) ? Colors.white24 : Colors.black12,
                        onChanged: (v) => setState(() => fontSize = v)),
                    const SizedBox(height: 10),
                    Center(
                        child: Text("بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيمِ",
                            style: TextStyle(
                                color: getAccentColor(context),
                                fontSize: fontSize,
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

  Widget _buildVakitAlarmSection(BuildContext context, String vakitAdi,
      String saat, IconData icon, Color iconColor,
      {bool isSabahEzani = false}) {
    final authService = context.watch<AuthService>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, vakitAdi),
        _buildCard(context, children: [
          _buildTile(context,
              icon: Icons.alarm,
              iconBgColor: Colors.redAccent,
              title: "45 Dakika Önce",
              trailingText: "Melodi 1",
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          VakitSettingsPage(vakitAdi: vakitAdi)))),
          _buildDivider(context, indent: 50),
          _buildTile(context,
              icon: icon,
              iconBgColor: iconColor,
              title: isSabahEzani ? "Sabah Ezanı" : vakitAdi,
              titleSpan: isSabahEzani ? null : saat,
              trailingText: isSabahEzani ? "Essalatu Hayrun" : "Melodi 3",
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          VakitSettingsPage(vakitAdi: vakitAdi)))),
        ]),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTemkinlerList(BuildContext context) {
    final authService = context.watch<AuthService>();
    return Column(
      children: _temkinDegerleri.entries.map((entry) {
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
                        onTap: () => setState(() =>
                            _temkinDegerleri[entry.key] = entry.value - 1),
                        child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            child: Icon(Icons.remove,
                                color: getTextColor(context), size: 16))),
                    Container(
                        width: 1, height: 16, color: getDividerColor(context)),
                    InkWell(
                        onTap: () => setState(() =>
                            _temkinDegerleri[entry.key] = entry.value + 1),
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
      if (!gunler[i])
        kapaliOlanlar.add(authService.translate(gunIsimleriUzun[i]));
    }
    if (kapaliOlanlar.isEmpty) return authService.translate("Tüm Günler Açık");
    if (kapaliOlanlar.length == 7)
      return authService.translate("Tüm Günler Kapalı");
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
                  final secilenSes = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              SoundSelectionPage(mevcutSes: vakitSesi)));
                  if (secilenSes != null)
                    setState(() => vakitSesi = secilenSes);
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
                  final secilenSes = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              SoundSelectionPage(mevcutSes: onceSesi)));
                  if (secilenSes != null) setState(() => onceSesi = secilenSes);
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
                  Navigator.pop(context, formatted);
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
                            color: Colors.redAccent.withOpacity(0.7), size: 20),
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
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => VaktindeKilDetayPage(vakitAdi: title)));
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
                      onTap: () => _showSwiperPicker(
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
                    final secilen = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                SoundSelectionPage(mevcutSes: ses)));
                    if (secilen != null) setState(() => ses = secilen);
                  }),
                  Divider(
                      color: getDividerColor(context), height: 1, indent: 16),
                  _buildDetayRow("Uyarı Sıklığı", siklik, true,
                      onTap: () => _showSwiperPicker(
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

class HatirlaticilarPage extends StatefulWidget {
  const HatirlaticilarPage({super.key});
  @override
  State<HatirlaticilarPage> createState() => _HatirlaticilarPageState();
}

class _HatirlaticilarPageState extends State<HatirlaticilarPage> {
  bool cumaOn = true;
  String cumaSure = "60 Dakika Önce";
  String cumaSes = "Sela";

  bool orucOn = true;
  String orucSure = "60 Dakika Önce";
  String orucSes = "Melodi 1";

  bool teheccutOn = false;
  String teheccutSure = "45 Dakika Önce";
  String teheccutSes = "Melodi 3";

  bool ramazanOn = false;
  String ramazanSure = "60 Dakika Önce";
  String ramazanSes = "Melodi 19";

  List<String> get _timeOptions =>
      List.generate(14, (i) => "${(i + 1) * 5} Dakika Önce");

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
          title: Text(authService.translate("Hatırlatıcılar"),
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
            _buildHatirlaticiCard(
                "Cuma Namazı Hatırlatma",
                "Cumadan",
                cumaOn,
                (v) => setState(() => cumaOn = v),
                cumaSure,
                (s) => setState(() => cumaSure = s),
                cumaSes,
                (s) => setState(() => cumaSes = s)),
            const SizedBox(height: 20),
            _buildHatirlaticiCard(
                "Pazartesi/Perşembe Orucu",
                "İmsaktan",
                orucOn,
                (v) => setState(() => orucOn = v),
                orucSure,
                (s) => setState(() => orucSure = s),
                orucSes,
                (s) => setState(() => orucSes = s)),
            const SizedBox(height: 20),
            _buildHatirlaticiCard(
                "Teheccüt Uyandırması",
                "İmsaktan",
                teheccutOn,
                (v) => setState(() => teheccutOn = v),
                teheccutSure,
                (s) => setState(() => teheccutSure = s),
                teheccutSes,
                (s) => setState(() => teheccutSes = s)),
            const SizedBox(height: 20),
            _buildHatirlaticiCard(
                "Ramazan Davulcusu",
                "İmsaktan",
                ramazanOn,
                (v) => setState(() => ramazanOn = v),
                ramazanSure,
                (s) => setState(() => ramazanSure = s),
                ramazanSes,
                (s) => setState(() => ramazanSes = s)),
          ],
        ),
      ),
    );
  }

  Widget _buildHatirlaticiCard(
      String title,
      String offsetLabel,
      bool isOn,
      Function(bool) onSwitch,
      String timeVal,
      Function(String) onTimeSelect,
      String soundVal,
      Function(String) onSoundSelect) {
    final authService = context.watch<AuthService>();
    return Container(
      decoration: BoxDecoration(
          color: getCardColor(context),
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    child: Text(authService.translate(title),
                        style: TextStyle(
                            color: getTextColor(context),
                            fontSize: 16,
                            fontWeight: FontWeight.w500))),
                CupertinoSwitch(
                    value: isOn,
                    activeTrackColor: CupertinoColors.activeGreen,
                    onChanged: onSwitch),
              ],
            ),
          ),
          if (isOn) ...[
            Divider(color: getDividerColor(context), height: 1, indent: 16),
            InkWell(
              onTap: () => _showSwiperPicker(
                  context,
                  authService.translate(title),
                  _timeOptions,
                  timeVal,
                  onTimeSelect),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(authService.translate(offsetLabel),
                        style: TextStyle(
                            color: getTextColor(context), fontSize: 15)),
                    Row(
                      children: [
                        Text(authService.translate(timeVal),
                            style: TextStyle(
                                color: getSubTextColor(context), fontSize: 15)),
                        const SizedBox(width: 8),
                        Icon(Icons.unfold_more_rounded,
                            color: isDark(context)
                                ? Colors.white54
                                : Colors.black45,
                            size: 20)
                      ],
                    )
                  ],
                ),
              ),
            ),
            Divider(color: getDividerColor(context), height: 1, indent: 16),
            InkWell(
              onTap: () async {
                final secilen = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            SoundSelectionPage(mevcutSes: soundVal)));
                if (secilen != null) onSoundSelect(secilen);
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(authService.translate("Ses"),
                        style: TextStyle(
                            color: getTextColor(context), fontSize: 15)),
                    Row(
                      children: [
                        Text(authService.translate(soundVal),
                            style: TextStyle(
                                color: getSubTextColor(context), fontSize: 15)),
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward_ios,
                            color: isDark(context)
                                ? Colors.white24
                                : Colors.black26,
                            size: 14)
                      ],
                    )
                  ],
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}

class SoundSelectionPage extends StatefulWidget {
  final String mevcutSes;
  const SoundSelectionPage({super.key, required this.mevcutSes});
  @override
  State<SoundSelectionPage> createState() => _SoundSelectionPageState();
}

class _SoundSelectionPageState extends State<SoundSelectionPage> {
  final List<String> sesler = [
    "Sela",
    "Melodi 1",
    "Melodi 2",
    "Melodi 3",
    "Melodi 4",
    "Melodi 19",
    "Ding Dong",
    "Beep",
    "Kuş Sesi 1",
    "Kısa Ezan 1",
    "Kısa Ezan 2",
    "Kısa Ezan 3",
    "Ezan Sultanahmet",
    "Ezan Mekke"
  ];
  Set<String> indirilenYapanlar = {};
  final AudioPlayer _audioPlayer = AudioPlayer();
  late String _seciliSes;

  @override
  void initState() {
    super.initState();
    _seciliSes = widget.mevcutSes;
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _geriDon() {
    _audioPlayer.stop();
    Navigator.pop(context, _seciliSes);
  }

  String _getAudioUrl(String sesAdi) {
    if (sesAdi.contains("Melodi"))
      return "https://cdn.islamic.network/quran/audio/128/ar.alafasy/1.mp3";
    if (sesAdi.contains("Sela"))
      return "https://cdn.islamic.network/quran/audio/128/ar.husary/2.mp3";
    if (sesAdi.contains("Ezan"))
      return "https://cdn.islamic.network/quran/audio/128/ar.husary/1.mp3";
    return "https://cdn.islamic.network/quran/audio/128/ar.alafasy/1.mp3";
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _geriDon();
      },
      child: Directionality(
        textDirection: authService.uygulamaDili == "العربية"
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: getBgColor(context),
          appBar: AppBar(
            leading: buildBeautifulBackButton(context, onPressed: _geriDon),
            title: Text(authService.translate("Ses Seçimi"),
                style: TextStyle(
                    color: getTextColor(context),
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                      child: Text(
                          authService.translate("Varsayılan Sistem Sesi"),
                          style: TextStyle(
                              color: getSubTextColor(context), fontSize: 14)),
                    ),
                    Divider(color: getDividerColor(context), height: 1),
                    ...sesler.asMap().entries.map((entry) {
                      int idx = entry.key;
                      String ses = entry.value;
                      bool isSelected = ses == _seciliSes;
                      bool isDownloaded = globalIndirilenSesler.contains(ses);
                      bool isDownloading = indirilenYapanlar.contains(ses);

                      return Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            leading: Icon(Icons.play_arrow,
                                color: getTextColor(context)),
                            title: Text(ses,
                                style: TextStyle(
                                    color: getTextColor(context),
                                    fontSize: 16)),
                            trailing: isSelected
                                ? Icon(Icons.check,
                                    color: getAccentColor(context))
                                : isDownloading
                                    ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                            color: getAccentColor(context),
                                            strokeWidth: 2))
                                    : !isDownloaded
                                        ? IconButton(
                                            icon: Icon(
                                                Icons.cloud_download_outlined,
                                                color:
                                                    getSubTextColor(context)),
                                            onPressed: () {
                                              setState(() =>
                                                  indirilenYapanlar.add(ses));
                                              Future.delayed(
                                                  const Duration(seconds: 2),
                                                  () {
                                                if (mounted) {
                                                  setState(() {
                                                    indirilenYapanlar
                                                        .remove(ses);
                                                    globalIndirilenSesler
                                                        .add(ses);
                                                  });
                                                }
                                              });
                                            },
                                          )
                                        : null,
                            onTap: () async {
                              if (isDownloaded) {
                                setState(() => _seciliSes = ses);
                                await _audioPlayer.stop();
                                String sesUrL = _getAudioUrl(ses);
                                await _audioPlayer.play(UrlSource(sesUrL));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(authService.translate(
                                        'Sesi kullanmak için önce indirmelisiniz.'))));
                              }
                            },
                          ),
                          if (idx != sesler.length - 1)
                            Divider(
                                color: getDividerColor(context),
                                height: 1,
                                indent: 50,
                                endIndent: 16),
                        ],
                      );
                    }),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class HesabimLoginPage extends StatefulWidget {
  const HesabimLoginPage({super.key});
  @override
  State<HesabimLoginPage> createState() => _HesabimLoginPageState();
}

class _HesabimLoginPageState extends State<HesabimLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating));
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating));
  }

  bool _isEmailValid(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _validateLogin(String email, String password) {
    final authService = context.read<AuthService>();
    if (email.isEmpty || password.isEmpty) {
      _showError(authService.translate("Lütfen e-posta ve şifrenizi girin."));
      return false;
    }
    if (!_isEmailValid(email)) {
      _showError(
          authService.translate("Lütfen geçerli bir e-posta adresi girin."));
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final isUserLoggedIn = authService.user != null;
    Color fieldBgColor =
        isDark(context) ? const Color(0xFF1C1C1E) : Colors.grey.shade100;
    Color fieldBorderColor = isDark(context) ? Colors.white10 : Colors.black12;

    return Directionality(
      textDirection: authService.uygulamaDili == "العربية"
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: getBgColor(context),
        appBar: AppBar(
          leading: buildBeautifulBackButton(context),
          title: Text(
              authService.translate(isUserLoggedIn ? "Profilim" : "Hesabım"),
              style: TextStyle(
                  color: getTextColor(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          backgroundColor: getBgColor(context),
          centerTitle: true,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: isUserLoggedIn
              ? _buildLoggedInView(context, authService)
              : _buildLoginView(
                  context, authService, fieldBgColor, fieldBorderColor),
        ),
      ),
    );
  }

  Widget _buildLoggedInView(BuildContext context, AuthService authService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.greenAccent.withOpacity(0.1)),
            child: const Icon(Icons.check_circle_rounded,
                color: Colors.greenAccent, size: 80)),
        const SizedBox(height: 24),
        Text(authService.translate("Hoş Geldin!"),
            textAlign: TextAlign.center,
            style: TextStyle(color: getSubTextColor(context), fontSize: 18)),
        const SizedBox(height: 10),
        Text(authService.user!.email!,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: getTextColor(context),
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 50),
        SizedBox(
            height: 55,
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withOpacity(0.1),
                    foregroundColor: Colors.redAccent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
                onPressed: () async => await authService.logout(),
                child: Text(authService.translate("Çıkış Yap"),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)))),
      ],
    );
  }

  Widget _buildLoginView(BuildContext context, AuthService authService,
      Color fieldBgColor, Color fieldBorderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: getCardColor(context),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ]),
          child: Column(
            children: [
              TextField(
                controller: _emailController,
                style: TextStyle(color: getTextColor(context)),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                    hintText: authService.translate("Mail Adresiniz"),
                    hintStyle: TextStyle(color: getSubTextColor(context)),
                    prefixIcon: Icon(Icons.mail_rounded,
                        color: getSubTextColor(context)),
                    filled: true,
                    fillColor: fieldBgColor,
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            BorderSide(color: fieldBorderColor, width: 1)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                            color: getAccentColor(context), width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                style: TextStyle(color: getTextColor(context)),
                decoration: InputDecoration(
                    hintText: authService.translate("Şifre"),
                    hintStyle: TextStyle(color: getSubTextColor(context)),
                    prefixIcon: Icon(Icons.lock_rounded,
                        color: getSubTextColor(context)),
                    suffixIcon: IconButton(
                        icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            color: getSubTextColor(context)),
                        onPressed: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible)),
                    filled: true,
                    fillColor: fieldBgColor,
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            BorderSide(color: fieldBorderColor, width: 1)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                            color: getAccentColor(context), width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18)),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                height: 55,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                        colors: isDark(context)
                            ? [Colors.yellow.shade600, Colors.orange.shade500]
                            : [
                                Colors.orange.shade400,
                                Colors.deepOrange.shade400
                              ]),
                    boxShadow: [
                      BoxShadow(
                          color: getAccentColor(context).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4))
                    ]),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16))),
                  onPressed: authService.isLoading
                      ? null
                      : () async {
                          String mail = _emailController.text.trim();
                          String pass = _passwordController.text.trim();
                          if (!_validateLogin(mail, pass)) return;
                          String? errorMessage =
                              await authService.loginWithEmail(mail, pass);
                          if (errorMessage != null && mounted) {
                            _showError(errorMessage);
                          } else if (mounted) {
                            _showSuccess("Başarıyla giriş yapıldı!");
                            Navigator.pop(context);
                          }
                        },
                  child: authService.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(authService.translate("Giriş Yap"),
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const RegisterPage())),
                  child: Text(authService.translate("Hesap Oluştur"),
                      style: TextStyle(
                          color: getAccentColor(context),
                          fontSize: 15,
                          fontWeight: FontWeight.w600))),
              GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ForgotPasswordPage())),
                  child: Text(authService.translate("Şifremi Unuttum"),
                      style: TextStyle(
                          color: getSubTextColor(context), fontSize: 15))),
            ],
          ),
        ),
        const SizedBox(height: 40),
        Row(children: [
          Expanded(child: Divider(color: getDividerColor(context))),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(authService.translate("veya"),
                  style: TextStyle(
                      color: getSubTextColor(context), fontSize: 14))),
          Expanded(child: Divider(color: getDividerColor(context)))
        ]),
        const SizedBox(height: 30),
        if (Theme.of(context).platform == TargetPlatform.iOS) ...[
          SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark(context) ? Colors.white : Colors.black,
                      foregroundColor:
                          isDark(context) ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0),
                  icon: Icon(Icons.apple,
                      size: 26,
                      color: isDark(context) ? Colors.black : Colors.white),
                  label: Text(authService.translate("Apple ile Giriş Yap"),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: () => _showError(
                      "Apple ile giriş çok yakında aktif edilecek!"))),
          const SizedBox(height: 16),
        ],
        SizedBox(
          height: 55,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDark(context) ? const Color(0xFF2C2C2E) : Colors.white,
                foregroundColor: getTextColor(context),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: isDark(context) ? 0 : 2),
            icon: Image.network(
                "https://cdn-icons-png.flaticon.com/512/2991/2991148.png",
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.g_mobiledata,
                    color: Colors.blue,
                    size: 28)),
            label: Text(authService.translate("Google ile Oturum Aç"),
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            onPressed: authService.isLoading
                ? null
                : () async {
                    String? errorMessage = await authService.signInWithGoogle();
                    if (errorMessage != null &&
                        errorMessage != "Google girişi iptal edildi." &&
                        mounted) {
                      _showError(errorMessage);
                    } else if (errorMessage == null && mounted) {
                      _showSuccess("Google ile başarıyla giriş yapıldı!");
                      Navigator.pop(context);
                    }
                  },
          ),
        ),
      ],
    );
  }
}

class CitiesPage extends StatefulWidget {
  const CitiesPage({super.key});
  @override
  State<CitiesPage> createState() => _CitiesPageState();
}

class _CitiesPageState extends State<CitiesPage> {
  bool isEditing = false;

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final sehirler = authService.kayitliSehirler;

    return Directionality(
      textDirection: authService.uygulamaDili == "العربية"
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: getBgColor(context),
        appBar: AppBar(
          leading: buildBeautifulBackButton(context),
          backgroundColor: getBgColor(context),
          elevation: 0,
          centerTitle: true,
          title: Text(authService.translate("Şehirler"),
              style: TextStyle(
                  color: getTextColor(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          actions: [
            TextButton(
                onPressed: () => setState(() => isEditing = !isEditing),
                child: Text(
                    isEditing
                        ? authService.translate("Bitti")
                        : authService.translate("Düzenle"),
                    style:
                        TextStyle(color: getTextColor(context), fontSize: 16))),
            IconButton(
                icon: Icon(Icons.add, color: getTextColor(context), size: 28),
                onPressed: () async {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AddCityPreviewPage(
                              baslangicSehri: "İstanbul")));
                }),
            const SizedBox(width: 8),
          ],
        ),
        body: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                  color: getCardColor(context),
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: sehirler.asMap().entries.map((entry) {
                  int idx = entry.key;
                  var sehir = entry.value;
                  bool isSecili = sehir["secili"] == "true";

                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: Icon(
                            sehir["tur"] == "Konumum"
                                ? Icons.near_me_outlined
                                : Icons.public,
                            color: getSubTextColor(context)),
                        title: Text(sehir["isim"]!,
                            style: TextStyle(
                                color: getTextColor(context),
                                fontSize: 18,
                                fontWeight: FontWeight.w500)),
                        subtitle: Text(
                            "${authService.translate(sehir["sehir"] ?? "Türkiye")}\n${authService.translate(sehir["tur"])}",
                            style: TextStyle(
                                color: getSubTextColor(context),
                                fontSize: 13,
                                height: 1.3)),
                        trailing: isEditing
                            ? IconButton(
                                icon: const Icon(Icons.remove_circle,
                                    color: Colors.redAccent),
                                onPressed: () {
                                  if (sehirler.length > 1) {
                                    List<dynamic> guncel = List.from(sehirler);
                                    guncel.removeAt(idx);
                                    authService.updateSetting(
                                        'kayitli_sehirler', guncel);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(authService.translate(
                                                "En az bir şehir kalmalıdır."))));
                                  }
                                })
                            : (isSecili
                                ? Icon(Icons.check,
                                    color: getAccentColor(context))
                                : null),
                        onTap: () {
                          if (!isEditing) {
                            List<dynamic> guncelListe = List.from(sehirler);
                            for (var s in guncelListe) {
                              s["secili"] = "false";
                            }
                            guncelListe[idx]["secili"] = "true";
                            authService.updateSetting(
                                'kayitli_sehirler', guncelListe);
                            Navigator.pop(context);
                          }
                        },
                      ),
                      if (idx != sehirler.length - 1)
                        Divider(
                            color: getDividerColor(context),
                            height: 1,
                            indent: 50,
                            endIndent: 16),
                    ],
                  );
                }).toList(),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class CitySearchPage extends StatefulWidget {
  const CitySearchPage({super.key});
  @override
  State<CitySearchPage> createState() => _CitySearchPageState();
}

class _CitySearchPageState extends State<CitySearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _tumSehirler = [
    "Adana",
    "Adıyaman",
    "Afyonkarahisar",
    "Ağrı",
    "Amasya",
    "Ankara",
    "Antalya",
    "Artvin",
    "Aydın",
    "Balıkesir",
    "Bilecik",
    "Bingöl",
    "Bitlis",
    "Bolu",
    "Burdur",
    "Bursa",
    "Çanakkale",
    "Çankırı",
    "Çorum",
    "Denizli",
    "Diyarbakır",
    "Edirne",
    "Elazığ",
    "Erzincan",
    "Erzurum",
    "Eskişehir",
    "Gaziantep",
    "Giresun",
    "Gümüşhane",
    "Hakkari",
    "Hatay",
    "Isparta",
    "Mersin",
    "İstanbul",
    "İzmir",
    "Kars",
    "Kastamonu",
    "Kayseri",
    "Kırklareli",
    "Kırşehir",
    "Kocaeli",
    "Konya",
    "Kütahya",
    "Malatya",
    "Manisa",
    "Kahramanmaraş",
    "Mardin",
    "Muğla",
    "Muş",
    "Nevşehir",
    "Niğde",
    "Ordu",
    "Rize",
    "Sakarya",
    "Samsun",
    "Siirt",
    "Sinop",
    "Sivas",
    "Tekirdağ",
    "Tokat",
    "Trabzon",
    "Tunceli",
    "Şanlıurfa",
    "Uşak",
    "Van",
    "Yozgat",
    "Zonguldak",
    "Aksaray",
    "Bayburt",
    "Karaman",
    "Kırıkkale",
    "Batman",
    "Şırnak",
    "Bartın",
    "Ardahan",
    "Iğdır",
    "Yalova",
    "Karabük",
    "Kilis",
    "Osmaniye",
    "Düzce"
  ];
  List<String> _filtrelenmisSehirler = [];

  void _sehirFiltrele(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtrelenmisSehirler = [];
      } else {
        _filtrelenmisSehirler = _tumSehirler
            .where((sehir) => sehir.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    return Directionality(
      textDirection: authService.uygulamaDili == "العربية"
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: getCardColor(context),
        appBar: AppBar(
            leading: buildBeautifulBackButton(context),
            backgroundColor: getCardColor(context),
            elevation: 0),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(authService.translate("Ara"),
                    style: TextStyle(
                        color: getTextColor(context),
                        fontSize: 34,
                        fontWeight: FontWeight.bold))),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: getTextColor(context)),
                autofocus: false,
                onChanged: _sehirFiltrele,
                decoration: InputDecoration(
                    hintText: authService.translate("Ara"),
                    hintStyle: TextStyle(color: getSubTextColor(context)),
                    prefixIcon:
                        Icon(Icons.search, color: getSubTextColor(context)),
                    filled: true,
                    fillColor: getTextFieldColor(context),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0)),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    Navigator.pop(context, value.trim());
                  }
                },
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                itemCount: _filtrelenmisSehirler.length,
                separatorBuilder: (context, index) => Divider(
                    color: getDividerColor(context), height: 1, indent: 16),
                itemBuilder: (context, index) {
                  return ListTile(
                      title: Text(_filtrelenmisSehirler[index],
                          style: TextStyle(color: getTextColor(context))),
                      onTap: () =>
                          Navigator.pop(context, _filtrelenmisSehirler[index]));
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

class AddCityPreviewPage extends StatefulWidget {
  final String baslangicSehri;
  const AddCityPreviewPage({super.key, required this.baslangicSehri});
  @override
  State<AddCityPreviewPage> createState() => _AddCityPreviewPageState();
}

class _AddCityPreviewPageState extends State<AddCityPreviewPage> {
  late String _gosterilenSehir;
  bool isLoading = true;
  bool hasError = false;
  Map<String, String> vakitler = {};

  String _seciliYontem = "Diyanet Takvimi";
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

  @override
  void initState() {
    super.initState();
    _gosterilenSehir = widget.baslangicSehri;
    _fetchVakitler(_gosterilenSehir);
  }

  int _getApiMethodId(String method) {
    switch (method) {
      case "Kuzey Amerika (ISNA)":
        return 2;
      case "Müslim World Lig":
        return 3;
      case "Ummül Kurra":
        return 4;
      case "Mısır":
        return 5;
      case "Tahran Üniversitesi":
        return 7;
      case "Diyanet Takvimi":
        return 13;
      default:
        return 13;
    }
  }

  Future<void> _fetchVakitler(String sehir) async {
    setState(() {
      isLoading = true;
      hasError = false;
    });
    try {
      int methodId = _getApiMethodId(_seciliYontem);
      final url =
          'https://api.aladhan.com/v1/timingsByCity?city=$sehir&country=Turkey&method=$methodId';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data']['timings'];
        setState(() {
          vakitler = {
            "İmsak": data['Imsak'],
            "Güneş": data['Sunrise'],
            "Öğle": data['Dhuhr'],
            "İkindi": data['Asr'],
            "Akşam": data['Maghrib'],
            "Yatsı": data['Isha']
          };
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  void _showYontemDialog() {
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
                itemCount: hesaplamaSecenekleri.length,
                itemBuilder: (context, index) {
                  bool isSelected =
                      hesaplamaSecenekleri[index] == _seciliYontem;
                  return ListTile(
                    leading: isSelected
                        ? Icon(Icons.check,
                            color: getAccentColor(context), size: 20)
                        : const SizedBox(width: 20),
                    title: Text(
                        authService.translate(hesaplamaSecenekleri[index]),
                        style: TextStyle(
                            color: isSelected
                                ? getAccentColor(context)
                                : getTextColor(context),
                            fontSize: 16)),
                    onTap: () {
                      setState(
                          () => _seciliYontem = hesaplamaSecenekleri[index]);
                      Navigator.pop(context);
                      _fetchVakitler(_gosterilenSehir);
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
          title: Text(authService.translate("Yeni Şehir Ekle"),
              style: TextStyle(
                  color: getTextColor(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          backgroundColor: getBgColor(context),
          centerTitle: true,
          actions: [
            TextButton(
                onPressed: () {
                  List<dynamic> guncelListe =
                      List.from(authService.kayitliSehirler);
                  bool sehirZatenVar =
                      guncelListe.any((s) => s['isim'] == _gosterilenSehir);
                  for (var s in guncelListe) {
                    s["secili"] = "false";
                  }

                  if (sehirZatenVar) {
                    guncelListe.firstWhere(
                            (s) => s['isim'] == _gosterilenSehir)['secili'] =
                        'true';
                  } else {
                    guncelListe.add({
                      "isim": _gosterilenSehir,
                      "sehir": "Türkiye",
                      "tur": _seciliYontem,
                      "secili": "true"
                    });
                  }
                  authService.updateSetting('kayitli_sehirler', guncelListe);
                  authService.updateSetting('hesaplama_yontemi', _seciliYontem);
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text(authService.translate("Kaydet"),
                    style:
                        TextStyle(color: getTextColor(context), fontSize: 16))),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: getCardColor(context),
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_gosterilenSehir,
                                style: TextStyle(
                                    color: getTextColor(context),
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis),
                            Text(authService.translate("Türkiye"),
                                style: TextStyle(
                                    color: getSubTextColor(context),
                                    fontSize: 16)),
                          ],
                        ),
                      ),
                      TextButton(
                          onPressed: () async {
                            final yeniArama = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const CitySearchPage()));
                            if (yeniArama != null && yeniArama is String) {
                              setState(() => _gosterilenSehir = yeniArama);
                              _fetchVakitler(_gosterilenSehir);
                            }
                          },
                          child: Text(authService.translate("Değiştir"),
                              style: TextStyle(
                                  color: getTextColor(context), fontSize: 14))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (isLoading)
                    Center(
                        child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(
                                color: getAccentColor(context))))
                  else if (hasError)
                    Center(
                        child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                                authService
                                    .translate("Şehir bilgileri alınamadı."),
                                style:
                                    const TextStyle(color: Colors.redAccent))))
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _TimeColumn(
                            title: authService.translate("İmsak"),
                            time: vakitler["İmsak"] ?? "--:--"),
                        _TimeColumn(
                            title: authService.translate("Güneş"),
                            time: vakitler["Güneş"] ?? "--:--"),
                        _TimeColumn(
                            title: authService.translate("Öğle"),
                            time: vakitler["Öğle"] ?? "--:--"),
                        _TimeColumn(
                            title: authService.translate("İkindi"),
                            time: vakitler["İkindi"] ?? "--:--"),
                        _TimeColumn(
                            title: authService.translate("Akşam"),
                            time: vakitler["Akşam"] ?? "--:--"),
                        _TimeColumn(
                            title: authService.translate("Yatsı"),
                            time: vakitler["Yatsı"] ?? "--:--"),
                      ],
                    )
                ],
              ),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: _showYontemDialog,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: getCardColor(context),
                    borderRadius: BorderRadius.circular(16)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(authService.translate("Hesaplama Yöntemi"),
                            style: TextStyle(
                                color: getTextColor(context), fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(authService.translate(_seciliYontem),
                            style: TextStyle(
                                color: getSubTextColor(context), fontSize: 14))
                      ],
                    ),
                    Row(children: [
                      Icon(Icons.mosque_outlined,
                          color: getTextColor(context), size: 24),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios,
                          color:
                              isDark(context) ? Colors.white24 : Colors.black26,
                          size: 14)
                    ])
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating));
  }

  bool _validateRegister(String email, String password) {
    final authService = context.read<AuthService>();
    if (email.isEmpty || password.isEmpty) {
      _showError(authService
          .translate("Lütfen e-posta ve şifre alanlarını boş bırakmayın."));
      return false;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showError(
          authService.translate("Lütfen geçerli bir e-posta adresi girin."));
      return false;
    }
    if (password.length < 8) {
      _showError(authService
          .translate("Güvenliğiniz için şifreniz en az 8 karakter olmalıdır."));
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    Color fieldBgColor =
        isDark(context) ? const Color(0xFF1C1C1E) : Colors.grey.shade100;
    Color fieldBorderColor = isDark(context) ? Colors.white10 : Colors.black12;

    return Directionality(
      textDirection: authService.uygulamaDili == "العربية"
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: getBgColor(context),
        appBar: AppBar(
          leading: buildBeautifulBackButton(context),
          title: Text(authService.translate("Hesap Oluştur"),
              style: TextStyle(
                  color: getTextColor(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          centerTitle: true,
          backgroundColor: getBgColor(context),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        colors: [Colors.cyan.shade400, Colors.blue.shade600]),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.cyan.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5))
                    ]),
                child: const Icon(Icons.person_add_alt_1_rounded,
                    size: 60, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Text(authService.translate("Aramıza Katıl"),
                  style: TextStyle(
                      color: getTextColor(context),
                      fontSize: 26,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                  authService.translate(
                      "Ayarlarını buluta kaydetmek ve her cihazdan erişmek için ücretsiz kayıt ol."),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: getSubTextColor(context),
                      fontSize: 15,
                      height: 1.4)),
              const SizedBox(height: 35),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: getCardColor(context),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ]),
                child: Column(
                  children: [
                    TextField(
                      controller: _emailController,
                      style: TextStyle(color: getTextColor(context)),
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                          hintText: authService.translate("Mail Adresiniz"),
                          hintStyle: TextStyle(color: getSubTextColor(context)),
                          prefixIcon: Icon(Icons.mail_rounded,
                              color: getSubTextColor(context)),
                          filled: true,
                          fillColor: fieldBgColor,
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                  color: fieldBorderColor, width: 1)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                  color: Colors.cyan, width: 1.5)),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 18)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      style: TextStyle(color: getTextColor(context)),
                      decoration: InputDecoration(
                          hintText: authService.translate("Şifre Belirleyin"),
                          hintStyle: TextStyle(color: getSubTextColor(context)),
                          prefixIcon: Icon(Icons.lock_rounded,
                              color: getSubTextColor(context)),
                          suffixIcon: IconButton(
                              icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_rounded
                                      : Icons.visibility_off_rounded,
                                  color: getSubTextColor(context)),
                              onPressed: () => setState(() =>
                                  _isPasswordVisible = !_isPasswordVisible)),
                          filled: true,
                          fillColor: fieldBgColor,
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                  color: fieldBorderColor, width: 1)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                  color: Colors.cyan, width: 1.5)),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 18)),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(colors: [
                            Colors.cyan.shade400,
                            Colors.blue.shade600
                          ]),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.cyan.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4))
                          ]),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16))),
                        onPressed: authService.isLoading
                            ? null
                            : () async {
                                String mail = _emailController.text.trim();
                                String pass = _passwordController.text.trim();
                                if (!_validateRegister(mail, pass)) return;
                                String? errorMessage = await authService
                                    .registerWithEmail(mail, pass);
                                if (errorMessage != null && mounted) {
                                  _showError(errorMessage);
                                } else if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(authService.translate(
                                              "Hesabınız oluşturuldu!")),
                                          backgroundColor: Colors.green,
                                          behavior: SnackBarBehavior.floating));
                                  Navigator.pop(context);
                                }
                              },
                        child: authService.isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text(authService.translate("Kayıt Ol"),
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating));
  }

  bool _validateReset(String email) {
    final authService = context.read<AuthService>();
    if (email.isEmpty) {
      _showError(authService.translate("Lütfen mail adresinizi yazın."));
      return false;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showError(
          authService.translate("Lütfen geçerli bir e-posta adresi yazın."));
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    Color fieldBgColor =
        isDark(context) ? const Color(0xFF1C1C1E) : Colors.grey.shade100;
    Color fieldBorderColor = isDark(context) ? Colors.white10 : Colors.black12;

    return Directionality(
      textDirection: authService.uygulamaDili == "العربية"
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: getBgColor(context),
        appBar: AppBar(
          leading: buildBeautifulBackButton(context),
          title: Text(authService.translate("Şifre Sıfırlama"),
              style: TextStyle(
                  color: getTextColor(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          centerTitle: true,
          backgroundColor: getBgColor(context),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [
                      Colors.purple.shade400,
                      Colors.deepPurple.shade400
                    ]),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.purple.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5))
                    ]),
                child: const Icon(Icons.lock_reset_rounded,
                    size: 60, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Text(authService.translate("Şifrenizi mi Unuttunuz?"),
                  style: TextStyle(
                      color: getTextColor(context),
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                  authService.translate(
                      "Hesabınıza bağlı e-posta adresini girin, size güvenli bir sıfırlama bağlantısı gönderelim."),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: getSubTextColor(context),
                      fontSize: 15,
                      height: 1.4)),
              const SizedBox(height: 35),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: getCardColor(context),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ]),
                child: Column(
                  children: [
                    TextField(
                      controller: _emailController,
                      style: TextStyle(color: getTextColor(context)),
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                          hintText:
                              authService.translate("Kayıtlı Mail Adresiniz"),
                          hintStyle: TextStyle(color: getSubTextColor(context)),
                          prefixIcon: Icon(Icons.mail_rounded,
                              color: getSubTextColor(context)),
                          filled: true,
                          fillColor: fieldBgColor,
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                  color: fieldBorderColor, width: 1)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                  color: Colors.purple.shade400, width: 1.5)),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 18)),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(colors: [
                            Colors.purple.shade400,
                            Colors.deepPurple.shade400
                          ]),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.purple.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4))
                          ]),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16))),
                        onPressed: authService.isLoading
                            ? null
                            : () async {
                                String mail = _emailController.text.trim();
                                if (!_validateReset(mail)) return;
                                String? errorMessage =
                                    await authService.resetPassword(mail);
                                if (errorMessage != null && mounted) {
                                  _showError(errorMessage);
                                } else if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(authService.translate(
                                              "Sıfırlama bağlantısı mailinize gönderildi!")),
                                          backgroundColor: Colors.green,
                                          behavior: SnackBarBehavior.floating));
                                  Navigator.pop(context);
                                }
                              },
                        child: authService.isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text(authService.translate("Bağlantı Gönder"),
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeColumn extends StatelessWidget {
  final String title;
  final String time;

  const _TimeColumn({required this.title, required this.time});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    return Column(
      children: [
        Text(authService.translate(title),
            style: TextStyle(color: getSubTextColor(context), fontSize: 13)),
        const SizedBox(height: 6),
        Text(time,
            style: TextStyle(
                color: getTextColor(context),
                fontSize: 15,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}
