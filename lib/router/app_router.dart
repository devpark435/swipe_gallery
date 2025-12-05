import 'package:go_router/go_router.dart';
import 'package:swipe_gallery/presentation/features/gallery/screens/gallery_shell.dart';
import 'package:swipe_gallery/presentation/features/gallery/screens/gallery_swipe_screen.dart';
import 'package:swipe_gallery/presentation/features/gallery/screens/trash_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

enum AppRoute { gallery, trash }

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: '/gallery',
    routes: [
      StatefulShellRoute.indexedStack(
        builder:
            (context, state, navigationShell) =>
                GalleryShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/gallery',
                name: AppRoute.gallery.name,
                builder: (context, state) => const GallerySwipeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/trash',
                name: AppRoute.trash.name,
                builder: (context, state) => const TrashScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
