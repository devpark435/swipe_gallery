import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:swipe_gallery/data/models/gallery/photo_model.dart';
import 'package:swipe_gallery/theme/app_color_theme.dart';
import 'package:swipe_gallery/theme/app_text_theme.dart';
import 'package:video_player/video_player.dart';

class PhotoSwipeCard extends StatefulWidget {
  const PhotoSwipeCard({super.key, required this.photo});

  final PhotoModel photo;

  @override
  State<PhotoSwipeCard> createState() => _PhotoSwipeCardState();
}

class _PhotoSwipeCardState extends State<PhotoSwipeCard> {
  VideoPlayerController? _videoController;
  bool _isPlaying = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.photo.isVideo && widget.photo.isLocal) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    final file = File(widget.photo.imageUrl);
    _videoController = VideoPlayerController.file(file);
    try {
      await _videoController!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Video initialization failed: $e');
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_videoController == null || !_isInitialized) return;

    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      _videoController!.play();
    } else {
      _videoController!.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: context.colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(tag: widget.photo.id, child: _buildMedia(context)),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColorTheme.transparent,
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.4),
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: const [0.0, 0.3, 0.6, 1.0],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 32),
                    Text(
                      widget.photo.title,
                      style: AppTextTheme.headlineMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.photo.description,
                      style: AppTextTheme.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedia(BuildContext context) {
    if (widget.photo.isVideo) {
      if (_isInitialized && _videoController != null) {
        return Stack(
          fit: StackFit.expand,
          children: [
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController!.value.size.width,
                height: _videoController!.value.size.height,
                child: VideoPlayer(_videoController!),
              ),
            ),
            Center(
              child: GestureDetector(
                onTap: _togglePlay,
                child: AnimatedOpacity(
                  opacity: _isPlaying ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      } else {
        // 비디오 초기화 전 썸네일 표시 시도 (PhotoManager 사용)
        return FutureBuilder<AssetEntity?>(
          future: AssetEntity.fromId(widget.photo.id),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return FutureBuilder(
                future: snapshot.data!.thumbnailDataWithSize(
                  const ThumbnailSize.square(500),
                ),
                builder: (context, thumbSnapshot) {
                  if (thumbSnapshot.hasData && thumbSnapshot.data != null) {
                    return Image.memory(thumbSnapshot.data!, fit: BoxFit.cover);
                  }
                  return Center(
                    child: CircularProgressIndicator(
                      color: context.colors.primary,
                    ),
                  );
                },
              );
            }
            return Center(
              child: CircularProgressIndicator(color: context.colors.primary),
            );
          },
        );
      }
    }

    if (widget.photo.isLocal) {
      final file = File(widget.photo.imageUrl);
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) => _errorPlaceholder(context),
      );
    }

    return Image.network(
      widget.photo.imageUrl,
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
            color: context.colors.surface,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => _errorPlaceholder(context),
    );
  }

  Widget _errorPlaceholder(BuildContext context) {
    return Container(
      color: context.colors.background,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_rounded,
            color: context.colors.textSecondary.withOpacity(0.4),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            '이미지를 불러올 수 없어요',
            style: AppTextTheme.bodyMedium.copyWith(
              color: context.colors.textSecondary.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
