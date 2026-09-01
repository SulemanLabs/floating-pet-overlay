import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/streak_entity.dart';

enum StreakStatusFilter { all, active, completed, broken }

enum StreakDateFilter { allTime, today, thisWeek, thisMonth }

/// Combined status + date filter for the history screen. Kept in Riverpod
/// state (not duplicated per-widget) so every consumer of the filtered list
/// agrees on the current filter.
class StreakHistoryFilter {
  const StreakHistoryFilter({this.status = StreakStatusFilter.all, this.date = StreakDateFilter.allTime});

  final StreakStatusFilter status;
  final StreakDateFilter date;

  StreakHistoryFilter copyWith({StreakStatusFilter? status, StreakDateFilter? date}) {
    return StreakHistoryFilter(status: status ?? this.status, date: date ?? this.date);
  }
}

final streakFilterProvider = NotifierProvider<StreakFilterController, StreakHistoryFilter>(StreakFilterController.new);

class StreakFilterController extends Notifier<StreakHistoryFilter> {
  @override
  StreakHistoryFilter build() => const StreakHistoryFilter();

  void setStatus(StreakStatusFilter status) => state = state.copyWith(status: status);

  void setDate(StreakDateFilter date) => state = state.copyWith(date: date);
}

/// Applies [filter] to [history]. Pure function so it's independently
/// testable and reusable outside a provider.
List<StreakEntity> applyStreakFilter(List<StreakEntity> history, StreakHistoryFilter filter) {
  final now = DateTime.now();

  bool matchesStatus(StreakEntity streak) {
    return switch (filter.status) {
      StreakStatusFilter.all => true,
      StreakStatusFilter.active => streak.isActive,
      StreakStatusFilter.completed => streak.isCompleted,
      StreakStatusFilter.broken => streak.isBroken,
    };
  }

  bool matchesDate(StreakEntity streak) {
    switch (filter.date) {
      case StreakDateFilter.allTime:
        return true;
      case StreakDateFilter.today:
        return _isSameDay(streak.startDate, now);
      case StreakDateFilter.thisWeek:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final weekStartDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        return !streak.startDate.isBefore(weekStartDay);
      case StreakDateFilter.thisMonth:
        return streak.startDate.year == now.year && streak.startDate.month == now.month;
    }
  }

  return history.where((s) => matchesStatus(s) && matchesDate(s)).toList();
}

bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
