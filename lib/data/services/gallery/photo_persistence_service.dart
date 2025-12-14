import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'photo_persistence_service.g.dart';

@riverpod
PhotoPersistenceService photoPersistenceService(
  PhotoPersistenceServiceRef ref,
) {
  return PhotoPersistenceService();
}

class PhotoPersistenceService {
  PhotoPersistenceService();

  static const _trashKey = 'gallery_trash_ids';
  static const _skippedKey = 'gallery_skipped_ids';

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

  // --- Trash Methods ---

  Future<Set<String>> loadTrashIds() async {
    return _loadIds(_trashKey);
  }

  Future<void> saveTrashIds(Set<String> ids) async {
    await _saveIds(_trashKey, ids);
  }

  // --- Skipped Methods ---

  Future<Set<String>> loadSkippedIds() async {
    return _loadIds(_skippedKey);
  }

  Future<void> saveSkippedIds(Set<String> ids) async {
    await _saveIds(_skippedKey, ids);
  }

  // --- Helper Methods ---

  Future<Set<String>> _loadIds(String key) async {
    final prefs = await _preferences;
    if (prefs == null) {
      return <String>{};
    }
    final stored = prefs.getStringList(key);
    return stored?.toSet() ?? <String>{};
  }

  Future<void> _saveIds(String key, Set<String> ids) async {
    final prefs = await _preferences;
    if (prefs == null) {
      return;
    }
    await prefs.setStringList(key, ids.toList());
  }
}
