import 'dart:async';

import 'package:photo_manager/photo_manager.dart';
import 'package:pocket_photo/data/models/gallery/gallery_exception.dart';
import 'package:pocket_photo/data/models/gallery/photo_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gallery_service.g.dart';

class GalleryService {
  const GalleryService();

  Future<List<PhotoModel>> fetchPhotos() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
      throw const GalleryPermissionException();
    }

    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      hasAll: true,
      onlyAll: true,
    );

    if (paths.isEmpty) {
      return const [];
    }

    final assets = await paths.first.getAssetListPaged(page: 0, size: 100);
    final photos = <PhotoModel>[];

    for (final asset in assets) {
      final file = await asset.file;
      if (file == null) {
        continue;
      }

      photos.add(
        PhotoModel(
          id: asset.id,
          imageUrl: file.path,
          title: asset.title ?? '내 사진',
          description: _descriptionFromAsset(asset),
          isLocal: true,
        ),
      );
    }

    return photos;
  }

  Future<List<String>> deleteAssets(List<String> ids) async {
    if (ids.isEmpty) {
      return const [];
    }

    final deletedIds = await PhotoManager.editor.deleteWithIds(ids);
    if (deletedIds.isEmpty) {
      throw const GalleryDeletionException();
    }

    final deletedIdSet = deletedIds.toSet();
    return ids.where(deletedIdSet.contains).toList(growable: false);
  }

  String _descriptionFromAsset(AssetEntity asset) {
    final date = asset.createDateTime.toLocal();
    final album = asset.relativePath ?? '갤러리';
    final formattedDate =
        '${date.year}.${_twoDigit(date.month)}.${_twoDigit(date.day)}';
    return '$album · $formattedDate';
  }

  String _twoDigit(int value) => value.toString().padLeft(2, '0');
}

@riverpod
GalleryService galleryService(GalleryServiceRef ref) {
  return const GalleryService();
}
