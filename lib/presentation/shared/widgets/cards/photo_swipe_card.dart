import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pocket_photo/data/models/gallery/photo_model.dart';
import 'package:pocket_photo/theme/app_color_theme.dart';
import 'package:pocket_photo/theme/app_text_theme.dart';

class PhotoSwipeCard extends StatelessWidget {
  const PhotoSwipeCard({super.key, required this.photo});

  final PhotoModel photo;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(tag: photo.id, child: _buildImage()),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColorTheme.transparent,
                      AppColorTheme.textPrimary.withOpacity(0.85),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      photo.title,
                      style: AppTextTheme.headlineMedium.copyWith(
                        color: AppColorTheme.surface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      photo.description,
                      style: AppTextTheme.bodyMedium.copyWith(
                        color: AppColorTheme.surface.withOpacity(0.82),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (photo.isLocal) {
      final file = File(photo.imageUrl);
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _errorPlaceholder(),
      );
    }

    return Image.network(
      photo.imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return child;
        }
        return Center(
          child: CircularProgressIndicator(
            value:
                progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!
                    : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => _errorPlaceholder(),
    );
  }

  Widget _errorPlaceholder() {
    return Container(
      color: AppColorTheme.background,
      alignment: Alignment.center,
      child: Icon(
        Icons.broken_image_outlined,
        color: AppColorTheme.textSecondary.withOpacity(0.6),
        size: 48,
      ),
    );
  }
}
