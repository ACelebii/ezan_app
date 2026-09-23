import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'settings_common.dart';
import '../hatirlaticilar/data/reminder_sound.dart';

class SoundSelectionPage extends StatefulWidget {
  final String mevcutSes;
  const SoundSelectionPage({super.key, required this.mevcutSes});
  @override
  State<SoundSelectionPage> createState() => _SoundSelectionPageState();
}

class _SoundSelectionPageState extends State<SoundSelectionPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  late String _seciliSesKey;

  @override
  void initState() {
    super.initState();
    _seciliSesKey = widget.mevcutSes;
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _geriDon() {
    _audioPlayer.stop();
    context.pop(_seciliSesKey);
  }

  Future<void> _onaySesiCal(ReminderSound ses) async {
    setState(() => _seciliSesKey = ses.key);
    await _audioPlayer.stop();
    if (ses.assetPath != null) {
      // AssetSource, pubspec'te bildirilen `assets/` önekini kendi ekler.
      final relatifYol = ses.assetPath!.replaceFirst('assets/', '');
      await _audioPlayer.play(AssetSource(relatifYol));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
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
                      child: Text(authService.translate("Sesler"),
                          style: TextStyle(
                              color: getSubTextColor(context), fontSize: 14)),
                    ),
                    Divider(color: getDividerColor(context), height: 1),
                    ...ReminderSounds.all.asMap().entries.map((entry) {
                      int idx = entry.key;
                      ReminderSound ses = entry.value;
                      bool isSelected = ses.key == _seciliSesKey;

                      return Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            leading: Icon(
                                ses.isAvailable
                                    ? Icons.play_arrow
                                    : Icons.lock_outline,
                                color: ses.isAvailable
                                    ? getTextColor(context)
                                    : getSubTextColor(context)),
                            title: Text(authService.translate(ses.displayName),
                                style: TextStyle(
                                    color: ses.isAvailable
                                        ? getTextColor(context)
                                        : getSubTextColor(context),
                                    fontSize: 16)),
                            trailing: isSelected
                                ? Icon(Icons.check,
                                    color: getAccentColor(context))
                                : !ses.isAvailable
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                            color: getTextFieldColor(context),
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        child: Text(
                                            authService.translate("Yakında"),
                                            style: TextStyle(
                                                color: getSubTextColor(context),
                                                fontSize: 12)),
                                      )
                                    : null,
                            onTap: () {
                              if (ses.isAvailable) {
                                _onaySesiCal(ses);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(authService.translate(
                                        'Bu ses için dosya henüz eklenmedi.'))));
                              }
                            },
                          ),
                          if (idx != ReminderSounds.all.length - 1)
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
