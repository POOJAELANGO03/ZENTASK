// lib/modules/auth/viewmodel/login_view_model.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_auth_service.dart';
// 🔑 FIX 1: Import the central providers file
import '../../../providers.dart'; 

// The State (Data) for the Login Screen
class LoginState {
  final bool isLoading;
  final String? errorMessage;

  LoginState({this.isLoading = false, this.errorMessage});

  LoginState copyWith({
    bool? isLoading,
    String? errorMessage,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// The ViewModel (StateNotifier)
class LoginViewModel extends StateNotifier<LoginState> {
  final FirebaseAuthService _authService;

  LoginViewModel(this._authService) : super(LoginState());

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // 🔑 FIX 2: Use named arguments (required by the service method signature)
      await _authService.signInWithEmailAndPassword(
        email: email, 
        password: password
      );

      state = state.copyWith(isLoading: false);
    } catch (e) {
      debugPrint('Login Error: $e');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

// The Riverpod Provider to expose the ViewModel
final loginViewModelProvider =
    StateNotifierProvider<LoginViewModel, LoginState>((ref) {
  // 🔑 FIX 3: Correctly watch the imported provider
  final authService = ref.watch(firebaseAuthServiceProvider);
  return LoginViewModel(authService);
});