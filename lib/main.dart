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
import 'features/main/main_navigation_page.dart';
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
