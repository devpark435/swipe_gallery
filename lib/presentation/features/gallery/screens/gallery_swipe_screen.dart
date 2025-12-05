import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:pocket_photo/data/models/gallery/gallery_exception.dart';
import 'package:pocket_photo/data/models/gallery/gallery_state.dart';
import 'package:pocket_photo/data/models/gallery/photo_model.dart';
import 'package:pocket_photo/presentation/features/gallery/providers/gallery_provider.dart';
import 'package:pocket_photo/presentation/shared/widgets/cards/photo_swipe_card.dart';
import 'package:pocket_photo/router/app_router.dart';
import 'package:pocket_photo/theme/app_color_theme.dart';
import 'package:pocket_photo/theme/app_text_theme.dart';

class GallerySwipeScreen extends ConsumerStatefulWidget {
  const GallerySwipeScreen({super.key});

  @override
  ConsumerState<GallerySwipeScreen> createState() => _GallerySwipeScreenState();
}

class _GallerySwipeScreenState extends ConsumerState<GallerySwipeScreen> {
  @override
  Widget build(BuildContext context) {
    final galleryState = ref.watch(galleryNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '오늘의 갤러리',
          style: AppTextTheme.headlineMedium.copyWith(
            color: AppColorTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ref.read(galleryNotifierProvider.notifier).refresh();
            },
            icon: const Icon(Icons.refresh),
            tooltip: '사진 새로고침',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: galleryState.when(
            data:
                (gallery) => _GalleryContent(
                  gallery: gallery,
                  onRemove: (photo) {
                    ref
                        .read(galleryNotifierProvider.notifier)
                        .removePhoto(photo.id);
                  },
                  onPass: (photo) {
                    ref.read(galleryNotifierProvider.notifier).passPhoto(photo);
                  },
                  onOpenTrash: () => context.goNamed(AppRoute.trash.name),
                ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (error, stackTrace) => _GalleryError(
                  isPermissionDenied: error is GalleryPermissionException,
                  onRetry: () {
                    ref.read(galleryNotifierProvider.notifier).refresh();
                  },
                ),
          ),
        ),
      ),
    );
  }
}

class _GalleryContent extends StatelessWidget {
  const _GalleryContent({
    required this.gallery,
    required this.onRemove,
    required this.onPass,
    required this.onOpenTrash,
  });

  final GalleryState gallery;
  final ValueChanged<PhotoModel> onRemove;
  final ValueChanged<PhotoModel> onPass;
  final VoidCallback onOpenTrash;

  @override
  Widget build(BuildContext context) {
    final photos = gallery.active;

    if (photos.isEmpty) {
      return _GalleryEmpty(
        hasTrash: gallery.hasTrash,
        onOpenTrash: onOpenTrash,
      );
    }

    final mediaSize = MediaQuery.sizeOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          '스와이프로 다음 사진을 확인하세요',
          style: AppTextTheme.bodyMedium.copyWith(
            color: AppColorTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '좌 ',
                style: AppTextTheme.bodyLarge.copyWith(
                  color: AppColorTheme.error,
                ),
              ),
              TextSpan(
                text: '삭제 · ',
                style: AppTextTheme.bodyMedium.copyWith(
                  color: AppColorTheme.textSecondary,
                ),
              ),
              TextSpan(
                text: '우 ',
                style: AppTextTheme.bodyLarge.copyWith(
                  color: AppColorTheme.primary,
                ),
              ),
              TextSpan(
                text: '패스',
                style: AppTextTheme.bodyMedium.copyWith(
                  color: AppColorTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Center(
            child: SizedBox(
              height: mediaSize.height * 0.6,
              child: _SwipeDeck(
                photos: photos,
                onRemove: onRemove,
                onPass: onPass,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '남은 사진 ${photos.length}장',
          style: AppTextTheme.bodyMedium.copyWith(
            color: AppColorTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SwipeDeck extends StatelessWidget {
  const _SwipeDeck({
    required this.photos,
    required this.onRemove,
    required this.onPass,
  });

  final List<PhotoModel> photos;
  final ValueChanged<PhotoModel> onRemove;
  final ValueChanged<PhotoModel> onPass;

  @override
  Widget build(BuildContext context) {
    final visiblePhotos = photos.take(3).toList();

    return Stack(
      alignment: Alignment.center,
      children: [
        for (var i = visiblePhotos.length - 1; i >= 0; i--)
          Positioned.fill(
            top: i * 12,
            bottom: i * 12,
            child: Transform.translate(
              offset: Offset(0, i * 8),
              child: Transform.scale(
                scale: 1 - (i * 0.04),
                child:
                    i == 0
                        ? _SwipeableCard(
                          photo: visiblePhotos[i],
                          onRemove: onRemove,
                          onPass: onPass,
                        )
                        : IgnorePointer(
                          child: PhotoSwipeCard(photo: visiblePhotos[i]),
                        ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SwipeableCard extends StatelessWidget {
  const _SwipeableCard({
    required this.photo,
    required this.onRemove,
    required this.onPass,
  });

  final PhotoModel photo;
  final ValueChanged<PhotoModel> onRemove;
  final ValueChanged<PhotoModel> onPass;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(photo.id),
      direction: DismissDirection.horizontal,
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onRemove(photo);
          _showToast(
            context,
            message: '사진이 휴지통으로 이동했어요.',
            background: AppColorTheme.error,
          );
        } else if (direction == DismissDirection.startToEnd) {
          onPass(photo);
          _showToast(
            context,
            message: '패스한 사진을 숨겼어요.',
            background: AppColorTheme.primary,
          );
        }
      },
      background: _SwipeActionBackground(
        alignment: Alignment.centerLeft,
        color: AppColorTheme.primary.withOpacity(0.9),
        icon: Icons.arrow_forward_rounded,
        label: '패스',
      ),
      secondaryBackground: _SwipeActionBackground(
        alignment: Alignment.centerRight,
        color: AppColorTheme.error.withOpacity(0.9),
        icon: Icons.delete_outline,
        label: '삭제',
      ),
      child: PhotoSwipeCard(photo: photo),
    );
  }

  void _showToast(
    BuildContext context, {
    required String message,
    required Color background,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: AppTextTheme.labelLarge),
          backgroundColor: background,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _GalleryEmpty extends StatelessWidget {
  const _GalleryEmpty({required this.hasTrash, required this.onOpenTrash});

  final bool hasTrash;
  final VoidCallback onOpenTrash;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            color: AppColorTheme.textSecondary.withOpacity(0.5),
            size: 72,
          ),
          const SizedBox(height: 16),
          Text(
            '갤러리에 표시할 사진이 없어요.',
            style: AppTextTheme.headlineMedium.copyWith(
              color: AppColorTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            hasTrash
                ? '휴지통에서 사진을 복원하면 다시 볼 수 있어요.'
                : '사진 앱에 이미지를 추가하면 여기에서 확인할 수 있어요.',
            style: AppTextTheme.bodyMedium.copyWith(
              color: AppColorTheme.textSecondary.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: onOpenTrash,
            icon: const Icon(Icons.delete_outline),
            label: const Text('휴지통 열기'),
          ),
        ],
      ),
    );
  }
}

class _SwipeActionBackground extends StatelessWidget {
  const _SwipeActionBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColorTheme.surface),
          const SizedBox(width: 8),
          Text(label, style: AppTextTheme.labelLarge),
        ],
      ),
    );
  }
}

class _GalleryError extends StatelessWidget {
  const _GalleryError({
    required this.onRetry,
    required this.isPermissionDenied,
  });

  final VoidCallback onRetry;
  final bool isPermissionDenied;

  @override
  Widget build(BuildContext context) {
    final title = isPermissionDenied ? '사진 접근 권한이 필요해요.' : '사진을 불러오지 못했어요.';
    final description =
        isPermissionDenied
            ? '설정에서 사진 접근 권한을 허용하면 갤러리를 다시 볼 수 있어요.'
            : '갤러리 정보를 불러오는 중 문제가 발생했어요. 다시 시도해주세요.';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPermissionDenied ? Icons.lock_outline : Icons.cloud_off_outlined,
            color: AppColorTheme.textSecondary.withOpacity(0.5),
            size: 72,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTextTheme.headlineMedium.copyWith(
              color: AppColorTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: AppTextTheme.bodyMedium.copyWith(
              color: AppColorTheme.textSecondary.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onRetry,
            label: const Text('다시 시도'),
            icon: const Icon(Icons.refresh),
          ),
          if (isPermissionDenied) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                await PhotoManager.openSetting();
              },
              icon: const Icon(Icons.settings_outlined),
              label: const Text('설정에서 권한 허용하기'),
            ),
          ],
        ],
      ),
    );
  }
}
