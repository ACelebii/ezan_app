import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ezan_vakti_uygulamasi/core/theme/app_theme.dart';
import 'package:ezan_vakti_uygulamasi/core/widgets/glass_button.dart';
import 'package:ezan_vakti_uygulamasi/locator.dart';
import 'package:ezan_vakti_uygulamasi/features/multimedya/data/multimedya_repository.dart';
import 'package:ezan_vakti_uygulamasi/features/multimedya/multimedya_model.dart';
import 'package:ezan_vakti_uygulamasi/features/multimedya/multimedya_video_tab.dart';
import 'package:ezan_vakti_uygulamasi/features/multimedya/multimedya_wallpaper_tab.dart';
import 'package:ezan_vakti_uygulamasi/features/multimedya/multimedya_quote_feed.dart';
import '../auth/auth_service.dart';

class MultimediaPage extends StatefulWidget {
  const MultimediaPage({super.key});

  @override
  State<MultimediaPage> createState() => _MultimediaPageState();
}

class _MultimediaPageState extends State<MultimediaPage> {
  final MultimediaRepository _repo = getIt<MultimediaRepository>();
  late Future<List<MultimediaItem>> _future;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _future = _repo.getData();
  }

  Future<void> _refreshData() async {
    setState(() {
      _future = _repo.getData();
    });
  }

  Widget _buildTabSelector(BuildContext context, AuthService authService) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final labels = ["Video", "Ayet", "Hadis", "Duvar Kağıdı"];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = _selectedTab == index;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _selectedTab = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? (isDark ? Colors.white.withValues(alpha: 0.16) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: selected && !isDark
                      ? [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 1))
                        ]
                      : [],
                ),
                child: Text(
                  authService.translate(labels[index]),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    color: selected
                        ? AppTheme.getTextColor(context)
                        : AppTheme.getSubTextColor(context),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    Color bgColor = AppTheme.getBgColor(context);
    Color textColor = AppTheme.getTextColor(context);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.only(left: 16.0, top: 12.0, bottom: 12.0),
              child: Row(
                children: [
                  GlassButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  authService.translate("Multimedya"),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: textColor,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildTabSelector(context, authService),
            const SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshData,
                color: AppTheme.primaryColor,
                child: FutureBuilder<List<MultimediaItem>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.primaryColor));
                    } else if (snapshot.hasError) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                              height: MediaQuery.of(context).size.height * 0.2),
                          Icon(Icons.wifi_off_rounded,
                              size: 64,
                              color: Colors.grey.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 32.0),
                            child: Text(
                              "Sunucuya bağlanılamadı.\nLütfen internet bağlantınızı kontrol edip sayfayı aşağı çekerek yenileyin.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: textColor.withValues(alpha: 0.6),
                                  height: 1.5),
                            ),
                          ),
                        ],
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                              height: MediaQuery.of(context).size.height * 0.2),
                          Icon(Icons.video_library_outlined,
                              size: 64,
                              color: Colors.grey.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text(
                            "Henüz multimedya içeriği eklenmemiş.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: textColor.withValues(alpha: 0.6),
                                fontSize: 16),
                          ),
                        ],
                      );
                    }

                    final all = snapshot.data!;
                    final videoGrouped = _repo.groupByCategory(
                        _repo.ofType(all, MultimediaType.video));
                    final ayetItems = _repo.ofType(all, MultimediaType.ayet);
                    final hadisItems = _repo.ofType(all, MultimediaType.hadis);
                    final wallpaperGrouped = _repo.groupByCategory(
                        _repo.ofType(all, MultimediaType.wallpaper));

                    return IndexedStack(
                      index: _selectedTab,
                      children: [
                        VideoTab(grouped: videoGrouped),
                        QuoteFeed(items: ayetItems),
                        QuoteFeed(items: hadisItems),
                        WallpaperTab(grouped: wallpaperGrouped),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
