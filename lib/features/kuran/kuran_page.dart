import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../main.dart';

class KuranPage extends StatefulWidget {
  const KuranPage({super.key});
  @override
  State<KuranPage> createState() => _KuranPageState();
}

class _KuranPageState extends State<KuranPage> {
  List sureler = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSureler();
  }

  Future<void> _fetchSureler() async {
    try {
      final res =
          await http.get(Uri.parse('https://api.alquran.cloud/v1/surah'));
      if (res.statusCode == 200 && mounted) {
        setState(() {
          sureler = json.decode(res.body)['data'];
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
    Color cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    Color textColor = isDark ? Colors.white : Colors.black87;
    Color subTextColor = isDark ? Colors.white60 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: InkWell(
              onTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(
                      context); // Menüden veya Dashboard'dan geldiyse geri dön
                } else {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MainNavigationPage()),
                    (route) =>
                        false, // Alt navigasyondan basıldıysa Vakitler sayfasına dön
                  );
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isDark ? Colors.white24 : Colors.black12),
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    color: textColor, size: 18),
              ),
            ),
          ),
          title: Text("Kur'an-ı Kerim",
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          backgroundColor: isDark ? const Color(0xFF031F1F) : Colors.white,
          elevation: 0,
          centerTitle: true),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: isDark ? Colors.yellow : Colors.orange.shade700))
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: sureler.length,
              itemBuilder: (context, index) {
                final s = sureler[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 4))
                      ]),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                        backgroundColor: isDark
                            ? Colors.yellow.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        child: Text(s['number'].toString(),
                            style: TextStyle(
                                color: isDark
                                    ? Colors.yellow
                                    : Colors.orange.shade700,
                                fontWeight: FontWeight.bold))),
                    title: Text(s['englishName'],
                        style: TextStyle(
                            color: textColor, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        "${s['numberOfAyahs']} Ayet - ${s['revelationType']}",
                        style: TextStyle(color: subTextColor)),
                    trailing: Text(s['name'],
                        style: TextStyle(
                            color:
                                isDark ? Colors.yellow : Colors.orange.shade700,
                            fontSize: 20)),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SureDetayPage(
                                sureIndex: s['number'],
                                sureAdi: s['englishName']))),
                  ),
                );
              },
            ),
    );
  }
}

class SureDetayPage extends StatefulWidget {
  final int sureIndex;
  final String sureAdi;
  const SureDetayPage(
      {super.key, required this.sureIndex, required this.sureAdi});
  @override
  State<SureDetayPage> createState() => _SureDetayPageState();
}

class _SureDetayPageState extends State<SureDetayPage>
    with WidgetsBindingObserver {
  List ayetler = [];
  bool isLoading = true;
  bool isEnglish = false;

  final AudioPlayer _audioPlayer = AudioPlayer();
  int? playingIndex;
  bool isPaused = false;
  bool _sistemTarafindanDurduruldu = false;

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  double _kuranFontSize = 24.0;
  double _mealFontSize = 16.0;
  bool _okIleTakip = false;
  bool _turkceOkunusu = false;
  bool _kelimeKelimeMeal = false;
  bool _tecvidRenklendirme = false;
  int _seciliArkaplan = 2;
  String _sayfaGorunum = "Liste (Sayfa)";
  String _ayetTakibi = "Vurgu";
  double _playbackRate = 1.0;
  final List<double> _speedRates = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  final Map<String, String> _hafizListesi = {
    "Mishary Al-Alfasy": "128/ar.alafasy",
    "Abdul Basit (Murattal)": "64/ar.abdulbasitmurattal",
    "Mahmoud Al-Husary": "128/ar.husary",
    "Abdurrahman As-Sudais": "192/ar.abdurrahmaansudais",
    "Abu Bakr Ash-Shatree": "128/ar.shaatree"
  };
  String _seciliHafiz = "Mishary Al-Alfasy";

  DateTime _lastPlayTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchAyetler();
    _audioPlayer.onDurationChanged.listen((d) => setState(() => _duration = d));
    _audioPlayer.onPositionChanged.listen((p) => setState(() => _position = p));
    _audioPlayer.onPlayerComplete.listen((event) {
      if (playingIndex != null) {
        if (DateTime.now().difference(_lastPlayTime).inMilliseconds < 500) {
          setState(() {
            playingIndex = null;
            isPaused = false;
          });
          return;
        }
        int nextIndex = playingIndex! + 1;
        if (nextIndex < ayetler[0]['ayahs'].length) {
          final sonrakiArapca = ayetler[0]['ayahs'][nextIndex];
          _playAyah(sonrakiArapca['number'], nextIndex, forcePlay: true);
          _scrollToAyah(nextIndex);
        } else {
          setState(() {
            playingIndex = null;
            isPaused = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (playingIndex != null && !isPaused) {
        _audioPlayer.pause();
        setState(() {
          isPaused = true;
          _sistemTarafindanDurduruldu = true;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_sistemTarafindanDurduruldu && playingIndex != null) {
        _audioPlayer.resume();
        setState(() {
          isPaused = false;
          _sistemTarafindanDurduruldu = false;
        });
      }
    }
  }

  Future<void> _fetchAyetler() async {
    final edition = isEnglish ? "en.asad" : "tr.ates";
    try {
      final res = await http.get(Uri.parse(
          'https://api.alquran.cloud/v1/surah/${widget.sureIndex}/editions/quran-simple,$edition'));
      if (res.statusCode == 200 && mounted) {
        setState(() {
          ayetler = json.decode(res.body)['data'];
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _scrollToAyah(int index) {
    if (_itemScrollController.isAttached) {
      _itemScrollController.scrollTo(
          index: index,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
          alignment: 0.1);
    }
  }

  Future<void> _playAyah(int ayahInQuran, int index,
      {bool forcePlay = false}) async {
    String hafizYolu = _hafizListesi[_seciliHafiz] ?? "128/ar.alafasy";
    String url =
        "https://cdn.islamic.network/quran/audio/$hafizYolu/$ayahInQuran.mp3";
    _lastPlayTime = DateTime.now();
    _sistemTarafindanDurduruldu = false;

    try {
      if (playingIndex == index && !forcePlay) {
        if (isPaused) {
          await _audioPlayer.resume();
          setState(() => isPaused = false);
        } else {
          await _audioPlayer.pause();
          setState(() => isPaused = true);
        }
      } else {
        await _audioPlayer.stop();
        setState(() {
          playingIndex = index;
          isPaused = false;
        });
        await _audioPlayer.play(UrlSource(url));
        await _audioPlayer.setPlaybackRate(_playbackRate);
        if (!forcePlay) _scrollToAyah(index);
      }
    } catch (e) {
      debugPrint("Ses çalma hatası: $e");
    }
  }

  Color get _getBgColor {
    switch (_seciliArkaplan) {
      case 1:
        return const Color(0xFF011010);
      case 2:
        return const Color(0xFFEBE4C9);
      case 3:
        return const Color(0xFF3B5340);
      case 4:
        return Colors.white;
      default:
        return const Color(0xFFEBE4C9);
    }
  }

  Color get _getCardColor {
    switch (_seciliArkaplan) {
      case 1:
        return const Color(0xFF031F1F).withOpacity(0.5);
      case 2:
        return const Color(0xFFDFD6B2);
      case 3:
        return const Color(0xFF2E4233);
      case 4:
        return const Color(0xFFF5F5F5);
      default:
        return const Color(0xFFDFD6B2);
    }
  }

  Color get _getTextColor => (_seciliArkaplan == 2 || _seciliArkaplan == 4)
      ? Colors.black87
      : Colors.white;
  Color get _getMealTextColor => (_seciliArkaplan == 2 || _seciliArkaplan == 4)
      ? Colors.black54
      : Colors.white70;

  void _showSelectionDialog(
      String title,
      List<String> options,
      String currentValue,
      Function(String) onSelected,
      StateSetter setModalState) {
    showDialog(
        context: context,
        builder: (context) {
          return Dialog(
              backgroundColor: const Color(0xFF2C2F33),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: options.map((option) {
                        bool isSelected = option == currentValue;
                        return ListTile(
                            leading: isSelected
                                ? const Icon(Icons.check,
                                    color: Colors.yellow, size: 20)
                                : const SizedBox(width: 20),
                            title: Text(option,
                                style: TextStyle(
                                    color: isSelected
                                        ? Colors.yellow
                                        : Colors.white,
                                    fontSize: 16)),
                            onTap: () {
                              setModalState(() => onSelected(option));
                              setState(() {});
                              Navigator.pop(context);
                            });
                      }).toList())));
        });
  }

  void _showHafizMenu(StateSetter setParentModalState) {
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) {
          return SafeArea(
              bottom: true,
              child: Container(
                  decoration: const BoxDecoration(
                      color: Color(0xFF1E2124),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20))),
                  height: MediaQuery.of(context).size.height * 0.75,
                  child: StatefulBuilder(builder: (context, setHafizState) {
                    return Column(children: [
                      Padding(
                          padding: const EdgeInsets.only(
                              top: 20, bottom: 10, left: 10, right: 10),
                          child: Row(children: [
                            IconButton(
                                icon: const Icon(Icons.arrow_back,
                                    color: Colors.white),
                                onPressed: () => Navigator.pop(context)),
                            const Expanded(
                                child: Center(
                                    child: Text("Hafız Seçimi",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)))),
                            const SizedBox(width: 48)
                          ])),
                      const Divider(color: Colors.white10),
                      Expanded(
                          child: ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              itemCount: _hafizListesi.keys.length,
                              separatorBuilder: (c, i) =>
                                  const Divider(color: Colors.white10),
                              itemBuilder: (context, index) {
                                String hafiz =
                                    _hafizListesi.keys.elementAt(index);
                                bool isSelected = _seciliHafiz == hafiz;
                                return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(Icons.play_arrow,
                                        color: Colors.white),
                                    title: Row(children: [
                                      Text(hafiz,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16)),
                                      if (isSelected) ...[
                                        const SizedBox(width: 8),
                                        const Icon(Icons.check_circle,
                                            color: Colors.yellow, size: 20)
                                      ]
                                    ]),
                                    trailing: IconButton(
                                        icon: const Icon(
                                            Icons.cloud_download_outlined,
                                            color: Colors.white54),
                                        onPressed: () {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content: const Text(
                                                      'Kayıtlar internetten (canlı) çalınmaktadır.',
                                                      style: TextStyle(
                                                          color:
                                                              Colors.black87)),
                                                  backgroundColor:
                                                      Colors.yellow.shade700,
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  duration: const Duration(
                                                      seconds: 3)));
                                        }),
                                    onTap: () async {
                                      setHafizState(() => _seciliHafiz = hafiz);
                                      setParentModalState(() {});
                                      setState(() {});
                                      if (playingIndex != null) {
                                        int suAnkiIndex = playingIndex!;
                                        int ayahInQuran = ayetler[0]['ayahs']
                                            [suAnkiIndex]['number'];
                                        _playAyah(ayahInQuran, suAnkiIndex,
                                            forcePlay: true);
                                      }
                                    });
                              }))
                    ]);
                  })));
        });
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) {
          return SafeArea(
              bottom: true,
              child: Container(
                  decoration: const BoxDecoration(
                      color: Color(0xFF1E2124),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20))),
                  height: MediaQuery.of(context).size.height * 0.75,
                  child: StatefulBuilder(builder:
                      (BuildContext context, StateSetter setModalState) {
                    return Column(children: [
                      Container(
                          margin: const EdgeInsets.only(top: 10, bottom: 20),
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                              color: Colors.white30,
                              borderRadius: BorderRadius.circular(10))),
                      Expanded(
                          child: ListView(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              children: [
                            _buildSettingsRow(
                                "Sayfa Görünüm Stili", "$_sayfaGorunum ⌄",
                                onTap: () {
                              _showSelectionDialog(
                                  "Sayfa Görünüm Stili",
                                  ["Liste (Sayfa)", "Metin (Sayfa)", "Resim"],
                                  _sayfaGorunum,
                                  (val) => _sayfaGorunum = val,
                                  setModalState);
                            }),
                            const SizedBox(height: 15),
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Arkaplan",
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 16)),
                                  Row(
                                      children: List.generate(4, (index) {
                                    int bgNum = index + 1;
                                    bool isSelected = _seciliArkaplan == bgNum;
                                    Color bgColor = bgNum == 1
                                        ? const Color(0xFF011010)
                                        : bgNum == 2
                                            ? const Color(0xFFEBE4C9)
                                            : bgNum == 3
                                                ? const Color(0xFF3B5340)
                                                : Colors.white;
                                    Color textColor = (bgNum == 2 || bgNum == 4)
                                        ? Colors.black
                                        : Colors.white;
                                    return GestureDetector(
                                        onTap: () {
                                          setModalState(
                                              () => _seciliArkaplan = bgNum);
                                          setState(() {});
                                        },
                                        child: Container(
                                            margin:
                                                const EdgeInsets.only(left: 8),
                                            width: 40,
                                            height: 30,
                                            decoration: BoxDecoration(
                                                color: bgColor,
                                                border: Border.all(
                                                    color: isSelected
                                                        ? Colors.yellow
                                                        : Colors.white30,
                                                    width: isSelected ? 2 : 1),
                                                borderRadius:
                                                    BorderRadius.circular(15)),
                                            alignment: Alignment.center,
                                            child: Text("$bgNum",
                                                style: TextStyle(
                                                    color: textColor,
                                                    fontWeight: isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.normal))));
                                  }))
                                ]),
                            const SizedBox(height: 15),
                            _buildSettingsRow("Ayet Takibi", "$_ayetTakibi ⌄",
                                onTap: () {
                              _showSelectionDialog(
                                  "Ayet Takibi",
                                  ["Yok", "Renk", "Kenarlık", "Vurgu"],
                                  _ayetTakibi,
                                  (val) => _ayetTakibi = val,
                                  setModalState);
                            }),
                            const Divider(color: Colors.white10, height: 40),
                            _buildSettingsRow("Hafız", "$_seciliHafiz >",
                                icon: Icons.person_outline, onTap: () {
                              _showHafizMenu(setModalState);
                            }),
                            const SizedBox(height: 15),
                            _buildSettingsRow("Meal Seslendirme", "Meal ⌄"),
                            const Divider(color: Colors.white10, height: 40),
                            _buildSwitchRow("Ok ile takip", _okIleTakip, (val) {
                              setModalState(() => _okIleTakip = val);
                              setState(() {});
                            }),
                            const Padding(
                                padding: EdgeInsets.symmetric(vertical: 15),
                                child: Text("Metin Ayarları",
                                    style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold))),
                            _buildSettingsRow("Mealler", "Diyanet >",
                                icon: Icons.translate),
                            _buildSwitchRow(
                                "Türkçe Okunuşu",
                                _turkceOkunusu,
                                (val) =>
                                    setModalState(() => _turkceOkunusu = val),
                                icon: Icons.cloud_download_outlined),
                            _buildSwitchRow(
                                "Kelime Kelime Meal",
                                _kelimeKelimeMeal,
                                (val) => setModalState(
                                    () => _kelimeKelimeMeal = val),
                                icon: Icons.cloud_download_outlined),
                            _buildSwitchRow(
                                "Tecvid Renklendirme",
                                _tecvidRenklendirme,
                                (val) => setModalState(
                                    () => _tecvidRenklendirme = val),
                                icon: Icons.color_lens_outlined),
                            const SizedBox(height: 15),
                            _buildFontAdjustRow(
                                "Yazı Boyutu - Kuran", _kuranFontSize, (val) {
                              setModalState(() => _kuranFontSize = val);
                              setState(() {});
                            }),
                            _buildFontAdjustRow(
                                "Yazı Boyutu - Meal", _mealFontSize, (val) {
                              setModalState(() => _mealFontSize = val);
                              setState(() {});
                            }),
                            const SizedBox(height: 40)
                          ]))
                    ]);
                  })));
        });
  }

  Widget _buildSettingsRow(String title, String trailingText,
      {IconData? icon, VoidCallback? onTap}) {
    return InkWell(
        onTap: onTap,
        child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white54, size: 20),
                const SizedBox(width: 10)
              ],
              Text(title,
                  style: const TextStyle(color: Colors.white70, fontSize: 16)),
              const Spacer(),
              Text(trailingText,
                  style: const TextStyle(color: Colors.white54, fontSize: 16))
            ])));
  }

  Widget _buildSwitchRow(String title, bool value, Function(bool) onChanged,
      {IconData? icon}) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white54, size: 20),
            const SizedBox(width: 10)
          ],
          Text(title,
              style: const TextStyle(color: Colors.white70, fontSize: 16)),
          const Spacer(),
          CupertinoSwitch(
              value: value,
              activeTrackColor: Colors.yellow.shade700,
              onChanged: onChanged)
        ]));
  }

  Widget _buildFontAdjustRow(
      String title, double currentSize, Function(double) onChanged) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Row(children: [
          Text(title,
              style: const TextStyle(color: Colors.white70, fontSize: 16)),
          const Spacer(),
          Container(
              decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(20)),
              child: Row(children: [
                IconButton(
                    icon: const Icon(Icons.remove, color: Colors.white),
                    onPressed: () =>
                        onChanged((currentSize - 2).clamp(12.0, 40.0))),
                Text("${currentSize.toInt()}",
                    style: const TextStyle(color: Colors.white)),
                IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () =>
                        onChanged((currentSize + 2).clamp(12.0, 40.0)))
              ]))
        ]));
  }

  ColorFilter _getInversionColorFilter() {
    return const ColorFilter.matrix(<double>[
      -1,
      0,
      0,
      0,
      255,
      0,
      -1,
      0,
      0,
      255,
      0,
      0,
      -1,
      0,
      255,
      0,
      0,
      0,
      1,
      0
    ]);
  }

  Widget _buildArapcaIcerik(
      dynamic arapca, bool isActive, Color arapcaYaziRengi) {
    Widget arapcaWidget;
    if (_sayfaGorunum == "Resim") {
      String imageApiUrl =
          "https://cdn.islamic.network/quran/images/${widget.sureIndex}_${arapca['numberInSurah']}.png";
      arapcaWidget = Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8)),
          child: ColorFiltered(
              colorFilter: _getInversionColorFilter(),
              child: Image.network(imageApiUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Text(
                      arapca['text'],
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          color: Colors.black, fontSize: _kuranFontSize)))));
    } else {
      arapcaWidget = Text(arapca['text'],
          textAlign: TextAlign.right,
          style: TextStyle(
              color: arapcaYaziRengi,
              fontSize: _kuranFontSize,
              fontWeight: (isActive && _ayetTakibi == "Renk")
                  ? FontWeight.bold
                  : FontWeight.normal,
              height: _sayfaGorunum.contains("Metin") ? 2.0 : 1.0));
    }
    double progress = 0.0;
    if (isActive && _duration.inMilliseconds > 0) {
      progress =
          (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      arapcaWidget,
      if (isActive && _okIleTakip)
        AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment(1.0 - (progress * 2), 0.0),
            child: const Padding(
                padding: EdgeInsets.only(top: 4.0),
                child: Icon(Icons.keyboard_double_arrow_up,
                    color: Colors.yellow, size: 28)))
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getBgColor,
      appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: InkWell(
              onTap: () => Navigator.pop(context), // Detaydan geri dönüş
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.yellow, size: 18),
              ),
            ),
          ),
          title:
              Text(widget.sureAdi, style: const TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF031F1F),
          centerTitle: true,
          actions: [
            TextButton(
                onPressed: () {
                  setState(() {
                    isEnglish = !isEnglish;
                    isLoading = true;
                  });
                  _fetchAyetler();
                },
                child: Text(isEnglish ? "TÜRKÇE" : "ENGLISH",
                    style: const TextStyle(color: Colors.yellow)))
          ]),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.yellow))
          : Column(children: [
              Expanded(
                  child: ScrollablePositionedList.builder(
                      itemScrollController: _itemScrollController,
                      itemPositionsListener: _itemPositionsListener,
                      padding: const EdgeInsets.all(12),
                      itemCount: ayetler[0]['ayahs'].length,
                      itemBuilder: (context, index) {
                        final arapca = ayetler[0]['ayahs'][index];
                        final meal = ayetler[1]['ayahs'][index];
                        final isActive = playingIndex == index;
                        final isCurrentlyPlaying = isActive && !isPaused;
                        Color arapcaYaziRengi = _getTextColor;
                        if (isActive && _ayetTakibi == "Renk") {
                          arapcaYaziRengi = Colors.orange;
                        }
                        if (_sayfaGorunum == "Metin (Sayfa)") {
                          return Container(
                              decoration: BoxDecoration(
                                  color: isActive && _ayetTakibi == "Vurgu"
                                      ? _getCardColor
                                      : Colors.transparent,
                                  border: isActive && _ayetTakibi == "Kenarlık"
                                      ? Border.all(
                                          color: Colors.yellow, width: 1.5)
                                      : null,
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 12),
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text("(${index + 1})",
                                              style: TextStyle(
                                                  color: _seciliArkaplan == 4 ||
                                                          _seciliArkaplan == 2
                                                      ? Colors.orange.shade800
                                                      : Colors.yellow,
                                                  fontSize: 12)),
                                          if (isCurrentlyPlaying)
                                            const Icon(Icons.volume_up,
                                                size: 16, color: Colors.yellow)
                                        ]),
                                    _buildArapcaIcerik(
                                        arapca, isActive, arapcaYaziRengi),
                                    const SizedBox(height: 5),
                                    Text(meal['text'],
                                        style: TextStyle(
                                            color: _getMealTextColor,
                                            fontSize: _mealFontSize)),
                                    Divider(
                                        color: _getTextColor.withOpacity(0.1),
                                        height: 30)
                                  ]));
                        }
                        Color cardCurrentColor = _getCardColor;
                        BorderSide currentBorder = BorderSide.none;
                        if (isActive) {
                          if (_ayetTakibi == "Vurgu") {
                            cardCurrentColor = _seciliArkaplan == 1
                                ? const Color(0xFF031F1F)
                                : _seciliArkaplan == 2
                                    ? const Color(0xFFD4C99D)
                                    : _seciliArkaplan == 3
                                        ? const Color(0xFF243628)
                                        : const Color(0xFFE0E0E0);
                          } else if (_ayetTakibi == "Kenarlık") {
                            currentBorder = const BorderSide(
                                color: Colors.yellow, width: 1.5);
                          }
                        }
                        return Card(
                            color: cardCurrentColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: currentBorder),
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text("Ayet ${index + 1}",
                                                style: TextStyle(
                                                    color: _seciliArkaplan ==
                                                                4 ||
                                                            _seciliArkaplan == 2
                                                        ? Colors.orange.shade800
                                                        : Colors.yellow,
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            IconButton(
                                                icon: Icon(
                                                    isCurrentlyPlaying
                                                        ? Icons.pause_circle
                                                        : Icons
                                                            .play_circle_fill,
                                                    color: _seciliArkaplan ==
                                                                4 ||
                                                            _seciliArkaplan == 2
                                                        ? Colors.orange.shade800
                                                        : Colors.yellow),
                                                onPressed: () => _playAyah(
                                                    arapca['number'], index))
                                          ]),
                                      _buildArapcaIcerik(
                                          arapca, isActive, arapcaYaziRengi),
                                      const SizedBox(height: 10),
                                      Text(meal['text'],
                                          style: TextStyle(
                                              color: _getMealTextColor,
                                              fontSize: _mealFontSize))
                                    ])));
                      })),
              _buildBottomControlPanel()
            ]),
    );
  }

  Widget _buildBottomControlPanel() {
    return SafeArea(
        bottom: true,
        child: Container(
            color: const Color(0xFF031F1F),
            padding: const EdgeInsets.only(
                top: 8.0, left: 16.0, right: 16.0, bottom: 8.0),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Expanded(
                    child: Slider(
                        min: 0.0,
                        max: _duration.inMilliseconds.toDouble(),
                        value: _position.inMilliseconds
                            .toDouble()
                            .clamp(0.0, _duration.inMilliseconds.toDouble()),
                        onChanged: (value) async {
                          final position =
                              Duration(milliseconds: value.toInt());
                          await _audioPlayer.seek(position);
                        },
                        activeColor: Colors.yellow,
                        inactiveColor: Colors.white.withOpacity(0.3)))
              ]),
              FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                            icon:
                                const Icon(Icons.settings, color: Colors.white),
                            onPressed: _showSettingsMenu),
                        IconButton(
                            icon: const Icon(Icons.person, color: Colors.white),
                            onPressed: () => _showHafizMenu(setState)),
                        Theme(
                            data: Theme.of(context)
                                .copyWith(cardColor: const Color(0xFF36393E)),
                            child: PopupMenuButton<double>(
                                initialValue: _playbackRate,
                                offset: const Offset(0, -280),
                                color: const Color(0xFF2C2F33),
                                surfaceTintColor: Colors.transparent,
                                elevation: 8,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                onSelected: (double rate) async {
                                  setState(() {
                                    _playbackRate = rate;
                                  });
                                  await _audioPlayer.setPlaybackRate(rate);
                                },
                                itemBuilder: (BuildContext context) {
                                  return _speedRates.map((rate) {
                                    bool isSelected = rate == _playbackRate;
                                    return PopupMenuItem<double>(
                                        value: rate,
                                        child: Row(children: [
                                          if (isSelected)
                                            const Icon(Icons.check,
                                                color: Colors.yellow, size: 20)
                                          else
                                            const SizedBox(width: 20),
                                          const SizedBox(width: 10),
                                          Text("${rate}x",
                                              style: TextStyle(
                                                  color: isSelected
                                                      ? Colors.yellow
                                                      : Colors.white,
                                                  fontWeight: isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.normal))
                                        ]));
                                  }).toList();
                                },
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0),
                                    child: Text("${_playbackRate}x",
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold))))),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                              icon: const Icon(Icons.stop_circle_outlined,
                                  color: Colors.white),
                              onPressed: () async {
                                await _audioPlayer.stop();
                                setState(() {
                                  playingIndex = null;
                                  isPaused = false;
                                });
                              }),
                          const SizedBox(width: 5),
                          IconButton(
                              icon: Icon(
                                  playingIndex != null && !isPaused
                                      ? Icons.pause_circle
                                      : Icons.play_circle_fill,
                                  color: Colors.yellow,
                                  size: 32),
                              onPressed: () async {
                                if (playingIndex != null) {
                                  final currentArapca =
                                      ayetler[0]['ayahs'][playingIndex!];
                                  _playAyah(
                                      currentArapca['number'], playingIndex!);
                                } else if (ayetler[0]['ayahs'].isNotEmpty) {
                                  final firstArapca = ayetler[0]['ayahs'][0];
                                  _playAyah(firstArapca['number'], 0);
                                }
                              })
                        ]),
                        const SizedBox(width: 5),
                        IconButton(
                            icon: const Icon(Icons.repeat, color: Colors.white),
                            onPressed: () {}),
                        IconButton(
                            icon: const Icon(Icons.loop, color: Colors.white),
                            onPressed: () {})
                      ]))
            ])));
  }
}
