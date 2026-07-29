import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'features/main/main_navigation_page.dart';
import 'features/menu/menu_page.dart';

import 'features/kutuphane/kutuphane_page.dart';
import 'features/kutuphane/kutuphane_icerik_page.dart';
import 'features/kutuphane/kutuphane_pdf_page.dart';
import 'features/kutuphane/kutuphane_model.dart';

import 'features/dini_gunler/dini_gunler_page.dart';
import 'features/dini_gunler/dini_gunler_model.dart';

import 'features/dualar/dualar_page.dart';
import 'features/dualar/dua_detail_page.dart';
import 'features/dualar/dualar_model.dart';

import 'features/kuran/kuran_page.dart';
import 'features/kuran/surah_detail_page.dart';
import 'features/kuran/providers/kuran_provider.dart';

import 'features/pusula/pusula_page.dart';
import 'features/pusula/qibla_map_page.dart';

import 'features/vakitler/vakitler_page.dart' show VakitlerCitySearchPage;

import 'features/imsakiye/imsakiye_page.dart';
import 'features/camiler/cami_page.dart';
import 'features/ajanda/ajanda_timeline_page.dart';
import 'features/Kazalar/kazalar_page.dart';

import 'features/zikirmatik/zikirmatik_page.dart';
import 'features/hutbe/hutbe_page.dart';

import 'features/hatim/hatim_page.dart';
import 'features/hatim/hatim_selection_page.dart';
import 'features/hatim/my_tasks_page.dart';

import 'features/settings/settings_page.dart';
import 'features/settings/theme_selector_page.dart';
import 'features/settings/cities_page.dart';
import 'features/settings/city_search_page.dart';
import 'features/settings/add_city_preview_page.dart';
import 'features/settings/hatirlaticilar_page.dart';
import 'features/settings/vaktinde_kil_page.dart';
import 'features/settings/vaktinde_kil_detay_page.dart';
import 'features/settings/vakit_settings_page.dart';
import 'features/settings/sound_selection_page.dart';
import 'features/settings/hesabim_login_page.dart';
import 'features/settings/register_page.dart';
import 'features/settings/forgot_password_page.dart';
import 'features/settings/tarih_sec_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const MainNavigationPage()),
    GoRoute(
        path: '/menu',
        builder: (context, state) => MenuPage(onClose: () => context.pop())),

    // --- Kütüphane ---
    GoRoute(
        path: '/kutuphane', builder: (context, state) => const KutuphanePage()),
    GoRoute(
        path: '/kutuphane/icerik',
        builder: (context, state) =>
            KutuphaneIcerikPage(node: state.extra as LibraryNode)),
    GoRoute(
        path: '/kutuphane/pdf',
        builder: (context, state) =>
            KutuphanePdfPage(item: state.extra as LibraryNode)),

    // --- Dini Günler ---
    GoRoute(
        path: '/dini-gunler',
        builder: (context, state) => const DiniGunlerPage()),
    GoRoute(
        path: '/dini-gunler/detay',
        builder: (context, state) =>
            DiniGunDetayPage(gunData: state.extra as DiniGunlerModel)),

    // --- Dualar ---
    GoRoute(
      path: '/dualar',
      builder: (context, state) => const DualarPage(),
      routes: [
        GoRoute(
          path: 'detail',
          builder: (context, state) {
            final dua = state.extra as DuaModel;
            return DuaDetailPage(dua: dua);
          },
        ),
      ],
    ),

    // --- Kuran ---
    GoRoute(path: '/kuran', builder: (context, state) => const KuranPage()),
    GoRoute(
        path: '/kuran/surah-detail',
        builder: (context, state) => ChangeNotifierProvider.value(
              value: state.extra as KuranProvider,
              child: const SurahDetailPage(),
            )),

    // --- Pusula ---
    GoRoute(path: '/pusula', builder: (context, state) => const PusulaPage()),
    GoRoute(
        path: '/pusula/qibla-map',
        builder: (context, state) => const QiblaMapPage()),

    // --- Vakitler (şehir arama) ---
    GoRoute(
        path: '/vakitler/city-search',
        builder: (context, state) => VakitlerCitySearchPage(
            isDark: state.extra as bool)),

    // --- İmsakiye / Camiler / Ajanda / Kazalar ---
    GoRoute(
        path: '/imsakiye', builder: (context, state) => const ImsakiyePage()),
    GoRoute(path: '/camiler', builder: (context, state) => const CamiPage()),
    GoRoute(
        path: '/ajanda',
        builder: (context, state) => const AjandaTimelinePage()),
    GoRoute(path: '/kazalar', builder: (context, state) => const KazalarPage()),

    // --- Zikirmatik ---
    GoRoute(
        path: '/zikirmatik', builder: (context, state) => const ZikirmatikPage()),
    GoRoute(
        path: '/zikirmatik/sayac',
        builder: (context, state) => ZikirmatikSayacPage(
            zikirData: state.extra as Map<String, dynamic>)),

    // --- Hutbe ---
    GoRoute(
        path: '/hutbe', builder: (context, state) => const HaftaninHutbesiPage()),
    GoRoute(
        path: '/hutbe/pdf',
        builder: (context, state) =>
            HutbePdfPage(hutbe: state.extra as HutbeItem)),

    // --- Hatim ---
    // HatimProvider artık root MultiProvider'da (main.dart) yaşıyor, bu
    // yüzden alt sayfalara `state.extra` ile ayrıca taşınmıyor.
    GoRoute(path: '/hatim', builder: (context, state) => const HatimPage()),
    GoRoute(
        path: '/hatim/my-tasks',
        builder: (context, state) => const MyTasksPage()),
    GoRoute(
        path: '/hatim/selection',
        builder: (context, state) {
          final args = state.extra as (String hatimId, String taskTitle);
          return HatimSelectionPage(hatimId: args.$1, taskTitle: args.$2);
        }),

    // --- Ayarlar ---
    GoRoute(
        path: '/settings', builder: (context, state) => const SettingsPage()),
    GoRoute(
        path: '/settings/theme',
        builder: (context, state) => const ThemeSelectorPage()),
    GoRoute(
        path: '/settings/tarih-sec',
        builder: (context, state) => const TarihSecPage()),
    GoRoute(
        path: '/settings/hatirlaticilar',
        builder: (context, state) => const HatirlaticilarPage()),
    GoRoute(
        path: '/settings/vaktinde-kil',
        builder: (context, state) => const VaktindeKilPage()),
    GoRoute(
        path: '/settings/vaktinde-kil/detay',
        builder: (context, state) =>
            VaktindeKilDetayPage(vakitAdi: state.extra as String)),
    GoRoute(
        path: '/settings/vakit',
        builder: (context, state) =>
            VakitSettingsPage(vakitAdi: state.extra as String)),
    GoRoute(
        path: '/settings/ses-secimi',
        builder: (context, state) =>
            SoundSelectionPage(mevcutSes: state.extra as String)),
    GoRoute(
        path: '/settings/hesabim',
        builder: (context, state) => const HesabimLoginPage()),
    GoRoute(
        path: '/settings/hesabim/kayit',
        builder: (context, state) => const RegisterPage()),
    GoRoute(
        path: '/settings/hesabim/sifremi-unuttum',
        builder: (context, state) => const ForgotPasswordPage()),
    GoRoute(
        path: '/settings/cities',
        builder: (context, state) => const CitiesPage()),
    GoRoute(
        path: '/settings/cities/search',
        builder: (context, state) => const CitySearchPage()),
    GoRoute(
        path: '/settings/cities/add-preview',
        builder: (context, state) =>
            AddCityPreviewPage(baslangicSehri: state.extra as String)),
  ],
);
