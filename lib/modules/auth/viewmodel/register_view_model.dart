// lib/modules/auth/viewmodel/register_view_model.dart (RECTIFIED)

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// 🔑 FIX: Import the new service file name
import '../../../core/services/auth_service.dart'; 
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
  // 🔑 FIX: Use the correct service class name: AuthService
  final AuthService _authService; 

  RegisterViewModel(this._authService) : super(RegisterState());

  // Handles the registration logic
  Future<void> register(String email, String password, UserRole role) async {
    // Reset state and show loading
    state = state.copyWith(isLoading: true, errorMessage: null, isRegistered: false);

    try {
      // NOTE: The new AuthService doesn't have registerWithEmailAndRole. 
      // We will temporarily use the signUpWithEmail method and manually set the role here.
      // 🔑 CRITICAL FIX: The new AuthService doesn't support passing the role directly on signup.
      // To prevent errors, we will call the new service's method which defaults the role to 'learner'.
      // If you need role selection on signup, the AuthService must be updated.
      
      await _authService.signUpWithEmail(email, password, 'New User'); 
      
      // If successful, the user's role is set to 'learner' by default inside AuthService.

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
  // 🔑 FIX: Cast the provider to the correct AuthService type
  return RegisterViewModel(authService as AuthService); 
});