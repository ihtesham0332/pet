import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

enum AiProviderType { local, cloud, auto }

class AiSettingsNotifier extends StateNotifier<AiSettingsState> {
  AiSettingsNotifier() : super(AiSettingsState.initial());

  Future<void> checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    state = state.copyWith(
      isOnline: result != ConnectivityResult.none,
      activeProvider: state.mode == AiProviderType.auto
          ? (result != ConnectivityResult.none ? AiProviderType.cloud : AiProviderType.local)
          : state.mode,
    );
  }

  void setMode(AiProviderType mode) {
    state = state.copyWith(mode: mode, activeProvider: mode);
  }

  void toggleLocal() {
    final newMode = state.activeProvider == AiProviderType.local
        ? AiProviderType.cloud
        : AiProviderType.local;
    state = state.copyWith(mode: newMode, activeProvider: newMode);
  }
}

class AiSettingsState {
  final AiProviderType mode;
  final AiProviderType activeProvider;
  final bool isOnline;

  const AiSettingsState({
    this.mode = AiProviderType.auto,
    this.activeProvider = AiProviderType.local,
    this.isOnline = true,
  });

  factory AiSettingsState.initial() => const AiSettingsState();

  AiSettingsState copyWith({
    AiProviderType? mode,
    AiProviderType? activeProvider,
    bool? isOnline,
  }) {
    return AiSettingsState(
      mode: mode ?? this.mode,
      activeProvider: activeProvider ?? this.activeProvider,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  bool get useLocalAI => activeProvider == AiProviderType.local;
}

final aiSettingsProvider = StateNotifierProvider<AiSettingsNotifier, AiSettingsState>((ref) {
  return AiSettingsNotifier();
});
