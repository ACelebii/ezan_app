import 'package:go_router/go_router.dart';
import 'features/main/main_navigation_page.dart';
import 'features/settings/theme_selector_page.dart';
import 'features/menu/menu_page.dart';
import 'features/kutuphane/kutuphane_page.dart';
import 'features/dini_gunler/dini_gunler_page.dart';
import 'features/dualar/dualar_page.dart';
import 'features/dualar/dua_detail_page.dart';
import 'features/dualar/dualar_model.dart'; // DuaModel importu eklendi

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const MainNavigationPage()),
    GoRoute(
        path: '/settings/theme',
        builder: (context, state) => const ThemeSelectorPage()),

    // MenuPage'in onClose parametresi eklendi
    GoRoute(
        path: '/menu',
        builder: (context, state) => MenuPage(onClose: () => context.pop())),

    GoRoute(
        path: '/kutuphane', builder: (context, state) => const KutuphanePage()),
    GoRoute(
        path: '/dini-gunler',
        builder: (context, state) => const DiniGunlerPage()),
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
  ],
);
