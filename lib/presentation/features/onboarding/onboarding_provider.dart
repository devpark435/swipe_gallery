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
      // [개발 모드] 온보딩 화면 UI 수정을 위해 무조건 false로 설정하여 항상 보이게 함
      // 배포 전이나 UI 수정 완료 후에는 아래 줄을 주석 처리하고 state = AsyncData(seen);을 사용하세요.
      state = const AsyncData(false); 
      // state = AsyncData(seen); // 원래 로직: 저장된 상태를 불러옴
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
