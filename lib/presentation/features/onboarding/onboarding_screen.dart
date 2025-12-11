import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swipe_gallery/presentation/features/onboarding/onboarding_provider.dart';
import 'package:swipe_gallery/theme/app_color_theme.dart';
import 'package:swipe_gallery/theme/app_text_theme.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(onboardingControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColorTheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              _Header(),
              const SizedBox(height: 32),
              _Card(
                icon: Icons.swipe,
                title: '스와이프로 정리 시작',
                description: '왼쪽은 삭제, 오른쪽은 넘기기.\n실수하면 바로 되돌릴 수 있어요.',
              ),
              const SizedBox(height: 16),
              _Card(
                icon: Icons.delete_outline_rounded,
                title: '휴지통에서 복구·삭제',
                description: '삭제된 사진은 먼저 휴지통으로 이동하고,\n한 번에 복구하거나 완전 삭제할 수 있어요.',
              ),
              const Spacer(),
              FilledButton(
                onPressed: () async {
                  await controller.complete();
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColorTheme.primary,
                  foregroundColor: AppColorTheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('시작하기'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '빠르게 정리하는\n스와이프 갤러리',
          style: AppTextTheme.headlineMedium.copyWith(
            color: AppColorTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '오래된 사진부터 확인하고, 스와이프로\n삭제/넘기기를 간단하게 시작해보세요.',
          style: AppTextTheme.bodyMedium.copyWith(
            color: AppColorTheme.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorTheme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColorTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColorTheme.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColorTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextTheme.bodyLarge.copyWith(
                    color: AppColorTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: AppTextTheme.bodyMedium.copyWith(
                    color: AppColorTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
