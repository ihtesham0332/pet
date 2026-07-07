import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingState {
  final bool? completed;
  final bool isLoading;

  const OnboardingState({this.completed, this.isLoading = true});

  bool get isReady => completed != null;
}

class OnboardingProvider extends StateNotifier<OnboardingState> {
  OnboardingProvider() : super(const OnboardingState()) {
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool('onboarding_completed') ?? false;
    state = OnboardingState(completed: completed, isLoading: false);
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    state = OnboardingState(completed: true, isLoading: false);
  }

  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('onboarding_completed');
    state = OnboardingState(completed: false, isLoading: false);
  }
}

final onboardingProvider = StateNotifierProvider<OnboardingProvider, OnboardingState>((ref) {
  return OnboardingProvider();
});
