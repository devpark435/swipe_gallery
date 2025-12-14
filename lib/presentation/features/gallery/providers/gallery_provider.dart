import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

import 'package:swipe_gallery/data/models/gallery/gallery_exception.dart';
import 'package:swipe_gallery/data/models/gallery/gallery_state.dart';
import 'package:swipe_gallery/data/models/gallery/photo_model.dart';
import 'package:swipe_gallery/data/services/gallery/gallery_service.dart';
import 'package:swipe_gallery/data/services/gallery/trash_storage_service.dart';
import 'package:swipe_gallery/presentation/features/permission/providers/permission_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gallery_provider.g.dart';

@riverpod
class GalleryNotifier extends _$GalleryNotifier {
  late final TrashStorageService _trashStorage = ref.read(
    trashStorageServiceProvider,
  );

  AssetPathEntity? _selectedAlbum;

  @override
  FutureOr<GalleryState> build() async {
    final permissionStatus = await ref.watch(
      galleryPermissionNotifierProvider.future,
    );
    if (!permissionStatus.isGranted) {
      return const GalleryState();
    }

    // 초기에는 전체 사진 로드
    return _loadPhotos();
  }

  Future<void> selectAlbum(AssetPathEntity? album) async {
    _selectedAlbum = album;
    await refresh();
  }

  Future<GalleryState> _loadPhotos() async {
    final service = ref.read(galleryServiceProvider);
    final result = await service.fetchPhotos(album: _selectedAlbum);
    return _buildStateFromPhotos(result.photos, result.totalCount);
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

    state = AsyncData(
      current.copyWith(active: updatedActive, trash: updatedTrash),
    );
    _persistTrash(updatedTrash);
  }

  void passPhoto(PhotoModel photo) {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }

    final updatedActive = current.active
        .where((element) => element.id != photo.id)
        .toList(growable: false);

    state = AsyncData(current.copyWith(active: updatedActive));
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
    final updatedActive = <PhotoModel>[photo, ...current.active];
    state = AsyncData(current.copyWith(active: updatedActive));
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

    state = AsyncData(
      current.copyWith(active: updatedActive, trash: updatedTrash),
    );
    _persistTrash(updatedTrash);
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

    state = AsyncData(current.copyWith(trash: updatedTrash));
    _persistTrash(updatedTrash);
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
      return _loadPhotos();
    });
  }

  Future<GalleryState> _buildStateFromPhotos(
    List<PhotoModel> photos,
    int totalCount,
  ) async {
    final storedTrashIds = await _trashStorage.loadTrashIds();
    final active = <PhotoModel>[];
    final trash = <PhotoModel>[];

    for (final photo in photos) {
      if (storedTrashIds.contains(photo.id)) {
        trash.add(photo);
      } else {
        active.add(photo);
      }
    }

    final actualTrashIds = {for (final photo in trash) photo.id};
    if (!setEquals(actualTrashIds, storedTrashIds)) {
      await _trashStorage.saveTrashIds(actualTrashIds);
    }

    return GalleryState(
      active: active,
      trash: trash,
      totalCount: totalCount,
      selectedAlbumId: _selectedAlbum?.id,
    );
  }

  void _persistTrash(List<PhotoModel> trash) {
    final ids = {for (final photo in trash) photo.id};
    unawaited(_trashStorage.saveTrashIds(ids));
  }
}
