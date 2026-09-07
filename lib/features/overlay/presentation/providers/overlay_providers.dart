import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/platform/overlay_platform_events.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../pets/presentation/providers/pet_providers.dart';
import '../../../settings/domain/entities/overlay_settings.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../data/repositories/overlay_repository_impl.dart';
import '../../domain/entities/overlay_status.dart';
import '../../domain/repositories/overlay_repository.dart';
import 'overlay_state.dart';

final overlayRepositoryProvider = Provider<OverlayRepository>((ref) {
  return OverlayRepositoryImpl(ref.watch(overlayPlatformBridgeProvider));
});

final overlayControllerProvider = AsyncNotifierProvider<OverlayController, OverlayUiState>(OverlayController.new);

class OverlayController extends AsyncNotifier<OverlayUiState> {
  StreamSubscription<OverlayPlatformEvent>? _eventSubscription;

  OverlayRepository get _repository => ref.read(overlayRepositoryProvider);

  @override
  Future<OverlayUiState> build() async {
    final petRepository = ref.read(petRepositoryProvider);
    final settingsRepository = ref.read(settingsRepositoryProvider);

    final selectedPet = await petRepository.getSelectedPet();
    final settings = await settingsRepository.getSettings();
    final overlayPermissionGranted = await _repository.isOverlayPermissionGranted();

    _eventSubscription?.cancel();
    _eventSubscription = _repository.events.listen(_onPlatformEvent);
    ref.onDispose(() => _eventSubscription?.cancel());

    return OverlayUiState(
      status: OverlayStatus.stopped,
      overlayPermissionGranted: overlayPermissionGranted,
      selectedPet: selectedPet,
      settings: settings,
    );
  }

  void _onPlatformEvent(OverlayPlatformEvent event) {
    final current = state.value;
    if (current == null) return;
    switch (event) {
      case OverlayStartedEvent():
        state = AsyncData(current.copyWith(status: OverlayStatus.running, clearError: true));
      case OverlayStoppedEvent():
        state = AsyncData(current.copyWith(status: OverlayStatus.stopped));
      case PermissionChangedEvent(:final granted):
        state = AsyncData(current.copyWith(overlayPermissionGranted: granted));
      case OverlayErrorEvent(:final message):
        state = AsyncData(current.copyWith(status: OverlayStatus.stopped, errorMessage: message));
      case PetTappedEvent():
      case PetDoubleTappedEvent():
        // No-op in this build — reaction system (Section 16) hooks in here later.
        break;
    }
  }

  Future<void> refreshPermissions() async {
    final current = state.value;
    if (current == null) return;
    final overlayGranted = await _repository.isOverlayPermissionGranted();
    state = AsyncData(current.copyWith(overlayPermissionGranted: overlayGranted));
  }

  Future<void> requestOverlayPermission() async {
    await _repository.requestOverlayPermission();
  }

  Future<void> selectPet(String petId) async {
    final current = state.value;
    if (current == null) return;
    await ref.read(selectPetUseCaseProvider).call(petId);
    final pets = await ref.read(getPetsProvider).call();
    final selected = pets.firstWhere((p) => p.id == petId, orElse: () => current.selectedPet);
    state = AsyncData(current.copyWith(selectedPet: selected));
    await _pushLiveUpdate(current: current.copyWith(selectedPet: selected), applyPet: true);
  }

  Future<void> updateSettings(OverlaySettings Function(OverlaySettings) transform) async {
    final current = state.value;
    if (current == null) return;
    final updated = transform(current.settings);
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
    final next = current.copyWith(settings: updated);
    state = AsyncData(next);
    await _pushLiveUpdate(current: next);
  }

  /// Applies changed pet/settings to a running overlay immediately, and
  /// always mirrors state into native storage for boot auto-restore —
  /// regardless of whether the overlay is currently running.
  Future<void> _pushLiveUpdate({required OverlayUiState current, bool applyPet = false}) async {
    try {
      if (current.isRunning) {
        if (applyPet) {
          await _repository.updatePet(current.selectedPet);
        } else {
          await _repository.updateSize(current.settings.sizePercent);
          await _repository.updateOpacity(current.settings.opacity);
          await _repository.updateSpeed(current.settings.speed);
          await _repository.setMovementEnabled(current.settings.movementEnabled);
        }
      }
      await _repository.syncSettings(pet: current.selectedPet, settings: current.settings);
    } on Failure catch (e) {
      state = AsyncData(current.copyWith(errorMessage: e.message));
    }
  }

  Future<void> startOverlay() async {
    final current = state.value;
    if (current == null) return;

    if (!current.overlayPermissionGranted) {
      state = AsyncData(current.copyWith(errorMessage: 'Overlay permission is required to start the pet.'));
      return;
    }

    state = AsyncData(current.copyWith(status: OverlayStatus.starting, clearError: true));
    try {
      await _repository.startOverlay(pet: current.selectedPet, settings: current.settings);
      // Confirmation arrives asynchronously via `overlayStarted`; optimistically
      // reflect it here too so slow devices don't look stuck on "starting".
      final latest = state.value ?? current;
      state = AsyncData(latest.copyWith(status: OverlayStatus.running));
    } on Failure catch (e) {
      final latest = state.value ?? current;
      state = AsyncData(latest.copyWith(status: OverlayStatus.stopped, errorMessage: e.message));
    }
  }

  Future<void> stopOverlay() async {
    final current = state.value;
    if (current == null) return;
    try {
      await _repository.stopOverlay();
      final latest = state.value ?? current;
      state = AsyncData(latest.copyWith(status: OverlayStatus.stopped));
    } on Failure catch (e) {
      final latest = state.value ?? current;
      state = AsyncData(latest.copyWith(errorMessage: e.message));
    }
  }
}
