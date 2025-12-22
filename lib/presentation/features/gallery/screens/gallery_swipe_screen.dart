import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:swipe_gallery/data/models/gallery/gallery_exception.dart';
import 'package:swipe_gallery/data/models/gallery/gallery_state.dart';
import 'package:swipe_gallery/data/models/gallery/photo_model.dart';
import 'package:swipe_gallery/data/services/gallery/gallery_service.dart';
import 'package:swipe_gallery/presentation/features/gallery/providers/gallery_provider.dart';
import 'package:swipe_gallery/presentation/features/gallery/screens/ai_recommendation_screen.dart';
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
  final List<({PhotoModel photo, bool isRemove})> _actionHistory = [];

  void _undoAction() {
    if (_actionHistory.isEmpty) return;

    final lastAction = _actionHistory.removeLast();
    final photo = lastAction.photo;
    final isRemove = lastAction.isRemove;

    final notifier = ref.read(galleryNotifierProvider.notifier);
    if (isRemove) {
      notifier.restorePhotos([photo.id]);
    } else {
      notifier.reAddPhoto(photo);
    }

    setState(() {});
  }

  String _getKoreanAlbumName(AssetPathEntity album) {
    if (album.isAll) return '최근 항목';

    final name = album.name.toLowerCase();
    if (name.contains('camera')) return '카메라';
    if (name.contains('screenshot')) return '스크린샷';
    if (name.contains('download')) return '다운로드';
    if (name.contains('favorite')) return '즐겨찾기';
    if (name.contains('instagram')) return '인스타그램';
    if (name.contains('kakaotalk')) return '카카오톡';

    return album.name;
  }

  Widget _buildAiRecommendationItem(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colors.primary.withOpacity(0.15),
            context.colors.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.colors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.pop(context);
            // AI 추천 화면으로 이동
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AiRecommendationScreen(),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: context.colors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: context.colors.primary.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI 추천 정리',
                        style: AppTextTheme.headlineMedium.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '비슷한 사진들을 모아서\n똑똑하게 정리해보세요 ✨',
                        style: AppTextTheme.bodyMedium.copyWith(
                          color: context.colors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: context.colors.primary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAlbumSelector(BuildContext context) async {
    final albums = await ref.read(galleryServiceProvider).fetchAlbums();
    // 현재 선택된 앨범 ID 가져오기
    final currentAlbumId =
        ref.read(galleryNotifierProvider).valueOrNull?.selectedAlbumId;

    if (!mounted) return;

    final selectedAlbum = await showModalBottomSheet<AssetPathEntity>(
      context: context,
      backgroundColor: context.colors.surface,
      isScrollControlled: true, // 높이 조절을 위해
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7, // 조금 더 키움
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.colors.border.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Row(
                    children: [
                      Text(
                        '앨범 선택',
                        style: AppTextTheme.headlineMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: context.colors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${albums.length}개의 앨범',
                          style: AppTextTheme.labelMedium.copyWith(
                            color: context.colors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.only(bottom: 32),
                    children: [
                      _buildAiRecommendationItem(context),
                      if (albums.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          child: Text(
                            '나의 앨범',
                            style: AppTextTheme.labelLarge.copyWith(
                              color: context.colors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ...albums.map((album) {
                        final isSelected = album.id == currentAlbumId;
                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? context.colors.primary.withOpacity(0.08)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => Navigator.pop(context, album),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: context.colors.background,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: context.colors.border,
                                          width: 1,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        album.isAll
                                            ? Icons.photo_library_rounded
                                            : Icons.folder_rounded,
                                        color:
                                            isSelected
                                                ? context.colors.primary
                                                : context.colors.textSecondary,
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _getKoreanAlbumName(album),
                                            style: AppTextTheme.bodyLarge
                                                .copyWith(
                                                  color:
                                                      isSelected
                                                          ? context
                                                              .colors
                                                              .primary
                                                          : context
                                                              .colors
                                                              .textPrimary,
                                                  fontWeight:
                                                      isSelected
                                                          ? FontWeight.bold
                                                          : FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          FutureBuilder<int>(
                                            future: album.assetCountAsync,
                                            builder: (context, snapshot) {
                                              return Text(
                                                '${snapshot.data ?? 0}장',
                                                style: AppTextTheme.bodyMedium
                                                    .copyWith(
                                                      color:
                                                          context
                                                              .colors
                                                              .textSecondary,
                                                      fontSize: 13,
                                                    ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle_rounded,
                                        color: context.colors.primary,
                                        size: 24,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (selectedAlbum != null) {
      ref.read(galleryNotifierProvider.notifier).selectAlbum(selectedAlbum);
    }
  }

  @override
  Widget build(BuildContext context) {
    final galleryState = ref.watch(galleryNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: GestureDetector(
          onTap: () => _showAlbumSelector(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '쓰윽',
                style: AppTextTheme.headlineMedium.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: context.colors.textPrimary,
                size: 24,
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _actionHistory.isNotEmpty ? _undoAction : null,
            icon: Icon(
              Icons.undo_rounded,
              color:
                  _actionHistory.isNotEmpty
                      ? context.colors.textPrimary
                      : context.colors.textSecondary.withOpacity(0.3),
              size: 20,
            ),
            label: Text(
              '되돌리기',
              style: AppTextTheme.labelLarge.copyWith(
                color:
                    _actionHistory.isNotEmpty
                        ? context.colors.textPrimary
                        : context.colors.textSecondary.withOpacity(0.3),
                fontWeight: FontWeight.bold,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
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
                  setState(() {
                    _actionHistory.add((photo: photo, isRemove: true));
                  });
                },
                onPass: (photo) {
                  ref.read(galleryNotifierProvider.notifier).passPhoto(photo);
                  setState(() {
                    _actionHistory.add((photo: photo, isRemove: false));
                  });
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
                '남은 사진 ${gallery.remainingCount}장 / 전체 ${gallery.totalCount}장',
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
          color: context.colors.primary,
        ),
        const SizedBox(width: 8),
        Text(
          '넘기기',
          style: AppTextTheme.bodyMedium.copyWith(
            color: context.colors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 24),
        Container(width: 1, height: 16, color: context.colors.border),
        const SizedBox(width: 24),
        Text(
          '삭제',
          style: AppTextTheme.bodyMedium.copyWith(
            color: context.colors.error,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: context.colors.error,
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
          // 오른쪽에서 왼쪽으로 스와이프 (Left Swipe) -> 넘기기 (Pass)
          onPass(photo);
        } else if (direction == DismissDirection.startToEnd) {
          // 왼쪽에서 오른쪽으로 스와이프 (Right Swipe) -> 삭제 (Remove)
          onRemove(photo);
        }
      },
      background: _SwipeActionBackground(
        alignment: Alignment.centerLeft,
        color: context.colors.error,
        icon: Icons.delete_outline_rounded,
        label: '삭제',
      ),
      secondaryBackground: _SwipeActionBackground(
        alignment: Alignment.centerRight,
        color: context.colors.primary,
        icon: Icons.check_rounded,
        label: '넘기기',
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
}

class _GalleryEmpty extends ConsumerWidget {
  const _GalleryEmpty({required this.hasTrash, required this.onOpenTrash});

  final bool hasTrash;
  final VoidCallback onOpenTrash;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              ref.read(galleryNotifierProvider.notifier).resetAllPassedPhotos();
            },
            icon: const Icon(Icons.replay_rounded, size: 20),
            label: const Text('처음부터 다시 보기'),
            style: TextButton.styleFrom(
              foregroundColor: context.colors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
