import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swipe_gallery/data/models/gallery/gallery_exception.dart';
import 'package:swipe_gallery/data/models/gallery/photo_model.dart';
import 'package:swipe_gallery/presentation/features/gallery/providers/gallery_provider.dart';
import 'package:swipe_gallery/theme/app_color_theme.dart';
import 'package:swipe_gallery/theme/app_text_theme.dart';

class TrashScreen extends ConsumerStatefulWidget {
  const TrashScreen({super.key});

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen> {
  final Set<String> _selectedIds = <String>{};

  ScaffoldMessengerState _messenger(BuildContext context) =>
      ScaffoldMessenger.of(context);

  bool get _hasSelection => _selectedIds.isNotEmpty;

  void _toggleSelection(PhotoModel photo) {
    setState(() {
      if (_selectedIds.contains(photo.id)) {
        _selectedIds.remove(photo.id);
      } else {
        _selectedIds.add(photo.id);
      }
    });
  }

  void _selectAll(List<PhotoModel> photos) {
    setState(() {
      if (_selectedIds.length == photos.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(photos.map((p) => p.id));
      }
    });
  }

  void _clearSelection() {
    if (!_hasSelection) {
      return;
    }
    setState(() => _selectedIds.clear());
  }

  Future<void> _restoreSelected(BuildContext context) async {
    if (!_hasSelection) {
      return;
    }

    final ids = _selectedIds.toList(growable: false);
    ref.read(galleryNotifierProvider.notifier).restorePhotos(ids);
    final restoredCount = ids.length;
    setState(() => _selectedIds.clear());

    _messenger(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Text('사진 $restoredCount장을 복원했어요', style: AppTextTheme.labelLarge),
            ],
          ),
          backgroundColor: AppColorTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  Future<void> _deleteSelected(BuildContext context) async {
    if (!_hasSelection) {
      return;
    }

    final ids = _selectedIds.toList(growable: false);

    try {
      final deleted = await ref
          .read(galleryNotifierProvider.notifier)
          .purgePhotos(ids);
      if (!mounted) {
        return;
      }

      setState(() => _selectedIds.clear());
      _messenger(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '사진 $deleted장을 완전히 삭제했어요',
              style: AppTextTheme.labelLarge,
            ),
            backgroundColor: AppColorTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
    } on GalleryDeletionException catch (error) {
      if (!mounted) {
        return;
      }
      _messenger(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error.message, style: AppTextTheme.labelLarge),
            backgroundColor: AppColorTheme.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final galleryState = ref.watch(galleryNotifierProvider);
    final trashCount = galleryState.valueOrNull?.trash.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          '휴지통',
          style: AppTextTheme.headlineMedium.copyWith(
            color: AppColorTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (trashCount > 0) ...[
            TextButton(
              onPressed: () {
                final trash = galleryState.valueOrNull?.trash ?? [];
                _selectAll(trash);
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColorTheme.textSecondary,
                textStyle: AppTextTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(
                _selectedIds.length == trashCount ? '선택 해제' : '전체 선택',
              ),
            ),
            const SizedBox(width: 12),
          ],
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            galleryState.when(
              data: (gallery) {
                final trash = gallery.trash;
                if (trash.isEmpty) {
                  return const _TrashEmptyView();
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: trash.length,
                  itemBuilder: (context, index) {
                    final photo = trash[index];
                    final selected = _selectedIds.contains(photo.id);
                    return _TrashGridItem(
                      photo: photo,
                      selected: selected,
                      onTap: () => _toggleSelection(photo),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (error, stackTrace) => _TrashErrorView(
                    onRetry: () {
                      ref.read(galleryNotifierProvider.notifier).refresh();
                    },
                  ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 16,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(parent: animation, curve: Curves.easeOut),
                    ),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child:
                    _hasSelection
                        ? _SelectionActionsBar(
                          key: const ValueKey('selection-bar'),
                          count: _selectedIds.length,
                          onRestore: () => _restoreSelected(context),
                          onDelete: () => _deleteSelected(context),
                          onClear: _clearSelection,
                        )
                        : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrashGridItem extends StatelessWidget {
  const _TrashGridItem({
    required this.photo,
    required this.selected,
    required this.onTap,
  });

  final PhotoModel photo;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColorTheme.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: AppColorTheme.primary.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _TrashImage(photo: photo),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                color:
                    selected
                        ? Colors.black.withOpacity(0.4)
                        : Colors.transparent,
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        photo.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextTheme.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        photo.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextTheme.labelLarge.copyWith(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: _SelectionIndicator(selected: selected),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrashImage extends StatelessWidget {
  const _TrashImage({required this.photo});

  final PhotoModel photo;

  @override
  Widget build(BuildContext context) {
    if (photo.isLocal) {
      final file = File(photo.imageUrl);
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _thumbnailPlaceholder(),
      );
    }

    return Image.network(
      photo.imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _thumbnailPlaceholder(),
    );
  }

  Widget _thumbnailPlaceholder() {
    return Container(
      color: AppColorTheme.background,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_rounded,
        color: AppColorTheme.textSecondary.withOpacity(0.3),
        size: 32,
      ),
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColorTheme.primary : Colors.black.withOpacity(0.3),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Icon(
        Icons.check,
        size: 16,
        color: selected ? Colors.white : Colors.transparent,
      ),
    );
  }
}

class _SelectionActionsBar extends StatelessWidget {
  const _SelectionActionsBar({
    super.key,
    required this.count,
    required this.onRestore,
    required this.onDelete,
    required this.onClear,
  });

  final int count;
  final VoidCallback onRestore;
  final VoidCallback onDelete;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColorTheme.textPrimary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                '$count장 선택됨',
                style: AppTextTheme.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onClear,
                child: Text(
                  '선택 해제',
                  style: AppTextTheme.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onRestore,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text('복원'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColorTheme.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_forever_rounded, size: 20),
                  label: const Text('삭제'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColorTheme.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrashEmptyView extends StatelessWidget {
  const _TrashEmptyView();

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
              color: AppColorTheme.background,
              shape: BoxShape.circle,
              border: Border.all(color: AppColorTheme.border),
            ),
            child: Icon(
              Icons.delete_outline_rounded,
              color: AppColorTheme.textSecondary.withOpacity(0.5),
              size: 56,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '휴지통이 비어 있어요',
            style: AppTextTheme.headlineMedium.copyWith(
              color: AppColorTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '삭제한 사진은 이곳에 보관돼요.\n필요할 때 언제든 복원할 수 있어요.',
            style: AppTextTheme.bodyMedium.copyWith(
              color: AppColorTheme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TrashErrorView extends StatelessWidget {
  const _TrashErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: AppColorTheme.textSecondary.withOpacity(0.5),
            size: 72,
          ),
          const SizedBox(height: 16),
          Text(
            '휴지통을 불러오지 못했어요',
            style: AppTextTheme.headlineMedium.copyWith(
              color: AppColorTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '잠시 후 다시 시도해주세요',
            style: AppTextTheme.bodyMedium.copyWith(
              color: AppColorTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('다시 시도'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              backgroundColor: AppColorTheme.textPrimary,
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
