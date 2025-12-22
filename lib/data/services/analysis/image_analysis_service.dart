import 'dart:isolate';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:swipe_gallery/data/models/gallery/photo_model.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'image_analysis_service.g.dart';

@riverpod
ImageAnalysisService imageAnalysisService(ImageAnalysisServiceRef ref) {
  return ImageAnalysisService();
}

class ImageAnalysisService {
  /// Compares photos and returns groups of similar photos.
  /// [threshold] 0.0 to 1.0 (1.0 means identical).
  Future<List<List<PhotoModel>>> groupSimilarPhotos(
    List<PhotoModel> photos, {
    double threshold = 0.85,
  }) async {
    if (photos.isEmpty) return [];

    // Run heavy computation in an isolate
    // We pass paths instead of complex objects to be safe,
    // but PhotoModel is simple data class so it might be fine if serializable.
    // However, cv.Mat cannot be passed.
    // We'll pass the list of photos and do the work in the isolate.

    return await Isolate.run(() => _processPhotos(photos, threshold));
  }

  static List<List<PhotoModel>> _processPhotos(
    List<PhotoModel> photos,
    double threshold,
  ) {
    final groups = <List<PhotoModel>>[];
    final visited = <String>{}; // Set of photo IDs

    // Pre-calculate histograms for all photos to avoid re-reading files
    // Key: Photo ID, Value: Histogram Mat
    final histograms = <String, cv.Mat>{};

    // 1. Calculate Histograms
    for (final photo in photos) {
      if (!photo.isLocal) continue; // Skip remote photos for now
      if (photo.isVideo) continue; // Skip videos for image comparison

      try {
        // Read image
        final img = cv.imread(photo.imageUrl, flags: cv.IMREAD_COLOR);
        if (img.isEmpty) continue;

        // Resize for faster processing (optional, but histogram on full size is slow)
        // cv.resize(img, (256, 256)); // Not strictly necessary for calcHist but good for caching if needed

        // Convert to HSV for better color comparison
        final hsv = cv.cvtColor(img, cv.COLOR_BGR2HSV);

        // Calculate Histogram
        // channels: [0, 1] (Hue, Saturation)
        // histSize: [50, 60]
        // ranges: [0, 180, 0, 256]
        final hist = cv.calcHist(
          cv.VecMat.fromList([hsv]),
          cv.VecI32.fromList([0, 1]),
          cv.Mat.empty(),
          cv.VecI32.fromList([50, 60]),
          cv.VecF32.fromList([0, 180, 0, 256]),
        );

        // Normalize histogram
        cv.normalize(hist, hist, alpha: 0, beta: 1, normType: cv.NORM_MINMAX);

        histograms[photo.id] = hist;

        // Release image memory immediately
        img.dispose();
        hsv.dispose();
      } catch (e) {
        debugPrint('Error processing photo ${photo.id}: $e');
      }
    }

    // 2. Compare Histograms
    final ids = histograms.keys.toList();
    for (int i = 0; i < ids.length; i++) {
      final id1 = ids[i];
      if (visited.contains(id1)) continue;

      final currentGroup = <PhotoModel>[];
      // Find photo object
      final photo1 = photos.firstWhere((p) => p.id == id1);
      currentGroup.add(photo1);
      visited.add(id1);

      final hist1 = histograms[id1]!;

      for (int j = i + 1; j < ids.length; j++) {
        final id2 = ids[j];
        if (visited.contains(id2)) continue;

        final hist2 = histograms[id2]!;

        // Compare using Correlation (CV_COMP_CORREL = 0)
        // 1.0 is perfect match
        final similarity = cv.compareHist(hist1, hist2, method: 0);

        if (similarity >= threshold) {
          final photo2 = photos.firstWhere((p) => p.id == id2);
          currentGroup.add(photo2);
          visited.add(id2);
        }
      }

      if (currentGroup.length > 1) {
        groups.add(currentGroup);
      }
    }

    // Clean up mats
    for (final mat in histograms.values) {
      mat.dispose();
    }

    return groups;
  }
}
