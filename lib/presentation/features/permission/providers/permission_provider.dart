import 'package:photo_manager/photo_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'permission_provider.g.dart';

enum GalleryPermissionStatus {
  granted,
  limited,
  needsRequest,
  denied,
  restricted,
}

extension GalleryPermissionStatusX on GalleryPermissionStatus {
  bool get isGranted =>
      this == GalleryPermissionStatus.granted ||
      this == GalleryPermissionStatus.limited;

  bool get requiresSettings =>
      this == GalleryPermissionStatus.denied ||
      this == GalleryPermissionStatus.restricted;
}

const _permissionOption = PermissionRequestOption(
  iosAccessLevel: IosAccessLevel.readWrite,
  androidPermission: AndroidPermission(
    type: RequestType.image,
    mediaLocation: false,
  ),
);

@riverpod
class GalleryPermissionNotifier extends _$GalleryPermissionNotifier {
  @override
  FutureOr<GalleryPermissionStatus> build() async {
    final status = await _getPermissionState();
    return _mapPermission(status);
  }

  Future<void> refreshStatus() async {
    state = const AsyncLoading();
    final status = await _getPermissionState();
    state = AsyncData(_mapPermission(status));
  }

  Future<void> requestPermission() async {
    state = const AsyncLoading();
    final status = await PhotoManager.requestPermissionExtend(
      requestOption: _permissionOption,
    );
    state = AsyncData(_mapPermission(status));
  }

  Future<void> openSettings() async {
    await PhotoManager.openSetting();
  }

  Future<PermissionState> _getPermissionState() {
    return PhotoManager.getPermissionState(requestOption: _permissionOption);
  }

  GalleryPermissionStatus _mapPermission(PermissionState state) {
    switch (state) {
      case PermissionState.authorized:
        return GalleryPermissionStatus.granted;
      case PermissionState.limited:
        return GalleryPermissionStatus.limited;
      case PermissionState.restricted:
        return GalleryPermissionStatus.restricted;
      case PermissionState.denied:
        return GalleryPermissionStatus.denied;
      case PermissionState.notDetermined:
        return GalleryPermissionStatus.needsRequest;
    }
  }
}
