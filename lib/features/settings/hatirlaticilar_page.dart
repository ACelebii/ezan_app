import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'settings_common.dart';

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
              onTap: () => showSwiperPicker(
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
                final secilen = await context.push<String>(
                    '/settings/ses-secimi',
                    extra: soundVal);
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

