import 'package:pocket_photo/data/models/gallery/photo_model.dart';

class GalleryState {
  const GalleryState({this.active = const [], this.trash = const []});

  final List<PhotoModel> active;
  final List<PhotoModel> trash;

  bool get hasTrash => trash.isNotEmpty;
  bool get isEmpty => active.isEmpty;

  GalleryState copyWith({List<PhotoModel>? active, List<PhotoModel>? trash}) {
    return GalleryState(
      active: active ?? this.active,
      trash: trash ?? this.trash,
    );
  }
}
