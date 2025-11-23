// lib/modules/auth/viewmodel/register_view_model.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../model/user_model.dart';
import '../../../providers.dart';

class RegisterState {
  final bool isLoading;
  final String? errorMessage;
  final bool isRegistered;

  RegisterState({
    this.isLoading = false,
    this.errorMessage,
    this.isRegistered = false,
  });

  RegisterState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isRegistered,
  }) {
    return RegisterState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isRegistered: isRegistered ?? this.isRegistered,
    );
  }
}

class RegisterViewModel extends StateNotifier<RegisterState> {
  final AuthService _authService;

  RegisterViewModel(this._authService) : super(RegisterState());

  // FIXED! ROLE IS NOW PASSED CORRECTLY
  Future<void> register(
    String email,
    String password,
    UserRole role,
  ) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      isRegistered: false,
    );

    try {
      final roleString = role.toString().split('.').last;

      // CALL UPDATED AUTH SERVICE
      await _authService.signUpWithEmail(
        email,
        password,
        'New User',
        roleString, // <-- CORRECT ROLE SENT
      );

      state = state.copyWith(
        isLoading: false,
        isRegistered: true,
      );
    } catch (e) {
      debugPrint("REGISTER ERROR: $e");

      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
        isRegistered: false,
      );
    }
  }
}

final registerViewModelProvider =
    StateNotifierProvider<RegisterViewModel, RegisterState>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return RegisterViewModel(authService as AuthService);
});
