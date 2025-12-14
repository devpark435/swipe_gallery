import 'package:swipe_gallery/data/models/gallery/photo_model.dart';

class GalleryState {
  const GalleryState({
    this.active = const [],
    this.trash = const [],
    this.totalCount = 0,
    this.selectedAlbumId,
  });

  final List<PhotoModel> active;
  final List<PhotoModel> trash;
  final int totalCount;
  final String? selectedAlbumId;

  bool get hasTrash => trash.isNotEmpty;
  bool get isEmpty => active.isEmpty;

  GalleryState copyWith({
    List<PhotoModel>? active,
    List<PhotoModel>? trash,
    int? totalCount,
    String? selectedAlbumId,
  }) {
    return GalleryState(
      active: active ?? this.active,
      trash: trash ?? this.trash,
      totalCount: totalCount ?? this.totalCount,
      selectedAlbumId: selectedAlbumId ?? this.selectedAlbumId,
    );
  }
}
