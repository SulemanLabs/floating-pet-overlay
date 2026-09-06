import 'package:hive/hive.dart';

/// Thin wrapper over the `prefs` Hive box, for the scalar key/value settings
/// that don't warrant a typed box of their own (overlay settings, the
/// selected pet id). Hive stores primitives natively, so no adapter is
/// needed here — only the typed per-feature boxes (tasks, pets, streaks)
/// register one.
class LocalStorage {
  LocalStorage(this._box);

  final Box _box;

  static Future<LocalStorage> create() async {
    final box = Hive.isBoxOpen('prefs') ? Hive.box('prefs') : await Hive.openBox('prefs');
    return LocalStorage(box);
  }

  String? getString(String key) => _box.get(key) as String?;

  Future<void> setString(String key, String value) => _box.put(key, value);

  double? getDouble(String key) => (_box.get(key) as num?)?.toDouble();

  Future<void> setDouble(String key, double value) => _box.put(key, value);

  bool? getBool(String key) => _box.get(key) as bool?;

  Future<void> setBool(String key, bool value) => _box.put(key, value);

  Future<void> remove(String key) => _box.delete(key);
}
