import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'kuran_download_service.dart';
import 'dart:io';

class KuranPage extends StatefulWidget {
  const KuranPage({super.key});

  @override
  State<KuranPage> createState() => _KuranPageState();
}

class _KuranPageState extends State<KuranPage> {
  int _currentPage = 1;
  final int _totalPages = 604; // Kuran-ı Kerim toplam sayfa sayısı
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentPage = 435;
    _pageController = PageController(initialPage: _currentPage - 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _hesaplaCuz(int sayfa) {
    if (sayfa <= 0) return 1;
    if (sayfa > 604) return 30;
    return ((sayfa - 1) ~/ 20) + 1;
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor = AppTheme.getBgColor(context);
    Color cardColor = AppTheme.getCardColor(context);
    Color textColor = AppTheme.getTextColor(context);
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text("Sayfa $_currentPage",
                style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            Text("Cüz ${_hesaplaCuz(_currentPage)}",
                style: const TextStyle(
                    color: Colors.teal,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.download_rounded, color: textColor),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("Sayfa indiriliyor..."),
                behavior: SnackBarBehavior.floating,
              ));
              // Örnek URL (gerçek API ile değiştirilmeli)
              await KuranDownloadService.downloadPage(
                  _currentPage, "https://example.com/page_$_currentPage.png");
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("İndirme tamamlandı!"),
                behavior: SnackBarBehavior.floating,
              ));
              setState(() {}); // Rebuild to show the image
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _totalPages,
              reverse: true,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index + 1;
                });
              },
              itemBuilder: (context, index) {
                int gercekSayfa = index + 1;

                return FutureBuilder<String?>(
                  future: KuranDownloadService.getPagePath(gercekSayfa),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      return Image.file(File(snapshot.data!));
                    }

                    return Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 20),
                        decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5))
                            ]),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.menu_book_rounded,
                                  size: 80,
                                  color: Colors.teal.withOpacity(0.2)),
                              const SizedBox(height: 20),
                              Text(
                                "Kuran-ı Kerim\nSayfa $gercekSayfa",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: textColor.withOpacity(0.6),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "(Henüz indirilmedi)",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: textColor.withOpacity(0.3),
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(color: cardColor, boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, -5))
            ]),
            child: Row(
              children: [
                Text("1",
                    style: TextStyle(
                        color: textColor.withOpacity(0.5),
                        fontWeight: FontWeight.bold)),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.teal,
                      inactiveTrackColor:
                          isDark ? Colors.white10 : Colors.black12,
                      thumbColor: Colors.teal,
                      overlayColor: Colors.teal.withOpacity(0.2),
                      trackHeight: 4.0,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 8.0),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 20.0),
                    ),
                    child: Slider(
                      value: _currentPage.toDouble(),
                      min: 1,
                      max: _totalPages.toDouble(),
                      onChanged: (value) {
                        setState(() {
                          _currentPage = value.toInt();
                        });
                      },
                      onChangeEnd: (value) {
                        _pageController.jumpToPage(value.toInt() - 1);
                      },
                    ),
                  ),
                ),
                Text("$_totalPages",
                    style: TextStyle(
                        color: textColor.withOpacity(0.5),
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
