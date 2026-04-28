import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'features/vakitler/vakitler_page.dart';
import 'features/kuran/kuran_page.dart';
import 'features/pusula/pusula_page.dart';
import 'features/imsakiye/imsakiye_page.dart';
import 'features/menu/menu_page.dart';
import 'main.dart'; // Import MainNavigationPage

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MainNavigationPage(),
      routes: [
        // Define sub-routes if needed
      ],
    ),
  ],
);
