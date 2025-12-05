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
          content: Text(
            '선택한 사진 $restoredCount장을 복원했어요.',
            style: AppTextTheme.labelLarge,
          ),
          backgroundColor: AppColorTheme.primary,
          behavior: SnackBarBehavior.floating,
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
              '선택한 사진 $deleted장을 완전히 삭제했습니다.',
              style: AppTextTheme.labelLarge,
            ),
            backgroundColor: AppColorTheme.error,
            behavior: SnackBarBehavior.floating,
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
          ),
        );
    }
  }

  Future<void> _deleteAll(BuildContext context) async {
    try {
      final deleted =
          await ref.read(galleryNotifierProvider.notifier).purgeAllTrash();
      if (!mounted) {
        return;
      }

      if (deleted == 0) {
        return;
      }

      setState(() => _selectedIds.clear());
      _messenger(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '휴지통에서 사진 $deleted장을 삭제했습니다.',
              style: AppTextTheme.labelLarge,
            ),
            backgroundColor: AppColorTheme.error,
            behavior: SnackBarBehavior.floating,
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
        title: Text(
          '휴지통',
          style: AppTextTheme.headlineMedium.copyWith(
            color: AppColorTheme.textPrimary,
          ),
        ),
        actions: [
          if (trashCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: () => _deleteAll(context),
                icon: const Icon(Icons.delete_forever_outlined),
                label: const Text('모두 삭제하기'),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: galleryState.when(
                data: (gallery) {
                  final trash = gallery.trash;
                  if (trash.isEmpty) {
                    return const _TrashEmptyView();
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.72,
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
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _TrashImage(photo: photo),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColorTheme.textPrimary.withOpacity(0.85),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      photo.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextTheme.bodyLarge.copyWith(
                        color: AppColorTheme.surface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      photo.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextTheme.bodyMedium.copyWith(
                        color: AppColorTheme.surface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: _SelectionIndicator(selected: selected),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: selected ? 1 : 0,
              child: Container(color: AppColorTheme.primary.withOpacity(0.2)),
            ),
          ],
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
        Icons.image_not_supported_outlined,
        color: AppColorTheme.textSecondary.withOpacity(0.5),
        size: 34,
      ),
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:
            selected
                ? AppColorTheme.primary
                : AppColorTheme.surface.withOpacity(0.85),
        border: Border.all(
          color: selected ? AppColorTheme.primary : AppColorTheme.border,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        selected ? Icons.check : Icons.radio_button_unchecked,
        size: 16,
        color:
            selected
                ? AppColorTheme.surface
                : AppColorTheme.textSecondary.withOpacity(0.8),
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
    return Material(
      elevation: 8,
      color: AppColorTheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '선택된 사진 $count장',
                    style: AppTextTheme.bodyLarge.copyWith(
                      color: AppColorTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onClear,
                    tooltip: '선택 해제',
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onRestore,
                      icon: const Icon(Icons.undo),
                      label: const Text('선택 사진 복구'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColorTheme.primary,
                        side: BorderSide(
                          color: AppColorTheme.primary.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('선택 사진 삭제'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColorTheme.error,
                        foregroundColor: AppColorTheme.surface,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
          Icon(
            Icons.inbox_outlined,
            color: AppColorTheme.textSecondary.withOpacity(0.5),
            size: 72,
          ),
          const SizedBox(height: 16),
          Text(
            '휴지통이 비어 있어요.',
            style: AppTextTheme.headlineMedium.copyWith(
              color: AppColorTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '삭제한 사진은 이곳에 임시 보관돼요.\n필요 없는 사진은 여기에서 영구 삭제할 수 있어요.',
            style: AppTextTheme.bodyMedium.copyWith(
              color: AppColorTheme.textSecondary.withOpacity(0.8),
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
            Icons.error_outline,
            color: AppColorTheme.textSecondary.withOpacity(0.5),
            size: 72,
          ),
          const SizedBox(height: 16),
          Text(
            '휴지통을 불러오지 못했어요.',
            style: AppTextTheme.headlineMedium.copyWith(
              color: AppColorTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '네트워크 상태를 확인하고 다시 시도해주세요.',
            style: AppTextTheme.bodyMedium.copyWith(
              color: AppColorTheme.textSecondary.withOpacity(0.8),
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
    );
  }
}
