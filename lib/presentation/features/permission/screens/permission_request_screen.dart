import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swipe_gallery/presentation/features/permission/providers/permission_provider.dart';
import 'package:swipe_gallery/theme/app_color_theme.dart';
import 'package:swipe_gallery/theme/app_text_theme.dart';

class PermissionRequestScreen extends ConsumerStatefulWidget {
  const PermissionRequestScreen({super.key, required this.status});

  final GalleryPermissionStatus status;

  @override
  ConsumerState<PermissionRequestScreen> createState() =>
      _PermissionRequestScreenState();
}

class _PermissionRequestScreenState
    extends ConsumerState<PermissionRequestScreen> {
  bool _requested = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_requested) return;
      _requested = true;
      // 화면 진입 후 안내 문구가 먼저 보이도록 약간의 지연을 둡니다.
      await Future<void>.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;
      ref.read(galleryPermissionNotifierProvider.notifier).requestPermission();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(galleryPermissionNotifierProvider.notifier);
    final showSettingsButton = widget.status.requiresSettings;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 3),
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: context.colors.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.photo_library_rounded,
                    size: 72,
                    color: context.colors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                '갤러리 접근 권한 안내',
                style: AppTextTheme.headlineMedium.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _buildDescription(context, widget.status),
              const SizedBox(height: 48),
              if (showSettingsButton)
                FilledButton(
                  onPressed: () => notifier.openSettings(),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: context.colors.primary,
                    foregroundColor: context.colors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('설정에서 권한 허용하기'),
                )
              else
                // 자동 요청 중이거나 needsRequest 상태일 때는 버튼을 최소화
                TextButton.icon(
                  onPressed: () => notifier.refreshStatus(),
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text('다시 시도'),
                  style: TextButton.styleFrom(
                    foregroundColor: context.colors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              const Spacer(flex: 4),
              const _PermissionFootnote(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescription(
    BuildContext context,
    GalleryPermissionStatus status,
  ) {
    final baseStyle = AppTextTheme.bodyLarge.copyWith(
      color: context.colors.textSecondary,
      height: 1.6,
    );

    String message;

    switch (status) {
      case GalleryPermissionStatus.needsRequest:
        message =
            '소중한 추억을 쓰윽 정리하기 위해\n갤러리 접근 권한이 필요해요.\n\n권한을 허용하면 최근 사진부터\n쉽고 빠르게 정리할 수 있습니다.';
        break;
      case GalleryPermissionStatus.denied:
        message = '사진 접근 권한이 거부되었습니다.\n\n원활한 서비스 이용을 위해\n앱 설정에서 권한을 허용해주세요.';
        break;
      case GalleryPermissionStatus.restricted:
        message = '사진 접근이 시스템에 의해 제한되었습니다.\n권한 설정 상태를 확인해주세요.';
        break;
      case GalleryPermissionStatus.granted:
      case GalleryPermissionStatus.limited:
        message = '잠시만 기다려주세요...';
        break;
    }

    return Text(message, style: baseStyle, textAlign: TextAlign.center);
  }
}

class _PermissionFootnote extends StatelessWidget {
  const _PermissionFootnote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: context.colors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                '안심하세요!',
                style: AppTextTheme.labelLarge.copyWith(
                  color: context.colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBulletPoint(context, '권한은 오직 사진 정리 기능에만 사용됩니다.'),
          const SizedBox(height: 8),
          _buildBulletPoint(context, '서버에 사진을 전송하거나 저장하지 않습니다.'),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(BuildContext context, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: context.colors.textSecondary.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
