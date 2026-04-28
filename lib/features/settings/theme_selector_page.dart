import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_service.dart';
import '../../core/utils/assets_constants.dart';

class ThemeSelectorPage extends StatefulWidget {
  const ThemeSelectorPage({super.key});

  @override
  State<ThemeSelectorPage> createState() => _ThemeSelectorPageState();
}

class _ThemeSelectorPageState extends State<ThemeSelectorPage> {
  final List<Map<String, dynamic>> stiller = [
    {
      'isim': 'Listeli',
      'renk': Colors.pinkAccent,
      'ikon': Icons.view_list_rounded,
      'tip': 'ikon'
    },
    {
      'isim': 'Dairesel',
      'renk': Colors.greenAccent,
      'ikon': Icons.data_usage_rounded,
      'tip': 'ikon'
    },
    {
      'isim': 'Analog Saat',
      'renk': Colors.deepOrange,
      'ikon': Icons.access_time_filled_rounded,
      'tip': 'ikon'
    },
    {
      'isim': 'Fotoğraflı',
      'renk': Colors.redAccent.shade200,
      'asset': Assets.fotografCamiteMa,
      'tip': 'asset'
    },
    {
      'isim': 'Timeline',
      'renk': Colors.tealAccent,
      'ikon': Icons.view_timeline_rounded,
      'tip': 'ikon'
    },
    {
      'isim': 'Dashboard',
      'renk': Colors.teal,
      'ikon': Icons.explore,
      'tip': 'ikon'
    },
  ];

  late PageController _pageController;
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _mockVakitler = [
    {"vakit": "İmsak", "saat": "05:17", "aktif": false},
    {"vakit": "Güneş", "saat": "06:44", "aktif": false},
    {"vakit": "Öğle", "saat": "13:14", "aktif": false},
    {"vakit": "İkindi", "saat": "16:45", "aktif": true},
    {"vakit": "Akşam", "saat": "19:34", "aktif": false},
    {"vakit": "Yatsı", "saat": "20:55", "aktif": false},
  ];

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthService>(context, listen: false);
    int initialPage =
        stiller.indexWhere((s) => s['isim'] == auth.anaSayfaStili);
    if (initialPage == -1) initialPage = 0;

    _currentIndex = initialPage;
    _pageController =
        PageController(viewportFraction: 0.85, initialPage: initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildMiniHeader(Color accentColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Icon(Icons.location_on_outlined, color: accentColor, size: 14),
          const SizedBox(width: 4),
          const Text("İstanbul",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ]),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.white10, borderRadius: BorderRadius.circular(6)),
          child: const Row(
            children: [
              Icon(Icons.wb_sunny, color: Colors.white, size: 10),
              SizedBox(width: 4),
              Text("10°C",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildMiniGrid(Color accentColor, {bool isGlass = false}) {
    final authService = context.watch<AuthService>();
    return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.2),
        itemCount: 6,
        itemBuilder: (context, index) {
          var item = _mockVakitler[index];
          bool isNext = item['aktif'];
          return Container(
              decoration: BoxDecoration(
                color: isNext
                    ? accentColor
                    : (isGlass
                        ? Colors.white.withOpacity(0.1)
                        : const Color(0xFF1C1C1E)),
                borderRadius: BorderRadius.circular(10),
                border: isGlass
                    ? Border.all(color: Colors.white24, width: 0.5)
                    : null,
              ),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(authService.translate(item['vakit']),
                        style: TextStyle(
                            color: isNext ? Colors.black : Colors.white70,
                            fontSize: 9,
                            fontWeight:
                                isNext ? FontWeight.bold : FontWeight.normal)),
                    const SizedBox(height: 2),
                    Text(item['saat'],
                        style: TextStyle(
                            color: isNext ? Colors.black : Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                  ]));
        });
  }

  Widget _buildPreviewListeli(Color accentColor) {
    final authService = context.watch<AuthService>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        children: [
          _buildMiniHeader(accentColor),
          const SizedBox(height: 15),
          const Text("01:23:45",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w300)),
          Text(
              "${authService.translate("İkindi")} ${authService.translate("vaktine kalan")}",
              style: TextStyle(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Expanded(
            child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 6,
                itemBuilder: (c, i) {
                  var item = _mockVakitler[i];
                  bool isNext = item['aktif'];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isNext
                          ? Colors.black.withOpacity(0.3)
                          : Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
                      border: isNext
                          ? Border.all(color: accentColor, width: 1.5)
                          : Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(authService.translate(item['vakit']),
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: isNext
                                    ? FontWeight.bold
                                    : FontWeight.w500)),
                        Text(item['saat'],
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: isNext
                                    ? FontWeight.bold
                                    : FontWeight.w400)),
                      ],
                    ),
                  );
                }),
          )
        ],
      ),
    );
  }

  Widget _buildPreviewDairesel(Color accentColor) {
    final authService = context.watch<AuthService>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        children: [
          _buildMiniHeader(accentColor),
          const Spacer(),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: CircularProgressIndicator(
                    value: 0.65,
                    strokeWidth: 6,
                    backgroundColor: Colors.white10,
                    color: accentColor),
              ),
              Column(
                children: [
                  Text(authService.translate("İkindi"),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  Text(authService.translate("Vaktine"),
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 10)),
                ],
              )
            ],
          ),
          const Spacer(),
          const Text("01:23:45",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w300)),
          const SizedBox(height: 20),
          _buildMiniGrid(accentColor),
        ],
      ),
    );
  }

  Widget _buildPreviewAnalogSaat(Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        children: [
          _buildMiniHeader(accentColor),
          const Spacer(),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white10, width: 2),
                color: const Color(0xFF1C1C1E)),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.translate(
                    offset: const Offset(0, -25),
                    child:
                        Container(width: 3, height: 30, color: Colors.white)),
                Transform.rotate(
                    angle: 1.2,
                    child: Transform.translate(
                        offset: const Offset(0, -30),
                        child: Container(
                            width: 2, height: 40, color: Colors.white70))),
                Transform.rotate(
                    angle: 2.5,
                    child: Transform.translate(
                        offset: const Offset(0, -35),
                        child: Container(
                            width: 1, height: 50, color: accentColor))),
                Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1))),
              ],
            ),
          ),
          const Spacer(),
          const Text("01:23:45",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w300)),
          const SizedBox(height: 20),
          _buildMiniGrid(accentColor),
        ],
      ),
    );
  }

  Widget _buildPreviewTimeline(Color accentColor) {
    final authService = context.watch<AuthService>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMiniHeader(accentColor),
          const SizedBox(height: 20),
          Text(authService.translate("İkindi"),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          Text("01:23:45",
              style: TextStyle(
                  color: accentColor,
                  fontSize: 32,
                  fontWeight: FontWeight.w300)),
          const SizedBox(height: 15),
          Expanded(
            child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 6,
                itemBuilder: (c, i) {
                  var item = _mockVakitler[i];
                  bool isNext = item['aktif'];
                  return Row(
                    children: [
                      Column(
                        children: [
                          Container(
                              width: 1,
                              height: 16,
                              color:
                                  i == 0 ? Colors.transparent : Colors.white24),
                          Icon(Icons.circle,
                              size: 10,
                              color: isNext ? accentColor : Colors.white24),
                          Container(
                              width: 1,
                              height: 16,
                              color:
                                  i == 5 ? Colors.transparent : Colors.white24),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(authService.translate(item['vakit']),
                                style: TextStyle(
                                    color: isNext ? accentColor : Colors.white,
                                    fontSize: 13,
                                    fontWeight: isNext
                                        ? FontWeight.bold
                                        : FontWeight.w500)),
                            Text(item['saat'],
                                style: TextStyle(
                                    color:
                                        isNext ? accentColor : Colors.white54,
                                    fontSize: 13,
                                    fontWeight: isNext
                                        ? FontWeight.bold
                                        : FontWeight.w500)),
                          ],
                        ),
                      )
                    ],
                  );
                }),
          )
        ],
      ),
    );
  }

  Widget _buildPreviewDashboard(Color accentColor) {
    final authService = context.watch<AuthService>();
    final miniIcons = [
      Icons.menu_book,
      Icons.headset,
      Icons.explore,
      Icons.calendar_month,
      Icons.touch_app,
      Icons.mosque,
      Icons.favorite,
      Icons.settings
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        children: [
          _buildMiniHeader(accentColor),
          const SizedBox(height: 20),
          Text(authService.translate("Vaktin Çıkmasına"),
              style: const TextStyle(color: Colors.white70, fontSize: 10)),
          const Text("01:23:45",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w300)),
          const SizedBox(height: 20),
          GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, mainAxisSpacing: 12, crossAxisSpacing: 12),
              itemCount: 8,
              itemBuilder: (c, i) =>
                  Icon(miniIcons[i], color: accentColor, size: 18)),
          const Spacer(),
          _buildMiniGrid(accentColor),
        ],
      ),
    );
  }

  Widget _buildPreviewFotografli(String assetPath) {
    final authService = context.watch<AuthService>();
    return Stack(
      fit: StackFit.expand,
      children: [
        Transform.scale(
          scale: 1.06,
          child: Image.asset(assetPath,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) =>
                  Container(color: const Color(0xFF101010))),
        ),
        Container(color: Colors.black.withOpacity(0.35)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            children: [
              _buildMiniHeader(Colors.white),
              const Spacer(flex: 2),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("01",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w300,
                          height: 1.0)),
                  Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                      child: Text(":",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w300))),
                  Text("23",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w300,
                          height: 1.0)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                  "${authService.translate("İkindi")} ${authService.translate("vaktine kalan")}",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
              const Spacer(flex: 3),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 11,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _mockVakitler.map((item) {
                          bool isNext = item['aktif'];
                          Color textColor = isNext
                              ? Colors.redAccent.shade200
                              : Colors.white70;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(authService.translate(item['vakit']),
                                    style: TextStyle(
                                        color: textColor,
                                        fontSize: 11,
                                        fontWeight: isNext
                                            ? FontWeight.bold
                                            : FontWeight.w500)),
                                Text(item['saat'],
                                    style: TextStyle(
                                        color: textColor,
                                        fontSize: 11,
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
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 6,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            children: [
                              const Text("30",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w400,
                                      height: 1.0)),
                              const SizedBox(height: 4),
                              Text(authService.translate("Mart"),
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      height: 1.0)),
                              Text(authService.translate("Pzt"),
                                  style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 9,
                                      height: 1.0)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8)),
                          child: const Center(
                              child: Text("9 Şevval\n1447",
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      height: 1.2),
                                  textAlign: TextAlign.center)),
                        ),
                      ],
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ],
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
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // YENİ GERİ BUTONU
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),

                    Text(authService.translate("Ana Sayfa Stili"),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),

                    // YENİ BİTTİ BUTONU
                    InkWell(
                      onTap: () {
                        authService.updateSetting(
                            'ana_sayfa_stili', stiller[_currentIndex]['isim']);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(authService.translate("Bitti"),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: stiller.length,
                  onPageChanged: (index) =>
                      setState(() => _currentIndex = index),
                  itemBuilder: (context, index) {
                    final stil = stiller[index];
                    double scale = _currentIndex == index ? 1.0 : 0.9;

                    return TweenAnimationBuilder(
                      tween: Tween<double>(begin: scale, end: scale),
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      builder: (context, double value, child) =>
                          Transform.scale(scale: value, child: child),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF101010),
                          borderRadius: BorderRadius.circular(24),
                          border: _currentIndex == index
                              ? Border.all(color: stil['renk'], width: 2.0)
                              : Border.all(color: Colors.white10, width: 1.0),
                          boxShadow: _currentIndex == index
                              ? [
                                  BoxShadow(
                                      color: stil['renk'].withOpacity(0.2),
                                      blurRadius: 15,
                                      spreadRadius: 1)
                                ]
                              : [],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                            child: Builder(builder: (context) {
                              switch (stil['isim']) {
                                case 'Listeli':
                                  return _buildPreviewListeli(stil['renk']);
                                case 'Dairesel':
                                  return _buildPreviewDairesel(stil['renk']);
                                case 'Analog Saat':
                                  return _buildPreviewAnalogSaat(stil['renk']);
                                case 'Fotoğraflı':
                                  return _buildPreviewFotografli(stil['asset']);
                                case 'Timeline':
                                  return _buildPreviewTimeline(stil['renk']);
                                case 'Dashboard':
                                  return _buildPreviewDashboard(stil['renk']);
                                default:
                                  return Container();
                              }
                            }),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 30, top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    stiller.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentIndex == index ? 10 : 6,
                      height: _currentIndex == index ? 10 : 6,
                      decoration: BoxDecoration(
                        color: _currentIndex == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


