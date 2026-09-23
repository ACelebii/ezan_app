import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../auth/auth_service.dart';
import '../../core/utils/assets_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/vakit/il_kodlari.dart';
import '../../core/vakit/vakit_modelleri.dart';
import '../../core/vakit/vakit_servisi.dart';
import '../../locator.dart';
import 'widgets/dairesel_layout.dart';
import 'widgets/gokyuzu_layout.dart';
import 'widgets/analog_saat_layout.dart';
import 'widgets/fotografli_layout.dart';
import 'widgets/timeline_layout.dart';
import 'widgets/dashboard_layout.dart';
import 'widgets/listeli_layout.dart';
import '../hatirlaticilar/data/reminder_scheduler.dart';

class EzanVaktiPage extends StatefulWidget {
  const EzanVaktiPage({super.key});
  @override
  State<EzanVaktiPage> createState() => _EzanVaktiPageState();
}

class _EzanVaktiPageState extends State<EzanVaktiPage>
    with WidgetsBindingObserver {
  late Timer _timer;
  Duration _remainingTime = Duration.zero;
  String _siradakiVakit = "Hesaplanıyor...";
  String _derece = "--°C";
  String _havaDurumuIcon = "01d";
  String _sehir = "Yükleniyor...";
  bool _isLoading = true;

  String _lastCity = "";

  /// Aramayla önizlenen geçici yer (Türkiye'deki il ya da yurt dışı); kayıtlı
  /// şehir değildir. null ise kayıtlı şehir gösterilir.
  Konum? _geciciKonum;
  String? get _temporaryCity => _geciciKonum?.ad;

  /// Kayıtlı şehrin ve gösterilen şehrin kimliği ([KayitliSehir.kimlik]); değişimi
  /// ad değil bunlar algılar (aynı adlı iki yer olabilir).
  String? _lastRealCity;
  String? _sonKimlik;
  bool _hasData = false;

  final _servis = locator<VakitServisi>();
  Konum? _konum;

  /// Dünden itibaren, Diyanet'ten (olmazsa Aladhan'dan) gelen günlük vakitler.
  List<GunlukVakit> _gunler = [];

  /// Ekranda gösterilen gün: konumun takvimine göre bugün. Telefonun saat
  /// diliminden bağımsızdır; gece yarısı geçince değişir ve vakitler yenilenir.
  DateTime? _bugun;

  /// Son başlatılan yüklemenin numarası: şehir hızlıca değişirse eski
  /// yüklemenin sonucu yok sayılır.
  int _istek = 0;
  bool _yukleniyor = false;

  /// Vakitlerin hesaplandığı tercih (yöntem, ikindi, temkin); değişince
  /// vakitler ve bildirimler yenilenir.
  String? _sonTercih;
  DateTime _sonYenileme = DateTime.fromMillisecondsSinceEpoch(0);

  String? _hicriGun;
  String? _hicriAy;
  String? _hicriYil;

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
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tikla());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Uygulama öne gelince vakitler yenilenir: gece yarısı geçmiş ya da veri
    // bayatlamış olabilir. Önbellek tazeyse ağa gidilmez.
    if (state == AppLifecycleState.resumed && _konum != null) {
      _vakitleriYukle(_konum!);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authService = context.watch<AuthService>();
    final realCity = authService.seciliSehir.isim;
    final realKimlik = authService.seciliSehir.kimlik;

    // Kullanıcı Ayarlar'dan gerçek şehrini değiştirdiyse: arama ile önizlenen
    // geçici şehri terk et ve zaten planlanmış ezan/hatırlatıcı bildirimlerini
    // yeni vakitlere göre yeniden zamanla (aksi halde eski şehrin saatleriyle
    // çalmaya devam ederler).
    if (_lastRealCity != null && _lastRealCity != realKimlik) {
      _geciciKonum = null;
      ReminderScheduler.rescheduleAll(authService);
    }
    _lastRealCity = realKimlik;

    // Hesaplama yöntemi, ikindi hesabı ya da temkin değiştiyse: vakitler ve
    // zaten planlanmış bildirimler yeni hesaba göre yenilenir.
    final tercihOzeti = authService.vakitTercihi.ozet;
    if (_sonTercih != null && _sonTercih != tercihOzeti) {
      ReminderScheduler.rescheduleAll(authService);
      final konum = _konum;
      if (konum != null) _vakitleriYukle(konum);
    }
    _sonTercih = tercihOzeti;

    final currentCity = _temporaryCity ?? realCity;
    final currentKimlik =
        _geciciKonum != null ? 'gecici-${_geciciKonum!.anahtar}' : realKimlik;
    if (_sonKimlik != currentKimlik) {
      _sonKimlik = currentKimlik;
      _lastCity = currentCity;
      _sehriYukle(currentCity);
    }
  }

  void _gercekSehreDon() {
    final secili = context.read<AuthService>().seciliSehir;
    final realCity = secili.isim;
    setState(() {
      _geciciKonum = null;
      _lastCity = realCity;
      _sonKimlik = secili.kimlik;
    });
    _sehriYukle(realCity);
  }

  /// Yeni bir şehre geçildiğinde: hava durumunu ve o şehrin vakitlerini yükler.
  /// Eski şehrin vakitleri yeni şehrin adıyla görünmesin diye ekran temizlenir.
  void _sehriYukle(String city) {
    final authService = context.read<AuthService>();

    // Kayıtlı şehrin kaydı koordinat da taşıyabilir; önizlenen (geçici) şehir
    // yalnızca adıyla aranır.
    final konum = _geciciKonum ?? authService.seciliSehir.konum;
    _havaDurumunuGetir(city, authService.apiKey, konum);

    _istek++; // önceki şehrin yarım kalan yüklemesini yok say
    setState(() {
      _konum = konum;
      _gunler = [];
      _hasData = false;
      _isLoading = true;
    });
    _vakitleriYukle(konum);
  }

  Future<void> _havaDurumunuGetir(
      String city, String? apiKey, Konum? konum) async {
    // Hava durumu vakitleri beklemez: geç yanıt verirse ya da hata verirse
    // akışı bozmadan devam edilir.
    try {
      // Koordinat varsa (yabancı yerler) ona göre; adla arama belirsizdir ve
      // yalnızca Türkiye içindir.
      final yer = konum != null && konum.koordinatVar
          ? "lat=${konum.enlem}&lon=${konum.boylam}"
          : "q=$city,TR";
      final weatherUrl =
          "https://api.openweathermap.org/data/2.5/weather?$yer&units=metric&appid=$apiKey&lang=tr";
      final weatherRes = await http
          .get(Uri.parse(weatherUrl))
          .timeout(const Duration(seconds: 8));
      if (weatherRes.statusCode == 200 && mounted && _lastCity == city) {
        final wData = json.decode(weatherRes.body);
        setState(() {
          _derece = "${wData['main']['temp'].toInt()}°C";
          _havaDurumuIcon = wData['weather'][0]['icon'];
        });
      }
    } catch (_) {}
  }

  /// [konum] için vakitleri servisten alır (önbellek tazeyse ağa gitmez).
  /// Ekranda zaten veri varsa yükleme sırasında yerinde kalır; alınamazsa
  /// eldeki veriyle devam edilir.
  Future<void> _vakitleriYukle(Konum konum) async {
    final istek = ++_istek;
    _yukleniyor = true;
    _sonYenileme = DateTime.now();

    final tercih = context.read<AuthService>().vakitTercihi;
    List<GunlukVakit>? gunler;
    try {
      gunler = await _servis.vakitleriGetir(konum, tercih);
    } catch (e) {
      // VakitHatasi (veri yok) ve beklenmedik hatalar aynı şekilde ele alınır:
      // ekran sonsuza kadar "Yükleniyor" kalmasın, hata ekranı çıksın.
      debugPrint('Vakitler yüklenemedi: $e');
      gunler = null;
    }
    if (!mounted || istek != _istek) return;
    _yukleniyor = false;

    final bugun = _servis.bugun(konum);
    final gun = gunler?.where((g) => g.tarih == bugun).firstOrNull;
    if (gunler == null || gun == null) {
      setState(() => _isLoading = false);
      if (!_hasData) {
        // Ne canlı ne önbellek veri var: sahte "--:--" değerleriyle normal
        // ekranı göstermek yerine _hasData false kalır ve build() bunun
        // yerine gerçek bir hata ekranı render eder.
        _showSnackBar("Veri alınamadı. İnternet bağlantınızı kontrol edin.");
      }
      return;
    }

    // Diyanet hicri tarihi "8 Rebiulahir 1448" biçiminde verir.
    final hicri = gun.hicriTarih?.split(' ');
    final hicriVar = hicri != null && hicri.length >= 3;
    setState(() {
      _gunler = gunler!;
      _bugun = bugun;
      _sehir = konum.ad;
      for (var i = 0; i < Vakit.values.length; i++) {
        vakitler[i]['saat'] = gun.saatler[Vakit.values[i]]!;
      }
      _hicriGun = hicriVar ? hicri.first : null;
      _hicriAy = hicriVar ? hicri.sublist(1, hicri.length - 1).join(' ') : null;
      _hicriYil = hicriVar ? hicri.last : null;
      _isLoading = false;
      _hasData = true;
    });
    _tikla();
  }

  /// Her saniye: sıradaki vakti, kalan süreyi ve ilerlemeyi hesaplar. Hepsi
  /// mutlak anlarla yapılır; telefonun saat dilimi sonucu etkilemez.
  void _tikla() {
    final konum = _konum;
    if (!mounted || !_hasData || konum == null) return;

    final simdi = DateTime.now();
    final durum = vakitDurumu(_gunler, simdi);

    // Konumun takvimine göre gün değiştiyse (gece yarısı) ya da elimizdeki veri
    // bittiyse vakitleri yeniden oku; ağ yoksa dakikada iki kereden fazla deneme.
    if ((_servis.bugun(konum) != _bugun || durum == null) &&
        !_yukleniyor &&
        simdi.difference(_sonYenileme) > const Duration(seconds: 30)) {
      _vakitleriYukle(konum);
    }
    if (durum == null) return;

    // Sıradaki vakitin günü: yatsıdan sonra sıradaki vakit yarının imsakıdır.
    final siradakiGun = _gunler.firstWhere(
        (g) => g.anlar[durum.siradaki]!.isAtSameMomentAs(durum.siradakiAn));
    final bugunGun = _gunler.where((g) => g.tarih == _bugun).firstOrNull;

    setState(() {
      _remainingTime = durum.kalan(simdi);
      _siradakiVakit = durum.siradaki.ad;
      _timeProgress = durum.ilerleme(simdi);
      if (bugunGun != null) {
        for (var i = 0; i < Vakit.values.length; i++) {
          vakitler[i]['saat'] = bugunGun.saatler[Vakit.values[i]]!;
        }
        // Sıradaki vakit yarına düşüyorsa kartında yarının saati görünür:
        // geri sayım ve bildirimle aynı olsun (bugünün imsakı 05:17 iken
        // yarınınki 05:18 olabilir).
        vakitler[Vakit.values.indexOf(durum.siradaki)]['saat'] =
            siradakiGun.saatler[durum.siradaki]!;
      }
    });
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
    WidgetsBinding.instance.removeObserver(this);
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

    if (!_hasData) {
      final city = _temporaryCity ?? authService.seciliSehir.isim;
      return Scaffold(
          backgroundColor: AppTheme.getBgColor(context),
          body: Center(
              child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off_rounded,
                    color: AppTheme.getSubTextColor(context), size: 48),
                const SizedBox(height: 16),
                Text(
                    authService.translate(
                        "$city için vakitler alınamadı. İnternet bağlantınızı kontrol edip tekrar deneyin."),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.getTextColor(context))),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _sehriYukle(city),
                  child: Text(authService.translate("Tekrar Dene")),
                ),
              ],
            ),
          )));
    }

    Widget seciliLayout;
    switch (stil) {
      case 'Gökyüzü':
        seciliLayout = GokyuzuLayout(
          gunler: _gunler,
          simdi: DateTime.now(),
          siradakiVakit: _siradakiVakit,
          remainingTime: _remainingTime,
          formatDuration: format,
          vakitler: vakitler,
          buildWeatherHeader: _buildWeatherHeader,
          translate: authService.translate,
          tarihMetni: _bugun == null
              ? null
              : "${authService.translate(_getDayName(_bugun!.weekday))}, "
                  "${_bugun!.day} "
                  "${authService.translate(_getMonthName(_bugun!.month))} "
                  "${_bugun!.year}",
          hicriMetni: _hicriGun != null && _hicriAy != null
              ? "$_hicriGun ${authService.translate(_hicriAy!)} "
                      "${_hicriYil ?? ''}"
                  .trim()
              : null,
        );
        break;
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
          tarih: _bugun,
          hicriGun: _hicriGun,
          hicriAy: _hicriAy,
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
    final now = _bugun ?? DateTime.now();
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
            if (_temporaryCity != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: _gercekSehreDon,
                child: Tooltip(
                  message: authService.translate("Kayıtlı şehrime dön"),
                  child:
                      Icon(Icons.close_rounded, color: accentColor, size: 18),
                ),
              ),
            ],
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
              final sonuc =
                  await context.push<Object>('/settings/cities/search');
              if (!context.mounted) return;
              final konum = switch (sonuc) {
                Konum k => k,
                String ad when ad.isNotEmpty => kayittanKonum({'isim': ad}),
                _ => null,
              };
              if (konum != null) {
                setState(() {
                  _geciciKonum = konum;
                  _lastCity = konum.ad;
                  _sonKimlik = 'gecici-${konum.anahtar}';
                });
                _sehriYukle(konum.ad);
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
