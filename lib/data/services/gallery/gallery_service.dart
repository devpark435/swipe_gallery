import 'dart:async';

import 'package:swipe_gallery/data/models/gallery/gallery_exception.dart';
import 'package:swipe_gallery/data/models/gallery/photo_model.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gallery_service.g.dart';

class GalleryService {
  const GalleryService();

  Future<List<AssetPathEntity>> fetchAlbums() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
      throw const GalleryPermissionException();
    }

    // hasAll: true -> 'Recent'(전체) 앨범 포함
    // filterOption: 빈 앨범 제외 등을 위한 설정 가능 (여기서는 기본값 사용하되, 추후 확장 가능)
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common, // 이미지 + 비디오 모두 포함
      hasAll: true,
      filterOption: FilterOptionGroup(
        containsPathModified: true, // 앨범 수정 시간 포함
      ),
    );

    // 1. 'isAll' (Recent) 앨범을 찾아서 맨 앞으로 보냄
    // 2. assetCount가 0인 앨범은 제외 (빈 앨범 숨기기)
    final filteredAlbums = <AssetPathEntity>[];

    for (final album in albums) {
      final count = await album.assetCountAsync;
      if (count > 0) {
        if (album.isAll) {
          filteredAlbums.insert(0, album);
        } else {
          filteredAlbums.add(album);
        }
      }
    }

    return filteredAlbums;
  }

  Future<({List<PhotoModel> photos, int totalCount})> fetchPhotos({
    AssetPathEntity? album,
  }) async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
      throw const GalleryPermissionException();
    }

    AssetPathEntity? targetAlbum = album;

    if (targetAlbum == null) {
      final paths = await PhotoManager.getAssetPathList(
        type: RequestType.common, // 이미지 + 비디오 모두 포함
        hasAll: true,
        onlyAll: true,
        filterOption: FilterOptionGroup(
          containsPathModified: true,
          orders: [
            const OrderOption(type: OrderOptionType.createDate, asc: false),
          ],
        ),
      );
      if (paths.isEmpty) {
        return (photos: <PhotoModel>[], totalCount: 0);
      }
      targetAlbum = paths.first;
    }

    final totalCount = await targetAlbum.assetCountAsync;

    // 초기 로딩 속도 개선을 위해 30장으로 제한
    final assets = await targetAlbum.getAssetListPaged(page: 0, size: 30);

    final photos = <PhotoModel>[];

    for (final asset in assets) {
      // 이미지 또는 비디오 타입만 처리
      if (asset.type != AssetType.image && asset.type != AssetType.video) {
        continue;
      }

      try {
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
            isVideo: asset.type == AssetType.video, // 비디오 여부 추가
          ),
        );
      } catch (e) {
        // 파일 로드 실패 시 건너뜀
        continue;
      }
    }

    return (photos: photos, totalCount: totalCount);
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
