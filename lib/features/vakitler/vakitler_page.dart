import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../main.dart';
import '../auth/auth_service.dart';
import '../kuran/kuran_page.dart';
import '../pusula/pusula_page.dart';
import '../imsakiye/imsakiye_page.dart';
import '../settings/settings_page.dart';
import '../zikirmatik/zikirmatik_page.dart'; // Zikirmatik sayfası eklendi
import '../../utils/assets_constants.dart';

class EzanVaktiPage extends StatefulWidget {
  const EzanVaktiPage({super.key});
  @override
  State<EzanVaktiPage> createState() => _EzanVaktiPageState();
}

class _EzanVaktiPageState extends State<EzanVaktiPage> {
  late Timer _timer;
  Duration _remainingTime = Duration.zero;
  String _siradakiVakit = "Hesaplanıyor...";
  String _derece = "--°C";
  String _havaDurumuIcon = "01d";
  String _sehir = "Yükleniyor...";
  bool _isLoading = true;

  String _lastCity = "";
  int _lastMethod = -1;
  String? _temporaryCity;
  StreamSubscription<Position>? _positionSubscription;
  Position? _lastPosition;

  late DateTime _currentTime;
  double _timeProgress = 0.0;

  List<Map<String, String>> vakitler = [
    {"vakit": "İmsak", "saat": "--:--", "image": "imsak.jpg"},
    {"vakit": "Güneş", "saat": "--:--", "image": "gunes.jpg"},
    {"vakit": "Öğle", "saat": "--:--", "image": "ogle.jpg"},
    {"vakit": "İkindi", "saat": "--:--", "image": "ikindi.jpg"},
    {"vakit": "Akşam", "saat": "--:--", "image": "aksam.jpg"},
    {"vakit": "Yatsı", "saat": "--:--", "image": "yatsi.jpg"},
  ];

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentTime = DateTime.now();
      _calculateNextVakit();
      _calculateTimeProgress();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authService = context.watch<AuthService>();
    final currentCity =
        _temporaryCity ?? authService.seciliSehir['isim'] ?? "İstanbul";
    final currentMethod = authService.apiMethod;

    if (_lastCity != currentCity || _lastMethod != currentMethod) {
      _lastCity = currentCity;
      _lastMethod = currentMethod;
      _fetchData(currentCity, currentMethod);
    }
  }

  Future<void> _fetchData(String city, int method) async {
    if (!mounted) return;
    if (vakitler[0]['saat'] == "--:--") setState(() => _isLoading = true);

    try {
      final apiKey = context.read<AuthService>().apiKey;
      final weatherUrl =
          "https://api.openweathermap.org/data/2.5/weather?q=$city,TR&units=metric&appid=$apiKey&lang=tr";
      final weatherRes = await http.get(Uri.parse(weatherUrl));
      if (weatherRes.statusCode == 200) {
        final wData = json.decode(weatherRes.body);
        if (mounted) {
          setState(() {
            _derece = "${wData['main']['temp'].toInt()}°C";
            _sehir = city;
            _havaDurumuIcon = wData['weather'][0]['icon'];
          });
        }
      }

      final timingsUrl =
          "https://api.aladhan.com/v1/timingsByCity?city=$city&country=Turkey&method=$method";
      final timingsRes = await http.get(Uri.parse(timingsUrl));
      if (timingsRes.statusCode == 200) {
        final tData = json.decode(timingsRes.body)['data']['timings'];
        context.read<AuthService>().cachePrayerTimes(city, tData);
        if (mounted) {
          setState(() {
            vakitler[0]['saat'] = tData['Fajr'].split(' ')[0];
            vakitler[1]['saat'] = tData['Sunrise'].split(' ')[0];
            vakitler[2]['saat'] = tData['Dhuhr'].split(' ')[0];
            vakitler[3]['saat'] = tData['Asr'].split(' ')[0];
            vakitler[4]['saat'] = tData['Maghrib'].split(' ')[0];
            vakitler[5]['saat'] = tData['Isha'].split(' ')[0];
            _isLoading = false;
          });
        }
        _calculateNextVakit();
        _calculateTimeProgress();
      } else {
        final cached =
            await context.read<AuthService>().getCachedPrayerTimes(city);
        if (cached != null && mounted) {
          setState(() {
            vakitler[0]['saat'] = cached['Fajr'].split(' ')[0];
            vakitler[1]['saat'] = cached['Sunrise'].split(' ')[0];
            vakitler[2]['saat'] = cached['Dhuhr'].split(' ')[0];
            vakitler[3]['saat'] = cached['Asr'].split(' ')[0];
            vakitler[4]['saat'] = cached['Maghrib'].split(' ')[0];
            vakitler[5]['saat'] = cached['Isha'].split(' ')[0];
            _isLoading = false;
          });
          _calculateNextVakit();
          _calculateTimeProgress();
          _showSnackBar("Çevrimdışı mod: Önbellekten gösteriliyor.");
        } else if (mounted) {
          setState(() => _isLoading = false);
          _showSnackBar(
              "Ezan vakitleri alınamadı. Lütfen daha sonra tekrar deneyin.");
        }
      }
    } catch (e) {
      final cached =
          await context.read<AuthService>().getCachedPrayerTimes(city);
      if (cached != null && mounted) {
        setState(() {
          vakitler[0]['saat'] = cached['Fajr'].split(' ')[0];
          vakitler[1]['saat'] = cached['Sunrise'].split(' ')[0];
          vakitler[2]['saat'] = cached['Dhuhr'].split(' ')[0];
          vakitler[3]['saat'] = cached['Asr'].split(' ')[0];
          vakitler[4]['saat'] = cached['Maghrib'].split(' ')[0];
          vakitler[5]['saat'] = cached['Isha'].split(' ')[0];
          _isLoading = false;
        });
        _calculateNextVakit();
        _calculateTimeProgress();
        _showSnackBar("Çevrimdışı mod: Önbellekten gösteriliyor.");
      } else if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar("Veri alınırken bir hata oluştu: $e");
      }
    }
  }

  void _calculateTimeProgress() {
    if (_isLoading || !mounted) return;

    DateTime now = DateTime.now();
    DateTime? startTime, endTime;
    String currentVakitName = "";

    for (int i = 0; i < vakitler.length; i++) {
      if (!vakitler[i]['saat']!.contains(':')) continue;
      final parts = vakitler[i]['saat']!.split(':');
      final vTime = DateTime(now.year, now.month, now.day, int.parse(parts[0]),
          int.parse(parts[1]));

      if (vTime.isAfter(now)) {
        currentVakitName = i == 0
            ? vakitler[vakitler.length - 1]['vakit']!
            : vakitler[i - 1]['vakit']!;
        endTime = vTime;
        break;
      }
    }

    if (endTime == null) {
      final parts = vakitler[0]['saat']!.split(':');
      currentVakitName = vakitler[vakitler.length - 1]['vakit']!;
      endTime = DateTime(now.year, now.month, now.day + 1, int.parse(parts[0]),
          int.parse(parts[1]));
    }

    for (int i = 0; i < vakitler.length; i++) {
      if (vakitler[i]['vakit'] == currentVakitName) {
        if (!vakitler[i]['saat']!.contains(':')) continue;
        final parts = vakitler[i]['saat']!.split(':');

        DateTime vTime = DateTime(now.year, now.month, now.day,
            int.parse(parts[0]), int.parse(parts[1]));
        if (currentVakitName == 'Yatsı' && now.hour < 3) {
          vTime = vTime.subtract(const Duration(days: 1));
        }
        startTime = vTime;
        break;
      }
    }

    if (startTime != null) {
      final totalDuration = endTime.difference(startTime).inSeconds;
      final elapsedDuration = now.difference(startTime).inSeconds;
      if (totalDuration <= 0) {
        if (mounted) {
          setState(() => _timeProgress = 0.0);
        }
        return;
      }

      if (mounted) {
        setState(() {
          _timeProgress = elapsedDuration / totalDuration;
          if (_timeProgress > 1.0) _timeProgress = 1.0;
          if (_timeProgress < 0.0) _timeProgress = 0.0;
        });
      }
    }
  }

  void _calculateNextVakit() {
    final now = DateTime.now();
    DateTime? nextVakitTime;
    String nextVakitName = "";

    for (var v in vakitler) {
      if (!v['saat']!.contains(':')) continue;
      final parts = v['saat']!.split(':');
      final vTime = DateTime(now.year, now.month, now.day, int.parse(parts[0]),
          int.parse(parts[1]));
      if (vTime.isAfter(now)) {
        nextVakitTime = vTime;
        nextVakitName = v['vakit']!;
        break;
      }
    }

    if (nextVakitTime == null) {
      final parts = vakitler[0]['saat']!.split(':');
      nextVakitTime = DateTime(now.year, now.month, now.day + 1,
          int.parse(parts[0]), int.parse(parts[1]));
      nextVakitName = vakitler[0]['vakit']!;
    }

    if (mounted) {
      setState(() {
        _remainingTime = nextVakitTime!.difference(now);
        _siradakiVakit = nextVakitName;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String format(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes % 60)}:${twoDigits(d.inSeconds % 60)}";
  }

  String _getMonthName(int month) {
    const months = [
      "",
      "Ocak",
      "Şubat",
      "Mart",
      "Nisan",
      "Mayıs",
      "Haziran",
      "Temmuz",
      "Ağustos",
      "Eylül",
      "Ekim",
      "Kasım",
      "Aralık"
    ];
    return months[month];
  }

  String _getDayName(int weekday) {
    const days = [
      "",
      "Pazartesi",
      "Salı",
      "Çarşamba",
      "Perşembe",
      "Cuma",
      "Cumartesi",
      "Pazar"
    ];
    return days[weekday];
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final stil = authService.anaSayfaStili;

    if (_isLoading) {
      return Scaffold(
          backgroundColor: Colors.black,
          body: Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.yellow),
              const SizedBox(height: 16),
              Text(authService.translate("Yükleniyor..."),
                  style: const TextStyle(color: Colors.yellow))
            ],
          )));
    }

    Widget seciliLayout;
    switch (stil) {
      case 'Analog Saat':
      case 'Minimal Kutu':
        seciliLayout = _buildAnalogSaatLayout(context);
        break;
      case 'Fotoğraflı':
        seciliLayout = _buildFotografliLayout(context);
        break;
      case 'Timeline':
        seciliLayout = _buildTimelineLayout(context);
        break;
      case 'Dashboard':
        seciliLayout = _buildDashboardLayout(context);
        break;
      case 'Listeli':
        seciliLayout = _buildListeliLayout(context);
        break;
      case 'Dairesel':
      case 'Circular':
      default:
        seciliLayout = _buildDaireselLayout(context);
        break;
    }

    return Directionality(
      textDirection: authService.uygulamaDili == "العربية"
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: seciliLayout,
    );
  }

  // ==========================================================================
  // 1. TEMA: DAİRESEL
  // ==========================================================================
  Widget _buildDaireselLayout(BuildContext context) {
    final authService = context.read<AuthService>();
    Color accentColor = Colors.greenAccent;
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 100), // Alt menü boşluğu
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildWeatherHeader(context, Colors.white, accentColor),
                const SizedBox(height: 40),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: CircularProgressIndicator(
                        value: _timeProgress,
                        strokeWidth: 12,
                        backgroundColor: Colors.white10,
                        color: accentColor,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),
                        Text(authService.translate(_siradakiVakit),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(authService.translate("Vaktine"),
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 14)),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 40),
                _buildCountdown(Colors.white54),
                const SizedBox(height: 40),
                _buildBoxGrid(accentColor, false),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // 2. TEMA: ANALOG SAAT
  // ==========================================================================
  Widget _buildAnalogSaatLayout(BuildContext context) {
    Color accentColor = Colors.deepOrange;
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 100), // Alt menü boşluğu
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildWeatherHeader(context, Colors.white, accentColor),
                const SizedBox(height: 40),
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white10, width: 4),
                      color: const Color(0xFF1C1C1E),
                      boxShadow: [
                        BoxShadow(
                            color: accentColor.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 5)
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ...List.generate(12, (index) {
                          double angle = (index * 30) * pi / 180;
                          final romaRakamlari = [
                            "XII",
                            "I",
                            "II",
                            "III",
                            "IV",
                            "V",
                            "VI",
                            "VII",
                            "VIII",
                            "IX",
                            "X",
                            "XI"
                          ];
                          return Transform.rotate(
                            angle: angle,
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Container(
                                        width: index % 3 == 0 ? 4 : 2,
                                        height: 10,
                                        color: index % 3 == 0
                                            ? accentColor
                                            : Colors.white24),
                                  ),
                                  const SizedBox(height: 2),
                                  Transform.rotate(
                                    angle: -angle,
                                    child: Text(romaRakamlari[index],
                                        style: TextStyle(
                                            color: index % 3 == 0
                                                ? Colors.orange.shade200
                                                : Colors.white54,
                                            fontSize: index % 3 == 0 ? 16 : 12,
                                            fontWeight: FontWeight.bold,
                                            height: 1.0)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        Transform.rotate(
                          angle: (_currentTime.hour % 12 +
                                  _currentTime.minute / 60) *
                              30 *
                              pi /
                              180,
                          child: Align(
                              alignment: Alignment.center,
                              child: Transform.translate(
                                  offset: const Offset(0, -30),
                                  child: Container(
                                      width: 7,
                                      height: 70,
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(4))))),
                        ),
                        Transform.rotate(
                          angle:
                              (_currentTime.minute + _currentTime.second / 60) *
                                  6 *
                                  pi /
                                  180,
                          child: Align(
                              alignment: Alignment.center,
                              child: Transform.translate(
                                  offset: const Offset(0, -45),
                                  child: Container(
                                      width: 5,
                                      height: 100,
                                      decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.7),
                                          borderRadius:
                                              BorderRadius.circular(2))))),
                        ),
                        Transform.rotate(
                          angle: _currentTime.second * 6 * pi / 180,
                          child: Align(
                              alignment: Alignment.center,
                              child: Transform.translate(
                                  offset: const Offset(0, -50),
                                  child: Container(
                                      width: 2,
                                      height: 120,
                                      decoration: BoxDecoration(
                                          color: accentColor,
                                          borderRadius:
                                              BorderRadius.circular(1))))),
                        ),
                        Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                                color: accentColor,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                _buildCountdown(accentColor),
                const SizedBox(height: 40),
                _buildBoxGrid(accentColor, false),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // 3. TEMA: FOTOĞRAFLI
  // ==========================================================================
  Widget _buildFotografliLayout(BuildContext context) {
    final authService = context.read<AuthService>();
    Color accentColor = Colors.redAccent.shade200;
    String mosqueBg = Assets.fotografCamiteMa;

    String hours = _remainingTime.inHours.toString().padLeft(2, '0');
    String minutes = (_remainingTime.inMinutes % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Transform.scale(
            scale: 1.06,
            child: Image.asset(mosqueBg,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (c, e, s) =>
                    Container(color: const Color(0xFF101010))),
          ),
          Container(color: Colors.black.withOpacity(0.35)),
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 5,
              bottom: MediaQuery.of(context).padding.bottom +
                  90, // Alt menü boşluğu
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildWeatherHeader(context, Colors.white, Colors.white),
                  const SizedBox(height: 25),
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(hours,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 75,
                                  fontWeight: FontWeight.w300,
                                  height: 1.0)),
                          const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 4.0, vertical: 10.0),
                            child: Text(":",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 50,
                                    fontWeight: FontWeight.w300)),
                          ),
                          Text(minutes,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 75,
                                  fontWeight: FontWeight.w300,
                                  height: 1.0)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                          "${authService.translate(_siradakiVakit)} ${authService.translate("vaktine kalan")}",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5)),
                    ],
                  ),
                  const SizedBox(height: 35),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 11,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: vakitler.map((item) {
                                bool isNext = item['vakit'] == _siradakiVakit;
                                Color textColor =
                                    isNext ? accentColor : Colors.white70;
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                          authService.translate(item['vakit']!),
                                          style: TextStyle(
                                              color: textColor,
                                              fontSize: 18,
                                              fontWeight: isNext
                                                  ? FontWeight.bold
                                                  : FontWeight.w500)),
                                      Text(item['saat']!,
                                          style: TextStyle(
                                              color: textColor,
                                              fontSize: 18,
                                              fontWeight: isNext
                                                  ? FontWeight.bold
                                                  : FontWeight.w500)),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          flex: 6,
                          child: Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  children: [
                                    Text(DateTime.now().day.toString(),
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 34,
                                            fontWeight: FontWeight.w400)),
                                    Text(
                                        authService.translate(_getMonthName(
                                            DateTime.now().month)),
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 16)),
                                    Text(
                                        authService.translate(_getDayName(
                                            DateTime.now().weekday)),
                                        style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 15),
                              Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Text("9 Shawwal\n1447",
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          height: 1.1),
                                      textAlign: TextAlign.center),
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // ==========================================================================
  // 4. TEMA: TIMELINE
  // ==========================================================================
  Widget _buildTimelineLayout(BuildContext context) {
    final authService = context.read<AuthService>();
    Color accentColor = Colors.tealAccent;
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = isDark ? Colors.white : Colors.black87;

    final anaVakitler = vakitler.where((v) => v['vakit'] != 'Güneş').toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildWeatherHeader(context, textColor, accentColor),
            Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(authService.translate(_siradakiVakit),
                      style: TextStyle(
                          color: textColor,
                          fontSize: 32,
                          fontWeight: FontWeight.bold)),
                  Text(format(_remainingTime),
                      style: TextStyle(
                          color: accentColor,
                          fontSize: 48,
                          fontWeight: FontWeight.w300)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                  padding: const EdgeInsets.only(
                      left: 30, right: 30, bottom: 100), // Alt menü boşluğu
                  itemCount: anaVakitler.length,
                  itemBuilder: (context, index) {
                    final item = anaVakitler[index];
                    bool isNext = item['vakit'] == _siradakiVakit;
                    return IntrinsicHeight(
                      child: Row(
                        children: [
                          Column(
                            children: [
                              Container(
                                  width: 2,
                                  height: 20,
                                  color: index == 0
                                      ? Colors.transparent
                                      : (isDark
                                          ? Colors.white24
                                          : Colors.black12)),
                              Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                      color: isNext
                                          ? accentColor
                                          : (isDark
                                              ? Colors.white24
                                              : Colors.black12),
                                      shape: BoxShape.circle)),
                              Expanded(
                                  child: Container(
                                      width: 2,
                                      color: index == anaVakitler.length - 1
                                          ? Colors.transparent
                                          : (isDark
                                              ? Colors.white24
                                              : Colors.black12))),
                            ],
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(authService.translate(item['vakit']!),
                                      style: TextStyle(
                                          color:
                                              isNext ? accentColor : textColor,
                                          fontSize: 20,
                                          fontWeight: isNext
                                              ? FontWeight.bold
                                              : FontWeight.w500)),
                                  Text(item['saat']!,
                                      style: TextStyle(
                                          color: isNext
                                              ? accentColor
                                              : getSubTextColor(context),
                                          fontSize: 20,
                                          fontWeight: isNext
                                              ? FontWeight.bold
                                              : FontWeight.normal)),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    );
                  }),
            )
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // 5. TEMA: DASHBOARD
  // ==========================================================================
  Widget _buildDashboardLayout(BuildContext context) {
    final authService = context.read<AuthService>();
    Color accentColor = Colors.teal;

    final icons = [
      {"i": Icons.menu_book_rounded, "t": "Kuran"},
      {"i": Icons.library_books_rounded, "t": "Kütüphane"},
      {"i": Icons.explore_rounded, "t": "Pusula"},
      {"i": Icons.calendar_month_rounded, "t": "İmsakiye"},
      {"i": Icons.touch_app_rounded, "t": "Zikirmatik"},
      {"i": Icons.mosque_rounded, "t": "Camiler"},
      {"i": Icons.favorite_rounded, "t": "Dualar"},
      {"i": Icons.settings_rounded, "t": "Ayarlar"},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 100), // Alt menü boşluğu
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildWeatherHeader(context, Colors.white, accentColor),
                const SizedBox(height: 30),
                _buildCountdown(accentColor),
                const SizedBox(height: 40),
                GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 25,
                            crossAxisSpacing: 15),
                    itemCount: 8,
                    itemBuilder: (c, i) {
                      final item = icons[i];
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            // Tıklama Yönlendirmeleri
                            if (item['t'] == 'Kuran') {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const KuranPage()));
                            } else if (item['t'] == 'Pusula') {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const PusulaPage()));
                            } else if (item['t'] == 'İmsakiye') {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const ImsakiyePage()));
                            } else if (item['t'] == 'Ayarlar') {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const SettingsPage()));
                            } else if (item['t'] == 'Zikirmatik') {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => ZikirmatikPage()));
                            } else {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text(
                                    "${authService.translate(item['t'] as String)} yakında eklenecek...",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                                backgroundColor: accentColor.withOpacity(0.8),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 1),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ));
                            }
                          },
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(item["i"] as IconData,
                                    color: accentColor, size: 30),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: Text(
                                      authService
                                          .translate(item["t"] as String),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 11)),
                                )
                              ]),
                        ),
                      );
                    }),
                const SizedBox(height: 40),
                _buildBoxGrid(accentColor, false),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // 6. TEMA: LİSTELİ
  // ==========================================================================
  Widget _buildListeliLayout(BuildContext context) {
    final authService = context.read<AuthService>();
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = isDark ? Colors.white : Colors.black87;
    Color accentColor = isDark ? Colors.yellow : Colors.orange.shade700;

    final anaVakitler = vakitler.where((v) => v['vakit'] != 'Güneş').toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildWeatherHeader(context, textColor, accentColor),
            const SizedBox(height: 15),
            Text(format(_remainingTime),
                style: TextStyle(
                    color: textColor,
                    fontSize: 75,
                    fontWeight: FontWeight.w300)),
            Text(
                "${authService.translate(_siradakiVakit)} ${authService.translate("vaktine kalan")}",
                style: TextStyle(
                    color: accentColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(
                    left: 15, right: 15, bottom: 100), // Alt menü boşluğu
                itemCount: anaVakitler.length,
                itemBuilder: (context, index) {
                  var item = anaVakitler[index];
                  bool isNext = item['vakit'] == _siradakiVakit;
                  return _buildOriginalVakitCard(
                      item, isNext, accentColor, isDark);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- ORTAK BİLEŞENLER ---

  Widget _buildCountdown(Color titleColor) {
    final authService = context.read<AuthService>();
    final now = DateTime.now();
    return Column(children: [
      Text(authService.translate("Vaktin Çıkmasına"),
          style: TextStyle(color: titleColor, fontSize: 14)),
      Text(format(_remainingTime),
          style: const TextStyle(
              color: Colors.white, fontSize: 60, fontWeight: FontWeight.w300)),
      Text(
          "${now.day} ${authService.translate(_getMonthName(now.month))} ${now.year}",
          style: const TextStyle(color: Colors.white54, fontSize: 12)),
    ]);
  }

  Widget _buildBoxGrid(Color accentColor, bool isGlass) {
    final authService = context.read<AuthService>();
    return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2),
        itemCount: 6,
        itemBuilder: (context, index) {
          var item = vakitler[index];
          bool isNext = item['vakit'] == _siradakiVakit;
          return Container(
              decoration: BoxDecoration(
                color: isNext
                    ? accentColor
                    : (isGlass
                        ? Colors.white.withOpacity(0.1)
                        : const Color(0xFF1C1C1E)),
                borderRadius: BorderRadius.circular(16),
                border: isGlass ? Border.all(color: Colors.white24) : null,
              ),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(authService.translate(item['vakit']!),
                        style: TextStyle(
                            color: isNext ? Colors.black : Colors.white70,
                            fontSize: 13,
                            fontWeight:
                                isNext ? FontWeight.bold : FontWeight.normal)),
                    const SizedBox(height: 2),
                    Text(item['saat']!,
                        style: TextStyle(
                            color: isNext ? Colors.black : Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                  ]));
        });
  }

  Widget _buildWeatherHeader(
      BuildContext context, Color textColor, Color accentColor) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final authService = context.watch<AuthService>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(Icons.location_on_outlined, color: accentColor, size: 20),
            const SizedBox(width: 5),
            Text(authService.translate(_sehir),
                style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Image.network(
                    "https://openweathermap.org/img/wn/$_havaDurumuIcon.png",
                    width: 25,
                    height: 25,
                    errorBuilder: (c, e, s) =>
                        Icon(Icons.wb_sunny, size: 15, color: accentColor)),
                Text(_derece,
                    style: TextStyle(
                        color: textColor, fontWeight: FontWeight.bold)),
              ]),
            ),
          ]),
          IconButton(
            icon: Icon(Icons.search, color: accentColor, size: 28),
            onPressed: () async {
              final cityName = await Navigator.push<String?>(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CitySearchPage(isDark: isDark)));
              if (cityName != null && cityName.isNotEmpty) {
                setState(() {
                  _temporaryCity = cityName;
                  _lastCity = cityName;
                });
                _fetchData(cityName, context.read<AuthService>().apiMethod);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOriginalVakitCard(
      Map<String, String> item, bool isNext, Color accentColor, bool isDark) {
    final authService = context.read<AuthService>();
    return Container(
      height: 95,
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(fit: StackFit.expand, children: [
          Image.asset("assets/Images/${item['image']}",
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                  color:
                      isDark ? const Color(0xFF031F1F) : Colors.grey.shade300)),
          Container(
              color: isNext
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.6)),
          if (isNext)
            Container(
                decoration: BoxDecoration(
                    border: Border.all(color: accentColor, width: 2),
                    borderRadius: BorderRadius.circular(20))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(authService.translate(item['vakit']!),
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight:
                              isNext ? FontWeight.bold : FontWeight.w500)),
                  Text(item['saat']!,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight:
                              isNext ? FontWeight.w400 : FontWeight.w300)),
                ]),
          ),
        ]),
      ),
    );
  }
}

Color getSubTextColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white54
        : Colors.black54;

class CitySearchPage extends StatefulWidget {
  final bool isDark;
  const CitySearchPage({super.key, required this.isDark});
  @override
  State<CitySearchPage> createState() => _CitySearchPageState();
}

class _CitySearchPageState extends State<CitySearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String query = "";

  final List<String> allCities = [
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color accentColor = widget.isDark ? Colors.yellow : Colors.orange.shade700;

    final List<String> list = query.isEmpty
        ? []
        : allCities
            .where((c) => c.toLowerCase().startsWith(query.toLowerCase()))
            .toList();

    final authService = context.watch<AuthService>();

    return Directionality(
      textDirection: authService.uygulamaDili == "العربية"
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: widget.isDark ? Colors.black : const Color(0xFFF2F2F7),
        appBar: AppBar(
          backgroundColor:
              widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
          elevation: 0,
          leading: IconButton(
              icon: Icon(Icons.arrow_back_ios,
                  color: widget.isDark ? Colors.white : Colors.black, size: 20),
              onPressed: () => Navigator.pop(context, null)),
          title: TextField(
            controller: _searchController,
            autofocus: false,
            style: TextStyle(
                color: widget.isDark ? Colors.white : Colors.black,
                fontSize: 18),
            decoration: InputDecoration(
                hintText: authService.translate("Ara"),
                hintStyle: TextStyle(
                    color: widget.isDark ? Colors.white54 : Colors.black54,
                    fontSize: 18),
                border: InputBorder.none),
            onChanged: (val) => setState(() => query = val),
          ),
          actions: [
            if (query.isNotEmpty)
              IconButton(
                  icon: Icon(Icons.clear,
                      color: widget.isDark ? Colors.white54 : Colors.black54),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => query = "");
                  })
          ],
        ),
        body: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: list.length,
          separatorBuilder: (context, index) => Divider(
              color: widget.isDark ? Colors.white10 : Colors.black12,
              height: 1),
          itemBuilder: (context, index) {
            final city = list[index];
            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.15),
                      shape: BoxShape.circle),
                  child: Icon(Icons.location_on_outlined,
                      color: accentColor, size: 18)),
              title: RichText(
                  text: TextSpan(children: [
                if (query.isNotEmpty &&
                    city.toLowerCase().startsWith(query.toLowerCase())) ...[
                  TextSpan(
                      text: city.substring(0, query.length),
                      style: TextStyle(
                          color: widget.isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 17)),
                  TextSpan(
                      text: city.substring(query.length),
                      style: TextStyle(
                          color:
                              widget.isDark ? Colors.white60 : Colors.black54,
                          fontSize: 17)),
                ] else ...[
                  TextSpan(
                      text: city,
                      style: TextStyle(
                          color: widget.isDark ? Colors.white : Colors.black87,
                          fontSize: 17)),
                ]
              ])),
              onTap: () => Navigator.pop(context, city),
            );
          },
        ),
      ),
    );
  }
}
