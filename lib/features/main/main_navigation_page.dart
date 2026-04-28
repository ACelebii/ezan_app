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

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});
  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final syncNotifier = Provider.of<SyncNotifier>(context, listen: false);
      getIt<SyncManager>().init(syncNotifier);
      Workmanager().registerPeriodicTask("1", "syncTask",
          frequency: const Duration(hours: 1));

      syncNotifier.addListener(() {
        if (syncNotifier.state == SyncState.error) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text("Senkronizasyon hatası: ${syncNotifier.errorMessage}"),
            backgroundColor: Colors.red,
          ));
        } else if (syncNotifier.state == SyncState.success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Senkronizasyon başarılı!"),
            backgroundColor: Colors.green,
          ));
        }
      });
    });
  }

  List<Widget> get _pages => [
        const EzanVaktiPage(),
        const KuranPage(),
        const PusulaPage(),
        const ImsakiyePage(),
        MenuPage(
          onClose: () {
            setState(() {
              _currentIndex = 0;
            });
          },
        ),
      ];

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final authService = context.watch<AuthService>();

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _pages),
          Consumer<SyncNotifier>(
            builder: (context, syncNotifier, child) {
              if (syncNotifier.state == SyncState.syncing) {
                return Container(
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator()),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      bottomNavigationBar: IgnorePointer(
        ignoring: _currentIndex != 0,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          offset: _currentIndex == 0 ? Offset.zero : const Offset(0, 1.5),
          child: _buildCustomBottomBar(context, authService, isDark),
        ),
      ),
    );
  }

  Widget _buildCustomBottomBar(
      BuildContext context, AuthService authService, bool isDark) {
    Color activeColor = isDark ? Colors.yellow : Colors.orange.shade700;
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
