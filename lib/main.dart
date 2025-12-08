import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swipe_gallery/presentation/features/permission/widgets/permission_gate.dart';
import 'package:swipe_gallery/router/app_router.dart';
import 'package:swipe_gallery/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: SwipeGalleryApp()));
}

class SwipeGalleryApp extends ConsumerWidget {
  const SwipeGalleryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Swipe Gallery',
      theme: AppTheme.theme,
      routerConfig: router,
      builder: (context, child) {
        return PermissionGate(child: child ?? const SizedBox.shrink());
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
