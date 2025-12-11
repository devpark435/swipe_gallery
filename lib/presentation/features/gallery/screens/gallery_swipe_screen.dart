import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:swipe_gallery/data/models/gallery/gallery_exception.dart';
import 'package:swipe_gallery/data/models/gallery/gallery_state.dart';
import 'package:swipe_gallery/data/models/gallery/photo_model.dart';
import 'package:swipe_gallery/presentation/features/gallery/providers/gallery_provider.dart';
import 'package:swipe_gallery/presentation/shared/widgets/cards/photo_swipe_card.dart';
import 'package:swipe_gallery/router/app_router.dart';
import 'package:swipe_gallery/theme/app_color_theme.dart';
import 'package:swipe_gallery/theme/app_text_theme.dart';

class GallerySwipeScreen extends ConsumerStatefulWidget {
  const GallerySwipeScreen({super.key});

  @override
  ConsumerState<GallerySwipeScreen> createState() => _GallerySwipeScreenState();
}

class _GallerySwipeScreenState extends ConsumerState<GallerySwipeScreen> {
  PhotoModel? _lastActionPhoto;
  bool _lastActionWasRemove = false;

  void _showUndo(BuildContext context) {
    final photo = _lastActionPhoto;
    if (photo == null) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            _lastActionWasRemove ? '휴지통으로 이동했어요' : '사진을 넘겼어요',
            style: AppTextTheme.labelLarge,
          ),
          action: SnackBarAction(
            label: '되돌리기',
            textColor: context.colors.surface,
            onPressed: () {
              final notifier = ref.read(galleryNotifierProvider.notifier);
              if (_lastActionWasRemove) {
                notifier.restorePhotos([photo.id]);
              } else {
                notifier.reAddPhoto(photo);
              }
            },
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final galleryState = ref.watch(galleryNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          'Swipe Gallery',
          style: AppTextTheme.headlineMedium.copyWith(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ref.read(galleryNotifierProvider.notifier).refresh();
            },
            icon: const Icon(Icons.refresh_rounded),
            tooltip: '사진 새로고침',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: galleryState.when(
            data: (gallery) {
              return _GalleryContent(
                gallery: gallery,
                onRemove: (photo) {
                  ref
                      .read(galleryNotifierProvider.notifier)
                      .removePhoto(photo.id);
                  _lastActionPhoto = photo;
                  _lastActionWasRemove = true;
                  _showUndo(context);
                },
                onPass: (photo) {
                  ref.read(galleryNotifierProvider.notifier).passPhoto(photo);
                  _lastActionPhoto = photo;
                  _lastActionWasRemove = false;
                  _showUndo(context);
                },
                onOpenTrash: () => context.goNamed(AppRoute.trash.name),
              );
            },
            loading: () => const _GallerySkeleton(),
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

class _GallerySkeleton extends StatefulWidget {
  const _GallerySkeleton();

  @override
  State<_GallerySkeleton> createState() => _GallerySkeletonState();
}

class _GallerySkeletonState extends State<_GallerySkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.05, end: 0.15).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final color = context.colors.textPrimary.withOpacity(_animation.value);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 120,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const Spacer(),
            Center(
              child: SizedBox(
                height: mediaSize.height * 0.62,
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 24),
                Container(
                  width: 1,
                  height: 16,
                  color: context.colors.border.withOpacity(0.5),
                ),
                const SizedBox(width: 24),
                Container(
                  width: 50,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        );
      },
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
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.colors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '남은 사진 ${photos.length}장',
                style: AppTextTheme.labelLarge.copyWith(
                  color: context.colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        Center(
          child: SizedBox(
            height: mediaSize.height * 0.62,
            child: _SwipeDeck(
              photos: photos,
              onRemove: onRemove,
              onPass: onPass,
            ),
          ),
        ),
        const Spacer(),
        _SwipeGuideText(),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SwipeGuideText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.arrow_back_ios_rounded,
          size: 16,
          color: context.colors.error,
        ),
        const SizedBox(width: 8),
        Text(
          '삭제',
          style: AppTextTheme.bodyMedium.copyWith(
            color: context.colors.error,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 24),
        Container(width: 1, height: 16, color: context.colors.border),
        const SizedBox(width: 24),
        Text(
          '넘기기',
          style: AppTextTheme.bodyMedium.copyWith(
            color: context.colors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: context.colors.primary,
        ),
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
    if (photos.isEmpty) {
      return const SizedBox.shrink();
    }

    // 가장 위에 있는 1장만 렌더링하여 레이아웃 단순화
    return _SwipeableCard(
      photo: photos.first,
      onRemove: onRemove,
      onPass: onPass,
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
            message: '사진이 휴지통으로 이동했어요',
            icon: Icons.delete_outline_rounded,
          );
        } else if (direction == DismissDirection.startToEnd) {
          onPass(photo);
        }
      },
      background: _SwipeActionBackground(
        alignment: Alignment.centerLeft,
        color: context.colors.primary,
        icon: Icons.check_rounded,
        label: '넘기기',
      ),
      secondaryBackground: _SwipeActionBackground(
        alignment: Alignment.centerRight,
        color: context.colors.error,
        icon: Icons.delete_outline_rounded,
        label: '삭제',
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: context.colors.textPrimary.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: PhotoSwipeCard(photo: photo),
      ),
    );
  }

  void _showToast(
    BuildContext context, {
    required String message,
    required IconData icon,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: context.colors.surface, size: 20),
              const SizedBox(width: 12),
              Text(message, style: AppTextTheme.labelLarge),
            ],
          ),
          backgroundColor: context.colors.textPrimary.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          elevation: 0,
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
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: context.colors.background,
              shape: BoxShape.circle,
              border: Border.all(color: context.colors.border),
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              color: context.colors.primary,
              size: 56,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '모든 사진을 확인했어요!',
            style: AppTextTheme.headlineMedium.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            hasTrash ? '휴지통에서 삭제한 사진을 정리해보세요.' : '새로운 사진이 추가되면\n여기서 알려드릴게요.',
            style: AppTextTheme.bodyMedium.copyWith(
              color: context.colors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (hasTrash)
            FilledButton.icon(
              onPressed: onOpenTrash,
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              label: const Text('휴지통 정리하기'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                backgroundColor: context.colors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
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
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(32),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      alignment: alignment,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextTheme.labelLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.colors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPermissionDenied
                  ? Icons.lock_outline_rounded
                  : Icons.cloud_off_rounded,
              color: context.colors.error,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isPermissionDenied ? '사진 접근 권한이 필요해요' : '사진을 불러오지 못했어요',
            style: AppTextTheme.headlineMedium.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            isPermissionDenied
                ? '설정에서 권한을 허용하면\n갤러리를 다시 볼 수 있어요.'
                : '일시적인 오류일 수 있어요.\n잠시 후 다시 시도해주세요.',
            style: AppTextTheme.bodyMedium.copyWith(
              color: context.colors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: onRetry,
            label: const Text('다시 시도'),
            icon: const Icon(Icons.refresh_rounded),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              backgroundColor: context.colors.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          if (isPermissionDenied) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () async {
                await PhotoManager.openSetting();
              },
              icon: const Icon(Icons.settings_outlined),
              label: const Text('설정으로 이동'),
              style: TextButton.styleFrom(
                foregroundColor: context.colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
