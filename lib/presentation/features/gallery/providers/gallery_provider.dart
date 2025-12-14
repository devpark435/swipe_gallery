import 'dart:async';
import 'package:photo_manager/photo_manager.dart';

import 'package:swipe_gallery/data/models/gallery/gallery_exception.dart';
import 'package:swipe_gallery/data/models/gallery/gallery_state.dart';
import 'package:swipe_gallery/data/models/gallery/photo_model.dart';
import 'package:swipe_gallery/data/services/gallery/gallery_service.dart';
import 'package:swipe_gallery/data/services/gallery/photo_persistence_service.dart';
import 'package:swipe_gallery/presentation/features/permission/providers/permission_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gallery_provider.g.dart';

@riverpod
class GalleryNotifier extends _$GalleryNotifier {
  late final PhotoPersistenceService _persistence = ref.read(
    photoPersistenceServiceProvider,
  );

  AssetPathEntity? _selectedAlbum;
  final Set<String> _skippedIdsCache = {};
  final Set<String> _trashIdsCache = {};

  int _currentPage = 0;
  static const int _pageSize = 30;
  bool _isLoadingMore = false;

  @override
  FutureOr<GalleryState> build() async {
    final permissionStatus = await ref.watch(
      galleryPermissionNotifierProvider.future,
    );
    if (!permissionStatus.isGranted) {
      return const GalleryState();
    }

    // 초기에는 전체 사진 로드
    return _initializePhotos();
  }

  Future<void> selectAlbum(AssetPathEntity? album) async {
    _selectedAlbum = album;
    await refresh();
  }

  Future<GalleryState> _initializePhotos() async {
    _currentPage = 0;
    _isLoadingMore = false;
    final service = ref.read(galleryServiceProvider);
    final result = await service.fetchPhotos(
      album: _selectedAlbum,
      page: _currentPage,
      size: _pageSize,
    );
    return _buildStateFromPhotos(
      result.photos,
      result.totalCount,
      isInitialLoad: true,
    );
  }

  Future<void> _loadMorePhotos() async {
    if (_isLoadingMore) return;

    final current = state.valueOrNull;
    if (current == null) return;

    _isLoadingMore = true;
    _currentPage++;

    try {
      final service = ref.read(galleryServiceProvider);
      final result = await service.fetchPhotos(
        album: _selectedAlbum,
        page: _currentPage,
        size: _pageSize,
      );

      if (result.photos.isEmpty) {
        _isLoadingMore = false;
        return;
      }

      final newState = await _buildStateFromPhotos(
        result.photos,
        result.totalCount,
        currentState: current,
      );

      state = AsyncData(newState);
    } catch (e) {
      _currentPage--;
    } finally {
      _isLoadingMore = false;
    }
  }

  void removePhoto(String id) {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }

    final targetIndex = current.active.indexWhere((photo) => photo.id == id);
    if (targetIndex < 0) {
      return;
    }

    final target = current.active[targetIndex];
    final updatedActive = List<PhotoModel>.from(current.active)
      ..removeAt(targetIndex);
    final updatedTrash = <PhotoModel>[target, ...current.trash];

    _trashIdsCache.add(id);
    _persistTrashIds();

    final newRemaining = current.remainingCount - 1;

    state = AsyncData(
      current.copyWith(
        active: updatedActive,
        trash: updatedTrash,
        remainingCount: newRemaining,
      ),
    );

    if (updatedActive.length < 5) {
      _loadMorePhotos();
    }
  }

  void passPhoto(PhotoModel photo) {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }

    final updatedActive = current.active
        .where((element) => element.id != photo.id)
        .toList(growable: false);

    _skippedIdsCache.add(photo.id);
    _persistSkippedIds();

    final newRemaining = current.remainingCount - 1;

    state = AsyncData(
      current.copyWith(active: updatedActive, remainingCount: newRemaining),
    );

    if (updatedActive.length < 5) {
      _loadMorePhotos();
    }
  }

  /// 패스했던 사진을 다시 맨 앞에 추가 (Undo 용도)
  void reAddPhoto(PhotoModel photo) {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    // 이미 active에 있다면 중복 추가하지 않음
    final alreadyExists = current.active.any(
      (element) => element.id == photo.id,
    );
    if (alreadyExists) {
      return;
    }

    if (_skippedIdsCache.contains(photo.id)) {
      _skippedIdsCache.remove(photo.id);
      _persistSkippedIds();
    }

    final updatedActive = <PhotoModel>[photo, ...current.active];
    // Undo 시 remainingCount 증가
    final newRemaining = current.remainingCount + 1;

    state = AsyncData(
      current.copyWith(active: updatedActive, remainingCount: newRemaining),
    );
  }

  void restorePhoto(String id) {
    restorePhotos([id]);
  }

  void restorePhotos(List<String> ids) {
    if (ids.isEmpty) {
      return;
    }

    final current = state.valueOrNull;
    if (current == null) {
      return;
    }

    final selectedIds = ids.toSet();
    final restored = current.trash
        .where((photo) => selectedIds.contains(photo.id))
        .toList(growable: false);

    if (restored.isEmpty) {
      return;
    }

    final updatedTrash = current.trash
        .where((photo) => !selectedIds.contains(photo.id))
        .toList(growable: false);
    final updatedActive = <PhotoModel>[...restored, ...current.active];

    _trashIdsCache.removeAll(selectedIds);
    _persistTrashIds();

    // 복구 시 remainingCount 증가 (복구된 개수만큼)
    final newRemaining = current.remainingCount + restored.length;

    state = AsyncData(
      current.copyWith(
        active: updatedActive,
        trash: updatedTrash,
        remainingCount: newRemaining,
      ),
    );
  }

  Future<int> purgePhoto(String id) {
    return purgePhotos([id]);
  }

  Future<int> purgePhotos(List<String> ids) async {
    if (ids.isEmpty) {
      return 0;
    }

    final service = ref.read(galleryServiceProvider);
    final deletedIds = await service.deleteAssets(ids);
    if (deletedIds.isEmpty) {
      throw const GalleryDeletionException();
    }

    final current = state.valueOrNull;
    if (current == null) {
      return deletedIds.length;
    }

    final deletedSet = deletedIds.toSet();
    final updatedTrash = current.trash
        .where((photo) => !deletedSet.contains(photo.id))
        .toList(growable: false);

    _trashIdsCache.removeAll(deletedSet);
    _persistTrashIds();

    state = AsyncData(current.copyWith(trash: updatedTrash));
    return deletedIds.length;
  }

  Future<int> purgeAllTrash() async {
    final current = state.valueOrNull;
    if (current == null || current.trash.isEmpty) {
      return 0;
    }

    final ids = current.trash.map((photo) => photo.id).toList(growable: false);
    return purgePhotos(ids);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return _initializePhotos();
    });
  }

  Future<GalleryState> _buildStateFromPhotos(
    List<PhotoModel> newPhotos,
    int totalCount, {
    GalleryState? currentState,
    bool isInitialLoad = false,
  }) async {
    final storedTrashIds = await _persistence.loadTrashIds();
    final storedSkippedIds = await _persistence.loadSkippedIds();

    _trashIdsCache.clear();
    _trashIdsCache.addAll(storedTrashIds);

    _skippedIdsCache.clear();
    _skippedIdsCache.addAll(storedSkippedIds);

    final active =
        isInitialLoad
            ? <PhotoModel>[]
            : List<PhotoModel>.from(currentState?.active ?? []);
    final trash =
        isInitialLoad
            ? <PhotoModel>[]
            : List<PhotoModel>.from(currentState?.trash ?? []);

    int filteredCount = 0;

    for (final photo in newPhotos) {
      if (_trashIdsCache.contains(photo.id)) {
        // 이미 Trash에 있는지 확인 후 추가
        if (!trash.any((t) => t.id == photo.id)) {
          trash.add(photo);
        }
        filteredCount++;
      } else if (_skippedIdsCache.contains(photo.id)) {
        filteredCount++;
      } else {
        // 이미 Active에 있는지 확인 후 추가
        if (!active.any((a) => a.id == photo.id)) {
          active.add(photo);
        }
      }
    }

    int remainingCount;
    if (isInitialLoad) {
      remainingCount = totalCount - filteredCount;
    } else {
      // 추가 로딩 시: 기존 remainingCount에서 이번에 로드된 것 중 처리된 개수를 뺌
      remainingCount =
          (currentState?.remainingCount ?? totalCount) - filteredCount;
    }

    return GalleryState(
      active: active,
      trash: trash,
      totalCount: totalCount,
      remainingCount: remainingCount,
      selectedAlbumId: _selectedAlbum?.id,
    );
  }

  void _persistTrashIds() {
    unawaited(_persistence.saveTrashIds(_trashIdsCache));
  }

  void _persistSkippedIds() {
    unawaited(_persistence.saveSkippedIds(_skippedIdsCache));
  }
}
