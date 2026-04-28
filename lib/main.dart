import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:workmanager/workmanager.dart';
import 'package:go_router/go_router.dart';

import 'firebase_options.dart';
import 'features/auth/auth_service.dart';
import 'core/theme/app_theme.dart';
import 'features/sync/sync_manager.dart';
import 'features/sync/sync_notifier.dart';
import 'features/kutuphane/data/kutuphane_repository.dart';
import 'features/kuran/kuran_download_service.dart';

import 'features/vakitler/vakitler_page.dart';
import 'features/kuran/kuran_page.dart';
import 'features/pusula/pusula_page.dart';
import 'features/imsakiye/imsakiye_page.dart';
import 'features/menu/menu_page.dart';
import 'locator.dart';
import 'routes.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final repo = KutuphaneRepository();
    await repo.refresh();
    await KuranDownloadService.refresh();
    return Future.value(true);
  });
}

// --- GLOBAL HAFIZA VE TEMA MOTORU ---
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);
final ValueNotifier<Map<String, dynamic>?> globalLocation = ValueNotifier(null);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env_production");
  await initializeDateFormatting('tr_TR', null);
  setupLocator();
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  debugPrint("Firebase initializing...");
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("Firebase initialized.");
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          final auth = AuthService();
          auth.setApiKey(dotenv.env['OWM_API_KEY'] ?? '');
          return auth;
        }),
        ChangeNotifierProvider(create: (_) => SyncNotifier()),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (_, ThemeMode currentMode, __) {
          return MaterialApp.router(
            routerConfig: appRouter,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: currentMode,
          );
        },
      ),
    ),
  );
}

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

  // Sayfa Listesi
  List<Widget> get _pages => [
        const EzanVaktiPage(),
        const KuranPage(),
        const PusulaPage(),
        const ImsakiyePage(),
        MenuPage(
          onClose: () {
            setState(() {
              _currentIndex = 0; // X'e basıldığında Vakitler'e dön
            });
          },
        ),
      ];

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final authService = context.watch<AuthService>();

    return Scaffold(
      // extendBody: true sayesinde alt menü kaybolduğunda siyah boşluk kalmaz, sayfa tam ekran olur.
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

      // Sadece Vakitler (index 0) ekranındayken görünür. Diğer sayfalarda aşağı doğru kayarak gizlenir.
      bottomNavigationBar: IgnorePointer(
        ignoring: _currentIndex != 0, // Gizliyken tıklanmaları engelle
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          offset: _currentIndex == 0 ? Offset.zero : const Offset(0, 1.5),
          child: _buildCustomBottomBar(context, authService, isDark),
        ),
      ),
    );
  }

  // ==========================================================================
  // YENİ BAĞIMSIZ VE YÜZEN ALT MENÜ (UI GELİŞTİRMESİ)
  // ==========================================================================
  Widget _buildCustomBottomBar(
      BuildContext context, AuthService authService, bool isDark) {
    // Tasarım Renkleri
    Color activeColor = isDark ? Colors.yellow : Colors.orange.shade700;
    Color inactiveIconColor = isDark ? Colors.white54 : Colors.black45;

    // Menü İçerikleri
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

            // Arka plan rengi ayarlamaları (Karanlık için antrasit gri, aydınlık için beyaz/hafif renkli)
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
                // Butonlar birbirine çok yapışmasın diye ortadakilere hafif boşluk verdik
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
                        if (!isDark) // Sadece aydınlık modda belirgin ve tatlı bir gölge
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
