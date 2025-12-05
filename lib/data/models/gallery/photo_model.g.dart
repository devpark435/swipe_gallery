// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PhotoModel _$PhotoModelFromJson(Map<String, dynamic> json) => PhotoModel(
  id: json['id'] as String,
  imageUrl: json['image_url'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  isLocal: json['is_local'] as bool? ?? false,
);

Map<String, dynamic> _$PhotoModelToJson(PhotoModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'image_url': instance.imageUrl,
      'title': instance.title,
      'description': instance.description,
      'is_local': instance.isLocal,
    };
