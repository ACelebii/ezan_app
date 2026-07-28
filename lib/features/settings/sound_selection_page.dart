import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'settings_common.dart';

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
    context.pop(_seciliSes);
  }

  String _getAudioUrl(String sesAdi) {
    if (sesAdi.contains("Melodi")) {
      return "https://cdn.islamic.network/quran/audio/128/ar.alafasy/1.mp3";
    }
    if (sesAdi.contains("Sela")) {
      return "https://cdn.islamic.network/quran/audio/128/ar.husary/2.mp3";
    }
    if (sesAdi.contains("Ezan")) {
      return "https://cdn.islamic.network/quran/audio/128/ar.husary/1.mp3";
    }
    return "https://cdn.islamic.network/quran/audio/128/ar.alafasy/1.mp3";
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

