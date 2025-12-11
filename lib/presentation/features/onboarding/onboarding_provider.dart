import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _onboardingSeenKey = 'onboarding_seen';

final onboardingSeenProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_onboardingSeenKey) ?? false;
});

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, AsyncValue<bool>>(
      (ref) => OnboardingController(ref),
    );

class OnboardingController extends StateNotifier<AsyncValue<bool>> {
  OnboardingController(this._ref) : super(const AsyncLoading()) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    try {
      final seen = await _ref.read(onboardingSeenProvider.future);
      state = AsyncData(seen);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> complete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingSeenKey, true);
      state = const AsyncData(true);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}
