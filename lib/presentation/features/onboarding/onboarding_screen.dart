import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swipe_gallery/presentation/features/onboarding/onboarding_provider.dart';
import 'package:swipe_gallery/theme/app_color_theme.dart';
import 'package:swipe_gallery/theme/app_text_theme.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      ref.read(onboardingControllerProvider.notifier).complete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: const [_SwipeGuidePage(), _TrashGuidePage()],
              ),
            ),
            _BottomControls(
              currentPage: _currentPage,
              totalPages: 2,
              onNext: _onNext,
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeGuidePage extends StatefulWidget {
  const _SwipeGuidePage();

  @override
  State<_SwipeGuidePage> createState() => _SwipeGuidePageState();
}

class _SwipeGuidePageState extends State<_SwipeGuidePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          SizedBox(
            height: 320,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: 0.9,
                  child: Container(
                    width: 240,
                    height: 320,
                    decoration: BoxDecoration(
                      color: context.colors.background,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: context.colors.border),
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    double dx = 0;
                    double rotate = 0;
                    double opacity = 1.0;
                    Color? overlayColor;
                    IconData? overlayIcon;

                    final value = _controller.value;

                    if (value < 0.40) {
                      final progress = value / 0.40;
                      final curve = Curves.easeInOut.transform(progress);
                      dx = curve * -150;
                      rotate = curve * -0.15;
                      opacity = 1.0 - (curve * 0.5);
                      if (curve > 0.1) {
                        overlayColor = context.colors.primary;
                        overlayIcon = Icons.check_rounded;
                      }
                    } else if (value < 0.50) {
                      opacity = 0.0;
                    } else if (value < 0.90) {
                      final progress = (value - 0.50) / 0.40;
                      final curve = Curves.easeInOut.transform(progress);
                      dx = curve * 150;
                      rotate = curve * 0.15;
                      opacity = 1.0 - (curve * 0.5);
                      if (curve > 0.1) {
                        overlayColor = context.colors.error;
                        overlayIcon = Icons.delete_outline_rounded;
                      }
                    } else {
                      opacity = 0.0;
                    }

                    return Transform.translate(
                      offset: Offset(dx, 0),
                      child: Transform.rotate(
                        angle: rotate,
                        child: Opacity(
                          opacity: opacity,
                          child: Stack(
                            children: [
                              _DemoCard(),
                              if (overlayColor != null)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: overlayColor.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(32),
                                    ),
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          overlayIcon,
                                          color: overlayColor,
                                          size: 32,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    double dx = 0;
                    double dy = 80;
                    double scale = 1.0;
                    final value = _controller.value;

                    if (value < 0.40) {
                      final progress = value / 0.40;
                      dx = Curves.easeInOut.transform(progress) * -150;
                    } else if (value < 0.50) {
                      scale = 0.0;
                    } else if (value < 0.90) {
                      final progress = (value - 0.50) / 0.40;
                      dx = Curves.easeInOut.transform(progress) * 150;
                    } else {
                      scale = 0.0;
                    }

                    if (value > 0.40 && value < 0.50) scale = 0;
                    if (value > 0.90) scale = 0;

                    return Transform.translate(
                      offset: Offset(dx, dy),
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            Icons.touch_app_rounded,
                            size: 32,
                            color: context.colors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            '쓰윽 정리하기',
            style: AppTextTheme.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '왼쪽으로 넘겨서 사진을 유지하고\n오른쪽으로 넘겨서 쓰윽 삭제하세요.',
            textAlign: TextAlign.center,
            style: AppTextTheme.bodyLarge.copyWith(
              color: context.colors.textSecondary,
              height: 1.5,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _TrashGuidePage extends StatefulWidget {
  const _TrashGuidePage();

  @override
  State<_TrashGuidePage> createState() => _TrashGuidePageState();
}

class _TrashGuidePageState extends State<_TrashGuidePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: context.colors.background,
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.delete_outline_rounded,
                  size: 80,
                  color: context.colors.textSecondary,
                ),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final value = Curves.easeInOut.transform(_controller.value);
                    return Positioned(
                      top: 40 + (value * 10),
                      right: 40,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.colors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: context.colors.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            '안전한 휴지통',
            style: AppTextTheme.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '삭제한 사진은 휴지통에 보관됩니다.\n실수로 지워도 언제든 복구할 수 있어요.',
            textAlign: TextAlign.center,
            style: AppTextTheme.bodyLarge.copyWith(
              color: context.colors.textSecondary,
              height: 1.5,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _DemoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 320,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE0E7FF), Color(0xFFF0F4FF)],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.photo_size_select_actual_rounded,
                  size: 64,
                  color: context.colors.primary.withOpacity(0.3),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 80,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  const _BottomControls({
    required this.currentPage,
    required this.totalPages,
    required this.onNext,
  });

  final int currentPage;
  final int totalPages;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalPages, (index) {
              final isActive = index == currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color:
                      isActive ? context.colors.primary : context.colors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: context.colors.primary,
                foregroundColor: context.colors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                currentPage == totalPages - 1 ? '시작하기' : '다음',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
