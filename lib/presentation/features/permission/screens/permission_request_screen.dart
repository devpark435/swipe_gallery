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
      // 문구가 먼저 보이도록 약간 지연 후 요청
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      ref.read(galleryPermissionNotifierProvider.notifier).requestPermission();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(galleryPermissionNotifierProvider.notifier);
    final textTheme = Theme.of(context).textTheme;
    final showSettingsButton = widget.status.requiresSettings;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                Icons.photo_library_rounded,
                size: 96,
                color: AppColorTheme.primary,
              ),
              const SizedBox(height: 32),
              Text(
                '사진 접근 권한이 필요해요',
                style: AppTextTheme.headlineMedium.copyWith(
                  color: AppColorTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _buildDescription(textTheme, widget.status),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: () => notifier.requestPermission(),
                child: const Text('권한 허용하기'),
              ),
              if (showSettingsButton) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => notifier.openSettings(),
                  child: const Text('설정에서 권한 허용'),
                ),
              ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => notifier.refreshStatus(),
                child: const Text('권한 상태 다시 확인'),
              ),
              const Spacer(),
              _PermissionFootnote(textTheme: textTheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescription(
    TextTheme textTheme,
    GalleryPermissionStatus status,
  ) {
    final baseStyle = AppTextTheme.bodyMedium.copyWith(
      color: AppColorTheme.textSecondary,
    );

    String message;

    switch (status) {
      case GalleryPermissionStatus.needsRequest:
        message =
            '스와이프 갤러리를 시작하기 이전에 사진 접근 권한이 필요합니다.\n허용을 누르면 스와이프 갤러리를 시작할 수 있어요.';
        break;
      case GalleryPermissionStatus.denied:
        message = '권한이 거부되어 사진을 불러올 수 없어요.\n설정에서 권한을 허용한 뒤 다시 시도해주세요.';
        break;
      case GalleryPermissionStatus.restricted:
        message = '시스템에서 사진 접근이 제한되어 있어요.\n필요한 경우 관리자에게 권한을 요청해 주세요.';
        break;
      case GalleryPermissionStatus.granted:
      case GalleryPermissionStatus.limited:
        message = '';
        break;
    }

    return Text(message, style: baseStyle, textAlign: TextAlign.center);
  }
}

class _PermissionFootnote extends StatelessWidget {
  const _PermissionFootnote({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• 권한은 사진 정리 기능에만 사용되며 서버에 전송되지 않습니다.',
          style: textTheme.bodySmall?.copyWith(
            color: AppColorTheme.textSecondary.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '• 언제든지 휴지통에서 사진을 복원하거나 삭제할 수 있습니다.',
          style: textTheme.bodySmall?.copyWith(
            color: AppColorTheme.textSecondary.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
