import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pet_health_assistant/shared/providers/auth_provider.dart';
import 'package:pet_health_assistant/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:pet_health_assistant/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:pet_health_assistant/features/auth/presentation/screens/login_screen.dart';
import 'package:pet_health_assistant/features/auth/presentation/screens/register_screen.dart';
import 'package:pet_health_assistant/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:pet_health_assistant/features/pet/presentation/screens/pet_list_screen.dart';
import 'package:pet_health_assistant/features/pet/presentation/screens/pet_detail_screen.dart';
import 'package:pet_health_assistant/features/pet/presentation/screens/add_pet_screen.dart';
import 'package:pet_health_assistant/features/symptom_checker/presentation/screens/symptom_history_screen.dart';
import 'package:pet_health_assistant/features/symptom_checker/presentation/screens/symptom_input_screen.dart';
import 'package:pet_health_assistant/features/symptom_checker/presentation/screens/symptom_result_screen.dart';
import 'package:pet_health_assistant/features/symptom_checker/domain/symptom_result_entity.dart';
import 'package:pet_health_assistant/features/emergency/presentation/screens/emergency_screen.dart';
import 'package:pet_health_assistant/features/health_dashboard/presentation/screens/dashboard_screen.dart';
import 'package:pet_health_assistant/features/settings/presentation/screens/settings_screen.dart';
import 'package:pet_health_assistant/features/settings/presentation/screens/profile_screen.dart';
import 'package:pet_health_assistant/features/settings/presentation/screens/subscription_screen.dart';
import 'package:pet_health_assistant/features/settings/presentation/screens/legal_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final onboardingState = ref.watch(onboardingProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      if (authState.isLoading || !onboardingState.isReady) {
        if (state.matchedLocation != '/splash') return '/splash';
        return null;
      }

      final isLoggedIn = authState.isAuthenticated;
      final location = state.matchedLocation;
      final isOnboarding = location == '/onboarding';
      final isSplash = location == '/splash';
      final isAuthRoute = location.startsWith('/login') ||
          location.startsWith('/register') ||
          location.startsWith('/forgot-password');

      if (isSplash) {
        if (!onboardingState.completed!) return '/onboarding';
        return isLoggedIn ? '/pets' : '/login';
      }

      if (!onboardingState.completed! && !isOnboarding) return '/onboarding';
      if (onboardingState.completed! && isOnboarding) return '/login';

      if (!isLoggedIn && !isAuthRoute && !isOnboarding) return '/login';
      if (isLoggedIn && isAuthRoute) return '/pets';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (_, __) => const _SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
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
                  GoRoute(
                    path: 'symptom-history',
                    name: 'symptomHistory',
                    builder: (_, state) => SymptomHistoryScreen(
                      petId: state.pathParameters['petId']!,
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
              GoRoute(
                path: 'terms',
                name: 'terms',
                builder: (_, __) => const LegalScreen(type: 'terms'),
              ),
              GoRoute(
                path: 'privacy',
                name: 'privacy',
                builder: (_, __) => const LegalScreen(type: 'privacy'),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E7D32),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.pets, size: 52, color: Colors.white),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Pet Health Assistant',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'AI-Powered Pet Care',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 48),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

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
}
