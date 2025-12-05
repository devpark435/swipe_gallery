import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'trash_storage_service.g.dart';

class TrashStorageService {
  TrashStorageService();

  static const _storageKey = 'gallery_trash_ids';
  SharedPreferences? _prefs;

  Future<SharedPreferences?> get _preferences async {
    if (_prefs != null) {
      return _prefs;
    }
    try {
      _prefs = await SharedPreferences.getInstance();
      return _prefs;
    } catch (error, stackTrace) {
      debugPrint('⚠️ SharedPreferences 초기화 실패: $error');
      debugPrint('$stackTrace');
      return null;
    }
  }

  Future<Set<String>> loadTrashIds() async {
    final prefs = await _preferences;
    if (prefs == null) {
      return <String>{};
    }
    final stored = prefs.getStringList(_storageKey);
    return stored?.toSet() ?? <String>{};
  }

  Future<void> saveTrashIds(Set<String> ids) async {
    final prefs = await _preferences;
    if (prefs == null) {
      return;
    }
    await prefs.setStringList(_storageKey, ids.toList());
  }
}

@riverpod
TrashStorageService trashStorageService(TrashStorageServiceRef ref) {
  return TrashStorageService();
}
