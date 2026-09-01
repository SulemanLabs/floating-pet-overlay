import 'package:hive/hive.dart';

import '../models/streak_model.dart';

/// Thin wrapper over the `streaks` Hive box — the only place in the streak
/// feature that touches Hive directly, mirroring `TaskLocalDataSource`'s role
/// for `LocalStorage`.
class StreakLocalDataSource {
  StreakLocalDataSource(this._box);

  final Box<StreakModel> _box;

  List<StreakModel> getAll() {
    final models = <StreakModel>[];
    for (final key in _box.keys) {
      try {
        final model = _box.get(key);
        if (model != null) models.add(model);
      } catch (_) {
        // A single corrupted record must not take down the whole history.
        continue;
      }
    }
    return models;
  }

  StreakModel? getById(String id) {
    try {
      return _box.get(id);
    } catch (_) {
      return null;
    }
  }

  Future<void> put(StreakModel model) => _box.put(model.id, model);

  Future<void> delete(String id) => _box.delete(id);
}
