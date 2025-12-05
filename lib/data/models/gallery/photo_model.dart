import 'package:json_annotation/json_annotation.dart';

part 'photo_model.g.dart';

@JsonSerializable()
class PhotoModel {
  final String id;
  @JsonKey(name: 'image_url')
  final String imageUrl;
  final String title;
  final String description;
  @JsonKey(name: 'is_local', defaultValue: false)
  final bool isLocal;

  const PhotoModel({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.description,
    this.isLocal = false,
  });

  factory PhotoModel.fromJson(Map<String, dynamic> json) {
    try {
      return _$PhotoModelFromJson(json);
    } catch (e) {
      return PhotoModel(
        id: json['id'] as String? ?? 'unknown',
        imageUrl: json['image_url'] as String? ?? '',
        title: json['title'] as String? ?? '알 수 없는 사진',
        description: json['description'] as String? ?? '',
        isLocal: json['is_local'] as bool? ?? false,
      );
    }
  }

  Map<String, dynamic> toJson() => _$PhotoModelToJson(this);

  PhotoModel copyWith({
    String? id,
    String? imageUrl,
    String? title,
    String? description,
    bool? isLocal,
  }) {
    return PhotoModel(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      isLocal: isLocal ?? this.isLocal,
    );
  }
}
