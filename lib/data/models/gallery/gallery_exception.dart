class GalleryPermissionException implements Exception {
  const GalleryPermissionException([
    this.message = '사진 접근 권한이 필요합니다. 설정에서 권한을 허용해주세요.',
  ]);

  final String message;

  @override
  String toString() => message;
}

class GalleryDeletionException implements Exception {
  const GalleryDeletionException([
    this.message = '사진을 완전히 삭제하지 못했습니다. 다시 시도해주세요.',
  ]);

  final String message;

  @override
  String toString() => message;
}
