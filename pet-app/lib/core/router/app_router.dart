import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pet_health_assistant/shared/providers/auth_provider.dart';
import 'package:pet_health_assistant/features/auth/presentation/screens/login_screen.dart';
import 'package:pet_health_assistant/features/auth/presentation/screens/register_screen.dart';
import 'package:pet_health_assistant/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:pet_health_assistant/features/pet/presentation/screens/pet_list_screen.dart';
import 'package:pet_health_assistant/features/pet/presentation/screens/pet_detail_screen.dart';
import 'package:pet_health_assistant/features/pet/presentation/screens/add_pet_screen.dart';
import 'package:pet_health_assistant/features/symptom_checker/presentation/screens/symptom_input_screen.dart';
import 'package:pet_health_assistant/features/symptom_checker/presentation/screens/symptom_result_screen.dart';
import 'package:pet_health_assistant/features/symptom_checker/domain/symptom_result_entity.dart';
import 'package:pet_health_assistant/features/emergency/presentation/screens/emergency_screen.dart';
import 'package:pet_health_assistant/features/health_dashboard/presentation/screens/dashboard_screen.dart';
import 'package:pet_health_assistant/features/settings/presentation/screens/settings_screen.dart';
import 'package:pet_health_assistant/features/settings/presentation/screens/profile_screen.dart';
import 'package:pet_health_assistant/features/settings/presentation/screens/subscription_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register') ||
          state.matchedLocation.startsWith('/forgot-password');

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/pets';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgotPassword',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/pets',
            name: 'petList',
            builder: (_, __) => const PetListScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: 'addPet',
                builder: (_, __) => const AddPetScreen(),
              ),
              GoRoute(
                path: ':petId',
                name: 'petDetail',
                builder: (_, state) => PetDetailScreen(
                  petId: state.pathParameters['petId']!,
                ),
                routes: [
                  GoRoute(
                    path: 'symptom-checker',
                    name: 'symptomChecker',
                    builder: (_, state) => SymptomInputScreen(
                      petId: state.pathParameters['petId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'symptom-result',
                    name: 'symptomResult',
                    builder: (_, state) => SymptomResultScreen(
                      result: state.extra as SymptomResultEntity,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/emergency',
            name: 'emergency',
            builder: (_, __) => const EmergencyScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (_, __) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'profile',
                name: 'profile',
                builder: (_, __) => const ProfileScreen(),
              ),
              GoRoute(
                path: 'subscription',
                name: 'subscription',
                builder: (_, __) => const SubscriptionScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateIndex(context),
        onDestinationSelected: (index) => _onTab(context, index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.pets), label: 'Pets'),
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Health'),
          NavigationDestination(icon: Icon(Icons.warning_amber), label: 'Emergency'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  int _calculateIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/pets')) return 0;
    if (location.startsWith('/dashboard')) return 1;
    if (location.startsWith('/emergency')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  void _onTab(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/pets');
      case 1: context.go('/dashboard');
      case 2: context.go('/emergency');
      case 3: context.go('/settings');
    }
  }
}
