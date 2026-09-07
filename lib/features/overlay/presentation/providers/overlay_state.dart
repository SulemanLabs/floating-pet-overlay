import '../../../pets/domain/entities/pet_entity.dart';
import '../../../settings/domain/entities/overlay_settings.dart';
import '../../domain/entities/overlay_status.dart';

class OverlayUiState {
  const OverlayUiState({
    required this.status,
    required this.overlayPermissionGranted,
    required this.selectedPet,
    required this.settings,
    this.errorMessage,
  });

  final OverlayStatus status;
  final bool overlayPermissionGranted;
  final PetEntity selectedPet;
  final OverlaySettings settings;
  final String? errorMessage;

  bool get isRunning => status == OverlayStatus.running;

  OverlayUiState copyWith({
    OverlayStatus? status,
    bool? overlayPermissionGranted,
    PetEntity? selectedPet,
    OverlaySettings? settings,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OverlayUiState(
      status: status ?? this.status,
      overlayPermissionGranted: overlayPermissionGranted ?? this.overlayPermissionGranted,
      selectedPet: selectedPet ?? this.selectedPet,
      settings: settings ?? this.settings,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
