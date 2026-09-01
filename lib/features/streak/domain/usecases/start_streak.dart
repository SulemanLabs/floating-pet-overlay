import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../entities/streak_entity.dart';
import '../repositories/streak_repository.dart';

/// Starts a new streak. `duration == null` means "until I stop it" (open
/// ended, count-up); any other duration produces a timed countdown streak
/// with `endDate = startDate + duration`.
class StartStreakUseCase {
  const StartStreakUseCase(this._repository);

  final StreakRepository _repository;

  Future<StreakEntity> call({Duration? duration}) async {
    final current = await _repository.getCurrentStreak();
    if (current != null) {
      throw const StreakValidationFailure(
        'A streak is already active. Complete or break it before starting a new one.',
      );
    }

    final now = DateTime.now();
    final streak = StreakEntity(
      id: const Uuid().v4(),
      startDate: now,
      endDate: duration == null ? null : now.add(duration),
      duration: duration,
      status: StreakStatus.active,
    );

    await _repository.startStreak(streak);
    return streak;
  }
}
