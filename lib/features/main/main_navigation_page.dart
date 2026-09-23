import '../../core/i18n/cevir.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import '../../locator.dart';
import '../auth/auth_service.dart';
import '../sync/sync_manager.dart';
import '../sync/sync_notifier.dart';
import '../vakitler/vakitler_page.dart';
import '../kuran/kuran_page.dart';
import '../pusula/pusula_page.dart';
import '../imsakiye/imsakiye_page.dart';
import '../menu/menu_page.dart';
import '../../core/services/notification_service.dart';
import '../hatirlaticilar/data/reminder_scheduler.dart';
import 'izin_akisi.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});
  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  /// Bir kez açılmış sekmeler. Sekmeler ilk açılışta oluşturulur: aksi halde
  /// Pusula'nın konum izni penceresi ve pusula sensörü, kimse Pusula'yı
  /// açmadan her uygulama açılışında çalışır.
  final _acilanSekmeler = <int>{0};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pages = [
      const EzanVaktiPage(),
      KuranPage(
        onBack: () {
          setState(() {
            _currentIndex = 0;
          });
        },
      ),
      PusulaPage(
        onBack: () {
          setState(() {
            _currentIndex = 0;
          });
        },
      ),
      ImsakiyePage(
        onBack: () {
          setState(() {
            _currentIndex = 0;
          });
        },
      ),
      MenuPage(
        onClose: () {
          setState(() {
            _currentIndex = 0;
          });
        },
      ),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final syncNotifier = Provider.of<SyncNotifier>(context, listen: false);
      getIt<SyncManager>().init(syncNotifier);
      Workmanager().registerPeriodicTask("1", "syncTask",
          frequency: const Duration(hours: 1));

      // SnackBar bildirimleri sadece hata olursa gösterilsin ki kullanıcı rahatsız olmasın
      syncNotifier.addListener(() {
        if (syncNotifier.state == SyncState.error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(context
                  .t("Senkronizasyon hatası: ${syncNotifier.errorMessage}")),
              backgroundColor: Colors.red,
            ));
          }
        }
      });

      _kurulumVeHatirlaticilariPlanla();
    });
  }

  Future<void> _kurulumVeHatirlaticilariPlanla() async {
    await NotificationService.instance.initialize();
    if (!mounted) return;
    await ilkAcilisIzinleriniIste(context);
    if (!mounted) return;
    final authService = Provider.of<AuthService>(context, listen: false);
    await ReminderScheduler.rescheduleAll(authService);
    await _arkaPlanYenilemesiniKaydet();
  }

  /// Uygulama günlerce açılmasa da bildirimlerin bitmemesi için 12 saatte bir
  /// (ağ varken) bildirimleri yenileyen arka plan görevi. `update`: sıklık
  /// değişirse uygulanır, mevcut sürenin zamanlaması sıfırlanmaz.
  Future<void> _arkaPlanYenilemesiniKaydet() async {
    try {
      await Workmanager().registerPeriodicTask(
        ReminderScheduler.arkaPlanGorevi,
        ReminderScheduler.arkaPlanGorevi,
        frequency: const Duration(hours: 12),
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      );
    } catch (e) {
      debugPrint("Bildirim yenileme görevi kaydedilemedi: $e");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final authService = Provider.of<AuthService>(context, listen: false);
      ReminderScheduler.rescheduleAll(authService);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    // Gökyüzü ana ekranı tema ne olursa olsun koyudur; alt menü de ona uyar
    // (menü yalnızca ana ekranda görünür).
    bool isDark = authService.anaSayfaStili == 'Gökyüzü' ||
        Theme.of(context).brightness == Brightness.dark;
    _acilanSekmeler.add(_currentIndex);

    return Scaffold(
      extendBody: true,
      // Stack ve Consumer KALDIRILDI! Artık uygulama açılırken kilitlenmeyecek!
      body: IndexedStack(index: _currentIndex, children: [
        for (var i = 0; i < _pages.length; i++)
          _acilanSekmeler.contains(i) ? _pages[i] : const SizedBox.shrink(),
      ]),
      bottomNavigationBar: IgnorePointer(
        ignoring: _currentIndex != 0,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          offset: _currentIndex == 0 ? Offset.zero : const Offset(0, 1.5),
          // Sayfalar kendi yönlerini ayarlar; alt menü de dile göre aynalanır.
          child: Directionality(
            textDirection: authService.uygulamaDili == "العربية"
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: _buildCustomBottomBar(context, authService, isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomBottomBar(
      BuildContext context, AuthService authService, bool isDark) {
    Color activeColor = isDark ? Colors.yellow : const Color(0xFF009688);
    Color inactiveIconColor = isDark ? Colors.white54 : Colors.black45;

    final items = [
      {'icon': Icons.access_time_filled, 'label': 'Vakitler'},
      {'icon': Icons.menu_book, 'label': 'Kuran'},
      {'icon': Icons.explore, 'label': 'Pusula'},
      {'icon': Icons.calendar_month, 'label': 'İmsakiye'},
      {'icon': Icons.more_horiz, 'label': 'Menü'},
    ];

    return SafeArea(
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20, top: 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(items.length, (index) {
            bool isSelected = _currentIndex == index;

            Color itemBgColor;
            if (isDark) {
              itemBgColor = isSelected
                  ? activeColor.withValues(alpha: 0.15)
                  : const Color(0xFF1E1E20);
            } else {
              itemBgColor = isSelected
                  ? activeColor.withValues(alpha: 0.1)
                  : Colors.white;
            }

            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal:
                        index == 0 || index == items.length - 1 ? 0 : 4),
                child: GestureDetector(
                  onTap: () => setState(() => _currentIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: itemBgColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? activeColor.withValues(alpha: isDark ? 0.5 : 0.3)
                            : (isDark
                                ? Colors.white10
                                : Colors.black.withValues(alpha: 0.04)),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      boxShadow: [
                        if (!isDark)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          items[index]['icon'] as IconData,
                          color: isSelected ? activeColor : inactiveIconColor,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          authService
                              .translate(items[index]['label'] as String),
                          style: TextStyle(
                            color: isSelected ? activeColor : inactiveIconColor,
                            fontSize: 10,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
