import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import 'kuran_download_service.dart';
import 'dart:io';
import 'providers/kuran_provider.dart';

class KuranPage extends StatelessWidget {
  const KuranPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => KuranProvider(),
      child: const _KuranPageContent(),
    );
  }
}

class _KuranPageContent extends StatefulWidget {
  const _KuranPageContent();

  @override
  State<_KuranPageContent> createState() => _KuranPageState();
}

class _KuranPageState extends State<_KuranPageContent> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<KuranProvider>(context, listen: false);
    _pageController = PageController(initialPage: provider.currentPage - 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KuranProvider>();
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
            Text("Sayfa ${provider.currentPage}",
                style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            Text("Cüz ${provider.getCuz(provider.currentPage)}",
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

              await provider.downloadPage(provider.currentPage);

              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("İndirme tamamlandı!"),
                behavior: SnackBarBehavior.floating,
              ));
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
              itemCount: provider.totalPages,
              reverse: true,
              onPageChanged: (index) {
                provider.setPage(index + 1);
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
                      value: provider.currentPage.toDouble(),
                      min: 1,
                      max: provider.totalPages.toDouble(),
                      onChanged: (value) {
                        provider.setPage(value.toInt());
                      },
                      onChangeEnd: (value) {
                        _pageController.jumpToPage(value.toInt() - 1);
                      },
                    ),
                  ),
                ),
                Text("${provider.totalPages}",
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
