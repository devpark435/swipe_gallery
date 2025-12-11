import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swipe_gallery/presentation/features/permission/providers/permission_provider.dart';
import 'package:swipe_gallery/presentation/features/permission/screens/permission_request_screen.dart';
import 'package:swipe_gallery/presentation/features/onboarding/onboarding_provider.dart';
import 'package:swipe_gallery/presentation/features/onboarding/onboarding_screen.dart';
import 'package:swipe_gallery/theme/app_color_theme.dart';

class PermissionGate extends ConsumerWidget {
  const PermissionGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permission = ref.watch(galleryPermissionNotifierProvider);

    return permission.when(
      data: (status) {
        if (status.isGranted) {
          return _OnboardingGate(child: child);
        }
        return PermissionRequestScreen(status: status);
      },
      loading:
          () => PermissionRequestScreen(
            status: GalleryPermissionStatus.needsRequest,
          ),
      error:
          (error, stackTrace) => _PermissionErrorView(
            onRetry: () {
              ref
                  .read(galleryPermissionNotifierProvider.notifier)
                  .refreshStatus();
            },
          ),
    );
  }
}

class _PermissionErrorView extends StatelessWidget {
  const _PermissionErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColorTheme.error),
            const SizedBox(height: 16),
            Text(
              '권한 상태를 확인하는 중 오류가 발생했어요.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColorTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              '네트워크 상태를 확인한 뒤 다시 시도해주세요.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColorTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingGate extends ConsumerWidget {
  const _OnboardingGate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboarding = ref.watch(onboardingControllerProvider);

    return onboarding.when(
      data: (seen) {
        if (seen) {
          return child;
        }
        return OnboardingScreen();
      },
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error:
          (error, stack) => Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColorTheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '온보딩 정보를 불러오지 못했어요.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColorTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () {
                      final _ = ref.refresh(onboardingSeenProvider.future);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
