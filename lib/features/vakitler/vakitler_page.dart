import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../auth/auth_service.dart';
import '../../core/utils/assets_constants.dart';
import '../../core/models/city_list.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/dairesel_layout.dart';
import 'widgets/analog_saat_layout.dart';
import 'widgets/fotografli_layout.dart';
import 'widgets/timeline_layout.dart';
import 'widgets/dashboard_layout.dart';
import 'widgets/listeli_layout.dart';

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

  double _timeProgress = 0.0;

  List<Map<String, String>> vakitler = [
    {"vakit": "İmsak", "saat": "--:--", "image": Assets.imsak},
    {"vakit": "Güneş", "saat": "--:--", "image": ""},
    {"vakit": "Öğle", "saat": "--:--", "image": Assets.ogle},
    {"vakit": "İkindi", "saat": "--:--", "image": Assets.ikindi},
    {"vakit": "Akşam", "saat": "--:--", "image": Assets.aksam},
    {"vakit": "Yatsı", "saat": "--:--", "image": Assets.yatsi},
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
    if (vakitler[0]['saat'] == "--:--") {
      setState(() => _isLoading = true);
    }

    try {
      final authService = context.read<AuthService>();
      final apiKey = authService.apiKey;

      // 1. Hava Durumu İsteği (8 Saniye sınır korumalı)
      try {
        final weatherUrl =
            "https://api.openweathermap.org/data/2.5/weather?q=$city,TR&units=metric&appid=$apiKey&lang=tr";
        final weatherRes = await http
            .get(Uri.parse(weatherUrl))
            .timeout(const Duration(seconds: 8));
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
      } catch (_) {
        // Hava durumu geç yanıt verirse akışı bozmadan devam et
      }

      // 2. Vakitler İsteği (8 Saniye sınır korumalı)
      final timingsUrl =
          "https://api.aladhan.com/v1/timingsByCity?city=$city&country=Turkey&method=$method";
      final timingsRes = await http
          .get(Uri.parse(timingsUrl))
          .timeout(const Duration(seconds: 8));

      if (timingsRes.statusCode == 200) {
        final tData = json.decode(timingsRes.body)['data']['timings'];
        authService.cachePrayerTimes(city, tData);
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
        throw Exception("API Error: ${timingsRes.statusCode}");
      }
    } catch (e) {
      if (!mounted) return;
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
        _showSnackBar("Bağlantı hatası: Önbellekten gösteriliyor.");
      } else if (mounted) {
        // Hata durumunda sonsuz yüklemede kilitlenmeyi kesin olarak kesiyoruz
        setState(() => _isLoading = false);
        _showSnackBar("Veri alınamadı. İnternet bağlantınızı kontrol edin.");
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

    if (vakitler.isEmpty) return;

    for (var v in vakitler) {
      if (v['saat'] == null || !v['saat']!.contains(':')) continue;

      final parts = v['saat']!.split(':');

      int saat = int.tryParse(parts[0].trim()) ?? 0;
      int dakika = int.tryParse(parts[1].trim()) ?? 0;

      final vTime = DateTime(now.year, now.month, now.day, saat, dakika);

      if (vTime.isAfter(now)) {
        nextVakitTime = vTime;
        nextVakitName = v['vakit'] ?? "";
        break;
      }
    }

    if (nextVakitTime == null) {
      if (vakitler[0]['saat'] != null && vakitler[0]['saat']!.contains(':')) {
        final parts = vakitler[0]['saat']!.split(':');

        int saat = int.tryParse(parts[0].trim()) ?? 0;
        int dakika = int.tryParse(parts[1].trim()) ?? 0;

        nextVakitTime =
            DateTime(now.year, now.month, now.day + 1, saat, dakika);
        nextVakitName = vakitler[0]['vakit'] ?? "";
      } else {
        nextVakitTime = now.add(const Duration(hours: 1));
        nextVakitName = "Yükleniyor...";
      }
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
          backgroundColor: AppTheme.getBgColor(context),
          body: Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                  color: AppTheme.getAccentColor(context)),
              const SizedBox(height: 16),
              Text(authService.translate("Yükleniyor..."),
                  style: TextStyle(color: AppTheme.getAccentColor(context)))
            ],
          )));
    }

    Widget seciliLayout;
    switch (stil) {
      case 'Analog Saat':
      case 'Minimal Kutu':
        seciliLayout = AnalogSaatLayout(
          siradakiVakit: _siradakiVakit,
          remainingTime: _remainingTime,
          formatDuration: format,
          buildWeatherHeader: _buildWeatherHeader,
          buildCountdown: _buildCountdown,
          buildBoxGrid: _buildBoxGrid,
          vakitler: vakitler,
        );
        break;
      case 'Fotoğraflı':
        seciliLayout = FotografliLayout(
          siradakiVakit: _siradakiVakit,
          remainingTime: _remainingTime,
          vakitler: vakitler,
          buildWeatherHeader: _buildWeatherHeader,
          getMonthName: _getMonthName,
          getDayName: _getDayName,
        );
        break;
      case 'Timeline':
        seciliLayout = TimelineLayout(
          siradakiVakit: _siradakiVakit,
          remainingTime: _remainingTime,
          vakitler: vakitler,
          formatDuration: format,
          buildWeatherHeader: _buildWeatherHeader,
          translate: authService.translate,
        );
        break;
      case 'Dashboard':
        seciliLayout = DashboardLayout(
          siradakiVakit: _siradakiVakit,
          remainingTime: _remainingTime,
          buildWeatherHeader: _buildWeatherHeader,
          buildCountdown: _buildCountdown,
          buildBoxGrid: _buildBoxGrid,
          translate: authService.translate,
        );
        break;
      case 'Listeli':
        seciliLayout = ListeliLayout(
          siradakiVakit: _siradakiVakit,
          remainingTime: _remainingTime,
          vakitler: vakitler,
          formatDuration: format,
          buildWeatherHeader: _buildWeatherHeader,
          buildOriginalVakitCard: _buildOriginalVakitCard,
          translate: authService.translate,
        );
        break;
      case 'Dairesel':
      case 'Circular':
      default:
        seciliLayout = DaireselLayout(
          timeProgress: _timeProgress,
          siradakiVakit: _siradakiVakit,
          remainingTime: _remainingTime,
          formatDuration: format,
          translate: authService.translate,
          weatherHeader: _buildWeatherHeader(
              context, AppTheme.getTextColor(context), AppTheme.primaryColor),
          countdown: _buildCountdown(AppTheme.primaryColor),
          boxGrid: _buildBoxGrid(AppTheme.primaryColor, false),
        );
        break;
    }

    return Directionality(
      textDirection: authService.uygulamaDili == "العربية"
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: seciliLayout,
    );
  }

  Widget _buildCountdown(Color titleColor) {
    final authService = context.read<AuthService>();
    final now = DateTime.now();
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    Color timerColor = isDark ? Colors.white : const Color(0xFF2C3E50);

    return Column(children: [
      Text(authService.translate("Vaktin Çıkmasına"),
          style: TextStyle(color: titleColor, fontSize: 14)),
      const SizedBox(height: 4),
      Text(format(_remainingTime),
          style: TextStyle(
              color: timerColor, fontSize: 60, fontWeight: FontWeight.w400)),
      const SizedBox(height: 8),
      Text(
          "${now.day} ${authService.translate(_getMonthName(now.month))} ${now.year}",
          style: TextStyle(
              color: AppTheme.getSubTextColor(context), fontSize: 13)),
    ]);
  }

  Widget _buildBoxGrid(Color accentColor, bool isGlass) {
    final authService = context.read<AuthService>();
    bool isDark = Theme.of(context).brightness == Brightness.dark;

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
                        ? AppTheme.getDividerColor(context)
                        : AppTheme.getCardColor(context)),
                borderRadius: BorderRadius.circular(16),
                border: isGlass ? Border.all(color: Colors.white24) : null,
                boxShadow: (!isDark && !isGlass && !isNext)
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 15,
                          spreadRadius: 2,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(authService.translate(item['vakit']!),
                        style: TextStyle(
                            color: isNext
                                ? Colors.white.withValues(alpha: 0.9)
                                : AppTheme.getSubTextColor(context),
                            fontSize: 13,
                            fontWeight:
                                isNext ? FontWeight.bold : FontWeight.normal)),
                    const SizedBox(height: 2),
                    Text(item['saat']!,
                        style: TextStyle(
                            color: isNext
                                ? Colors.white
                                : AppTheme.getTextColor(context),
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
                  color: AppTheme.getDividerColor(context),
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
              final cityName = await context.push<String?>(
                  '/vakitler/city-search',
                  extra: isDark);
              if (!context.mounted) return;
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
          Image.asset(item['image']!,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                  color:
                      isDark ? const Color(0xFF031F1F) : Colors.grey.shade300)),
          Container(
              color: isNext
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.6)),
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

class VakitlerCitySearchPage extends StatefulWidget {
  final bool isDark;
  const VakitlerCitySearchPage({super.key, required this.isDark});
  @override
  State<VakitlerCitySearchPage> createState() =>
      _VakitlerCitySearchPageState();
}

class _VakitlerCitySearchPageState extends State<VakitlerCitySearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String query = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color accentColor = AppTheme.getAccentColor(context);

    final List<String> list = query.isEmpty
        ? []
        : CityData.allCities
            .where((c) => c.toLowerCase().startsWith(query.toLowerCase()))
            .toList();

    final authService = context.watch<AuthService>();

    return Directionality(
      textDirection: authService.uygulamaDili == "العربية"
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppTheme.getBgColor(context),
        appBar: AppBar(
          backgroundColor: AppTheme.getCardColor(context),
          elevation: 0,
          leading: IconButton(
              icon: Icon(Icons.arrow_back_ios,
                  color: AppTheme.getTextColor(context), size: 20),
              onPressed: () => context.pop()),
          title: TextField(
            controller: _searchController,
            autofocus: false,
            style:
                TextStyle(color: AppTheme.getTextColor(context), fontSize: 18),
            decoration: InputDecoration(
                hintText: authService.translate("Ara"),
                hintStyle: TextStyle(
                    color: AppTheme.getSubTextColor(context), fontSize: 18),
                border: InputBorder.none),
            onChanged: (val) => setState(() => query = val),
          ),
          actions: [
            if (query.isNotEmpty)
              IconButton(
                  icon: Icon(Icons.clear,
                      color: AppTheme.getSubTextColor(context)),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => query = "");
                  })
          ],
        ),
        body: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: list.length,
          separatorBuilder: (context, index) =>
              Divider(color: AppTheme.getDividerColor(context), height: 1),
          itemBuilder: (context, index) {
            final city = list[index];
            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
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
                          color: AppTheme.getTextColor(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 17)),
                  TextSpan(
                      text: city.substring(query.length),
                      style: TextStyle(
                          color: AppTheme.getSubTextColor(context),
                          fontSize: 17)),
                ] else ...[
                  TextSpan(
                      text: city,
                      style: TextStyle(
                          color: AppTheme.getTextColor(context), fontSize: 17)),
                ]
              ])),
              onTap: () => context.pop(city),
            );
          },
        ),
      ),
    );
  }
}
