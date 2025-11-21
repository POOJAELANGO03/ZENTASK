// lib/modules/auth/viewmodel/register_view_model.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_auth_service.dart';
import '../model/user_model.dart'; 
import '../../../providers.dart'; 

// THE RegisterState CLASS DEFINITION (State for the View)
class RegisterState {
  final bool isLoading;
  final String? errorMessage;
  final bool isRegistered;

  RegisterState({this.isLoading = false, this.errorMessage, this.isRegistered = false});

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

// The ViewModel (StateNotifier)
class RegisterViewModel extends StateNotifier<RegisterState> {
  final FirebaseAuthService _authService;

  RegisterViewModel(this._authService) : super(RegisterState());

  // Handles the registration logic
  Future<void> register(String email, String password, UserRole role) async {
    // Reset state and show loading
    state = state.copyWith(isLoading: true, errorMessage: null, isRegistered: false);

    try {
      // Call the service method, passing the role as a string
      await _authService.registerWithEmailAndRole(
        email: email, 
        password: password, 
        role: role.toString().split('.').last, // Convert enum to simple string ('trainer', 'learner', 'admin')
      );

      // Registration successful
      state = state.copyWith(isLoading: false, isRegistered: true);
    } catch (e) {
      debugPrint('Registration Error: $e');
      // Registration failed, show error message
      state = state.copyWith(isLoading: false, errorMessage: e.toString(), isRegistered: false);
    }
  }
}

// The Riverpod Provider to expose the ViewModel 
final registerViewModelProvider =
    StateNotifierProvider<RegisterViewModel, RegisterState>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return RegisterViewModel(authService);
});