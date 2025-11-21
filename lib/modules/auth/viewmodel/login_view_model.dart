// lib/modules/auth/viewmodel/login_view_model.dart (ALTERED)

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// 🔑 FIX: Import the new service file (now named auth_service)
import '../../../core/services/auth_service.dart'; 
import '../../../providers.dart'; 

// The State (Data) for the Login Screen
class LoginState {
  final bool isLoading;
  final String? errorMessage;
  // NOTE: isAuthenticated state is handled by the main app routing (authStateViewModelProvider)

  LoginState({this.isLoading = false, this.errorMessage});

  LoginState copyWith({
    bool? isLoading,
    String? errorMessage,
  }) {
    // Note: errorMessage is explicitly set to null unless passed a string
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, 
    );
  }
}

// The ViewModel (StateNotifier)
class LoginViewModel extends StateNotifier<LoginState> {
  // 🔑 FIX: Use the new AuthService class name
  final AuthService _authService; 

  LoginViewModel(this._authService) : super(LoginState());

  // 1. Email/Password Sign-In
  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final user = await _authService.signInWithEmail(email, password);
      
      // If user is null, sign-in failed (e.g., invalid credentials)
      if (user == null) {
         state = state.copyWith(isLoading: false, errorMessage: 'Invalid email or password. Please try again.');
         return;
      }

      state = state.copyWith(isLoading: false);
      // Navigation is handled by AuthStateViewModel
    } catch (e) {
      debugPrint('Login Error: $e');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
  
  // 2. Google Sign-In
  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _authService.signInWithGoogle(); 
      
      // If sign-in is successful (user is not null or cancelled), 
      // the AuthStateViewModel handles the navigation.

      state = state.copyWith(isLoading: false);
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      // Use the friendly message from the GoogleSignInException
      state = state.copyWith(isLoading: false, errorMessage: e.toString()); 
    }
  }
}

// The Riverpod Provider to expose the ViewModel
final loginViewModelProvider =
    StateNotifierProvider<LoginViewModel, LoginState>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  // 🔑 FIX: ViewModel now uses AuthService instance
  return LoginViewModel(authService as AuthService); 
});