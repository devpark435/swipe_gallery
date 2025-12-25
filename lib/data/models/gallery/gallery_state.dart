import 'package:swipe_gallery/data/models/gallery/photo_model.dart';

class GalleryState {
  const GalleryState({
    this.active = const [],
    this.trash = const [],
    this.totalCount = 0,
    this.remainingCount = 0,
    this.selectedAlbumId,
  });

  final List<PhotoModel> active;
  final List<PhotoModel> trash;
  final int totalCount;
  final int remainingCount;
  final String? selectedAlbumId;

  bool get hasTrash => trash.isNotEmpty;
  bool get isEmpty => active.isEmpty;

  GalleryState copyWith({
    List<PhotoModel>? active,
    List<PhotoModel>? trash,
    int? totalCount,
    int? remainingCount,
    String? selectedAlbumId,
  }) {
    return GalleryState(
      active: active ?? this.active,
      trash: trash ?? this.trash,
      totalCount: totalCount ?? this.totalCount,
      remainingCount: remainingCount ?? this.remainingCount,
      selectedAlbumId: selectedAlbumId ?? this.selectedAlbumId,
    );
  }
}
