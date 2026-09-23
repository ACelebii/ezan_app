import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:workmanager/workmanager.dart';

import 'firebase_options.dart';
import 'features/auth/auth_service.dart';
import 'core/theme/app_theme.dart';
import 'features/sync/sync_notifier.dart';
import 'features/kutuphane/data/kutuphane_repository.dart';
import 'features/hutbe/data/hutbe_repository.dart';
import 'features/kuran/kuran_download_service.dart';
import 'features/hatim/hatim_provider.dart';
import 'features/hatirlaticilar/data/reminder_scheduler.dart';
import 'features/zikirmatik/zikirmatik_provider.dart';

import 'locator.dart';
import 'routes.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Bildirim yenileme görevi: Firebase'e/arayüze ihtiyaç duymaz, kendi
    // girdi kaydından çalışır.
    if (task == ReminderScheduler.arkaPlanGorevi) {
      try {
        return await ReminderScheduler.arkaPlandaYenile();
      } catch (e) {
        debugPrint("Arka plan bildirim yenileme hatası: $e");
        return false;
      }
    }
    // Her adım kendi try/catch'inde: biri başarısız olursa (ör. geçici ağ
    // hatası) diğerleri yine de çalışır ve arka plan görevi sessizce
    // tamamen ölmez (önceden try/catch hiç yoktu).
    try {
      await KutuphaneRepository().refresh();
    } catch (e) {
      debugPrint("Arka plan Kütüphane senkron hatası: $e");
    }
    try {
      await HutbeRepository().refresh();
    } catch (e) {
      debugPrint("Arka plan Hutbe senkron hatası: $e");
    }
    try {
      await KuranDownloadService.refresh();
    } catch (e) {
      debugPrint("Arka plan Kuran önbellek senkron hatası: $e");
    }
    return Future.value(true);
  });
}

// --- GLOBAL HAFIZA VE TEMA MOTORU ---
final ValueNotifier<Map<String, dynamic>?> globalLocation = ValueNotifier(null);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env_production");
  await initializeDateFormatting('tr_TR', null);
  await AppTheme.modYukle();
  setupLocator();
  Workmanager().initialize(callbackDispatcher);

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
        ChangeNotifierProxyProvider<AuthService, HatimProvider>(
          create: (_) => HatimProvider(),
          update: (_, auth, hatimProvider) {
            final provider = hatimProvider ?? HatimProvider();
            provider.onAuthChanged(auth.user?.uid);
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => ZikirmatikProvider()),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: AppTheme.mod,
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
