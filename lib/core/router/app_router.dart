import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/overlay/presentation/screens/home_screen.dart';
import '../../features/overlay/presentation/screens/overlay_permission_screen.dart';
import '../../features/pets/domain/entities/pet_entity.dart';
import '../../features/pets/presentation/screens/add_pet_screen.dart';
import '../../features/pets/presentation/screens/custom_emoji_screen.dart';
import '../../features/pets/presentation/screens/pet_library_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/streak/presentation/screens/streak_history_screen.dart';
import '../../features/streak/presentation/screens/streak_screen.dart';
import '../../features/tasks/presentation/screens/tasks_screen.dart';

class AppRoutes {
  const AppRoutes._();

  static const home = '/';
  static const pets = '/pets';
  static const addPet = '/pets/add';
  static const addEmojiPet = '/pets/add-emoji';
  static const settings = '/settings';
  static const permission = '/permission';
  static const tasks = '/tasks';
  static const streak = '/streak';
  static const streakHistory = '/streak/history';
}

/// Shared fade+slide transition for every route, so navigation feels
/// consistent without touching each route's actual logic.
CustomTransitionPage<void> _page(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(path: AppRoutes.home, pageBuilder: (context, state) => _page(const HomeScreen(), state)),
    GoRoute(
      path: AppRoutes.pets,
      pageBuilder: (context, state) => _page(const PetLibraryScreen(), state),
      routes: [
        GoRoute(path: 'add', pageBuilder: (context, state) => _page(const AddPetScreen(), state)),
        GoRoute(
          path: 'add-emoji',
          pageBuilder: (context, state) => _page(CustomEmojiScreen(existingPet: state.extra as PetEntity?), state),
        ),
      ],
    ),
    GoRoute(path: AppRoutes.settings, pageBuilder: (context, state) => _page(const SettingsScreen(), state)),
    GoRoute(path: AppRoutes.permission, pageBuilder: (context, state) => _page(const OverlayPermissionScreen(), state)),
    GoRoute(path: AppRoutes.tasks, pageBuilder: (context, state) => _page(const TasksScreen(), state)),
    GoRoute(
      path: AppRoutes.streak,
      pageBuilder: (context, state) => _page(const StreakScreen(), state),
      routes: [GoRoute(path: 'history', pageBuilder: (context, state) => _page(const StreakHistoryScreen(), state))],
    ),
  ],
);
