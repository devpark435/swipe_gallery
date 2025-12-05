import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:swipe_gallery/data/models/gallery/gallery_exception.dart';
import 'package:swipe_gallery/data/models/gallery/gallery_state.dart';
import 'package:swipe_gallery/data/models/gallery/photo_model.dart';
import 'package:swipe_gallery/data/services/gallery/gallery_service.dart';
import 'package:swipe_gallery/data/services/gallery/trash_storage_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gallery_provider.g.dart';

@riverpod
class GalleryNotifier extends _$GalleryNotifier {
  late final TrashStorageService _trashStorage = ref.read(
    trashStorageServiceProvider,
  );

  @override
  FutureOr<GalleryState> build() async {
    final service = ref.read(galleryServiceProvider);
    final photos = await service.fetchPhotos();
    return _buildStateFromPhotos(photos);
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
      final service = ref.read(galleryServiceProvider);
      final photos = await service.fetchPhotos();
      return _buildStateFromPhotos(photos);
    });
  }

  Future<GalleryState> _buildStateFromPhotos(List<PhotoModel> photos) async {
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

    return GalleryState(active: active, trash: trash);
  }

  void _persistTrash(List<PhotoModel> trash) {
    final ids = {for (final photo in trash) photo.id};
    unawaited(_trashStorage.saveTrashIds(ids));
  }
}
