// lib/modules/auth/view/login_screen.dart (ALTERED - Pure White Background)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodel/login_view_model.dart';
import 'role_selection_screen.dart'; 


// Converted from StatefulWidget to a stateless ConsumerWidget
class LoginScreen extends ConsumerWidget {
  LoginScreen({super.key});

  final TextEditingController _emailController = TextEditingController(); 
  final TextEditingController _passwordController = TextEditingController();

  // Local state for password visibility (must be managed using local state)
  final StateProvider<bool> isPasswordVisibleProvider = StateProvider<bool>((ref) => false);

  void _login(WidgetRef ref) {
    FocusScope.of(ref.context).unfocus();
    
    ref.read(loginViewModelProvider.notifier).signIn(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
  }

  void _signInWithGoogle(WidgetRef ref) {
    FocusScope.of(ref.context).unfocus();
    
    ref.read(loginViewModelProvider.notifier).signInWithGoogle();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loginViewModelProvider);
    final isPasswordVisible = ref.watch(isPasswordVisibleProvider);
    final isPasswordVisibleNotifier = ref.read(isPasswordVisibleProvider.notifier);


    return Scaffold(
      backgroundColor: Colors.white, // 🔑 PURE WHITE BACKGROUND
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                const Text(
                  "WELCOME TO COURSEHIVE!",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 40),
                _buildTextField(
                  controller: _emailController,
                  hintText: 'Enter your email',
                  obscureText: false, 
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _passwordController,
                  hintText: 'Enter your password',
                  obscureText: !isPasswordVisible, 
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      isPasswordVisibleNotifier.state = !isPasswordVisible;
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: Implement Forgot Password functionality
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                if (state.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Center(
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                
                if (state.isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _login(ref), 
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black, // PURE BLACK BUTTON
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                const SizedBox(height: 30),
                
                _buildSocialLoginSection(ref, state.isLoading),
                
                const SizedBox(height: 30),
                _buildBottomNavigation(context),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI Builder Methods ---

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 20,
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _buildSocialLoginSection(WidgetRef ref, bool isLoading) {
    return Column(
      children: [
        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'Or Login with',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : () => _signInWithGoogle(ref), 
            icon: Image.asset('assets/images/google_signlogo.png', height: 22.0),
            label: const Text('Sign in with Google'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have an account?"),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RoleSelectionScreen()), 
            );
          },
          child: const Text(
            'Register Now',
            style: TextStyle(
              color: Color(0xFF2962FF), // Keeping primary color for the link
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}