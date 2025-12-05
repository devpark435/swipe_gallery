import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pocket_photo/presentation/features/gallery/providers/gallery_provider.dart';
import 'package:pocket_photo/theme/app_color_theme.dart';
import 'package:pocket_photo/theme/app_text_theme.dart';

class GalleryShell extends ConsumerWidget {
  const GalleryShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trashCount = ref
        .watch(galleryNotifierProvider)
        .maybeWhen(data: (gallery) => gallery.trash.length, orElse: () => 0);

    Widget buildNavIcon({required Widget icon}) {
      if (trashCount == 0) {
        return icon;
      }

      return Stack(
        clipBehavior: Clip.none,
        children: [
          icon,
          Positioned(
            right: -6,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColorTheme.error,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 18),
              child: Text(
                trashCount > 99 ? '99 +' : '$trashCount',
                style: AppTextTheme.labelLarge.copyWith(fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        backgroundColor: AppColorTheme.surface,
        indicatorColor: AppColorTheme.primary.withOpacity(0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return (isSelected ? AppTextTheme.bodyLarge : AppTextTheme.bodyMedium)
              .copyWith(
                color:
                    isSelected
                        ? AppColorTheme.primary
                        : AppColorTheme.textSecondary,
              );
        }),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library_rounded),
            label: '갤러리',
          ),
          NavigationDestination(
            icon: buildNavIcon(icon: const Icon(Icons.delete_outline)),
            selectedIcon: buildNavIcon(icon: const Icon(Icons.delete_rounded)),
            label: '휴지통',
          ),
        ],
      ),
    );
  }
}
