import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';
import 'auth_service.dart';

import 'vakitler_page.dart';
import 'kuran_page.dart';
import 'pusula_page.dart';
import 'imsakiye_page.dart';
import 'menu_page.dart';

// --- GLOBAL HAFIZA VE TEMA MOTORU ---
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);
final ValueNotifier<Map<String, dynamic>?> globalLocation = ValueNotifier(null);
String myApiKey = "";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  myApiKey = dotenv.env['OWM_API_KEY'] ?? '';
  await initializeDateFormatting('tr_TR', null);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (_, ThemeMode currentMode, __) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              brightness: Brightness.light,
              scaffoldBackgroundColor: const Color(0xFFF2F2F7),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
              ),
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: Colors.black,
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF031F1F),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
            themeMode: currentMode,
            home: const MainNavigationPage(),
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
      body: IndexedStack(index: _currentIndex, children: _pages),

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
                  ? activeColor.withOpacity(0.15)
                  : const Color(0xFF1E1E20);
            } else {
              itemBgColor =
                  isSelected ? activeColor.withOpacity(0.1) : Colors.white;
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
                            ? activeColor.withOpacity(isDark ? 0.5 : 0.3)
                            : (isDark
                                ? Colors.white10
                                : Colors.black.withOpacity(0.04)),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      boxShadow: [
                        if (!isDark) // Sadece aydınlık modda belirgin ve tatlı bir gölge
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
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
