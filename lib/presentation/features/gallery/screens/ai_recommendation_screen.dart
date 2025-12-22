import 'dart:io' as java;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swipe_gallery/data/models/gallery/photo_model.dart';
import 'package:swipe_gallery/data/services/analysis/image_analysis_service.dart';
import 'package:swipe_gallery/data/services/gallery/gallery_service.dart';
import 'package:swipe_gallery/presentation/features/gallery/providers/gallery_provider.dart';
import 'package:swipe_gallery/theme/app_text_theme.dart';
import 'package:swipe_gallery/theme/app_color_theme.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ai_recommendation_screen.g.dart';

@riverpod
class AiRecommendationNotifier extends _$AiRecommendationNotifier {
  @override
  FutureOr<List<List<PhotoModel>>> build() async {
    // 1. 최근 사진 100장 가져오기 (또는 더 많이)
    final galleryService = ref.read(galleryServiceProvider);
    final result = await galleryService.fetchPhotos(page: 0, size: 100);

    // 2. 분석 서비스 실행
    final analysisService = ref.read(imageAnalysisServiceProvider);
    // threshold: 0.0 ~ 1.0 (1.0에 가까울수록 엄격, 낮을수록 관대함)
    // 0.85 -> 0.70으로 조정하여 더 많은 유사 사진을 찾도록 변경
    final groups = await analysisService.groupSimilarPhotos(
      result.photos,
      threshold: 0.70,
    );

    // 3. 그룹이 없는 경우 (유사한 사진 없음) 빈 리스트 반환
    return groups;
  }

  // 그룹에서 사진 삭제 (휴지통으로 이동)
  Future<void> removePhotos(List<String> photoIds) async {
    final galleryNotifier = ref.read(galleryNotifierProvider.notifier);

    // 실제 삭제 로직 (GalleryNotifier 재사용)
    for (final id in photoIds) {
      // 갤러리 상태에서도 제거해줘야 함
      galleryNotifier.removePhoto(id);
    }

    // 현재 상태 업데이트 (삭제된 사진 제거)
    final currentGroups = state.valueOrNull ?? [];
    final newGroups = <List<PhotoModel>>[];

    for (final group in currentGroups) {
      final newGroup = group.where((p) => !photoIds.contains(p.id)).toList();
      if (newGroup.length > 1) {
        // 2장 이상이어야 그룹 유지
        newGroups.add(newGroup);
      }
    }

    state = AsyncData(newGroups);
  }
}

class AiRecommendationScreen extends ConsumerWidget {
  const AiRecommendationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the provider. Note: If generation failed, aiRecommendationNotifierProvider is undefined.
    // We assume generation will succeed after fixing errors.
    final state = ref.watch(aiRecommendationNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'AI 스마트 정리',
          style: AppTextTheme.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: context.colors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: context.colors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: state.when(
        data: (groups) {
          if (groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 80,
                    color: context.colors.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '정리할 비슷한 사진이 없어요!',
                    style: AppTextTheme.headlineMedium.copyWith(
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '최근 사진 중에는 중복되거나\n비슷한 사진이 발견되지 않았습니다.',
                    textAlign: TextAlign.center,
                    style: AppTextTheme.bodyMedium.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              return _SimilarGroupCard(group: groups[index]);
            },
          );
        },
        loading:
            () => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: context.colors.primary),
                  const SizedBox(height: 24),
                  Text(
                    '사진을 분석하고 있어요...',
                    style: AppTextTheme.bodyLarge.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '최근 사진들을 비교하여\n비슷한 사진들을 찾고 있습니다.',
                    textAlign: TextAlign.center,
                    style: AppTextTheme.bodyMedium.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
        error: (error, stack) => Center(child: Text('오류가 발생했습니다: $error')),
      ),
    );
  }
}

class _SimilarGroupCard extends ConsumerStatefulWidget {
  const _SimilarGroupCard({required this.group});

  final List<PhotoModel> group;

  @override
  ConsumerState<_SimilarGroupCard> createState() => _SimilarGroupCardState();
}

class _SimilarGroupCardState extends ConsumerState<_SimilarGroupCard> {
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.colors.textPrimary.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: context.colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '비슷한 사진 ${widget.group.length}장',
                  style: AppTextTheme.labelMedium.copyWith(
                    color: context.colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              if (_selectedIds.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    // 선택된 사진 삭제 요청
                    ref
                        .read(aiRecommendationNotifierProvider.notifier)
                        .removePhotos(_selectedIds.toList());
                    setState(() {
                      _selectedIds.clear();
                    });
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text('${_selectedIds.length}장 삭제'),
                  style: TextButton.styleFrom(
                    foregroundColor: context.colors.error,
                    padding: EdgeInsets.zero,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.group.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final photo = widget.group[index];
                final isSelected = _selectedIds.contains(photo.id);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedIds.remove(photo.id);
                      } else {
                        _selectedIds.add(photo.id);
                      }
                    });
                  },
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          java.File(photo.imageUrl),
                          width: 120,
                          height: 160,
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (isSelected)
                        Container(
                          width: 120,
                          height: 160,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: context.colors.error,
                              width: 2,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '삭제할 사진을 선택하세요. 남길 사진은 선택하지 마세요.',
            style: AppTextTheme.labelMedium.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
