// lib/modules/auth/view/learner_registration_screen.dart 
// FIXED: MediaQuery error, Overflow error, Clean error message

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/model/user_model.dart';
import '../viewmodel/register_view_model.dart';

class LearnerRegistrationScreen extends ConsumerStatefulWidget {
  const LearnerRegistrationScreen({super.key});

  @override
  ConsumerState<LearnerRegistrationScreen> createState() =>
      _LearnerRegistrationScreenState();
}

class _LearnerRegistrationScreenState
    extends ConsumerState<LearnerRegistrationScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final UserRole _selectedRole = UserRole.learner;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage("assets/images/learner.jpg"), context);
  }

  void _register() {
    if (_emailController.text.trim().isEmpty) {
      _showError("Please enter email");
      return;
    }
    if (_passwordController.text.trim().isEmpty) {
      _showError("Please enter password");
      return;
    }
    if (_passwordController.text.trim().length < 6) {
      _showError("Password must be at least 6 characters");
      return;
    }

    ref.read(registerViewModelProvider.notifier).register(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _selectedRole,
        );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color.fromARGB(255, 15, 14, 14)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerViewModelProvider);
    final theme = Theme.of(context);

    ref.listen<RegisterState>(registerViewModelProvider, (previous, current) {
      if (current.errorMessage != null) {
        _showError("Registration failed: ${current.errorMessage}");
      } else if (current.isRegistered) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Learner account created! Please login.')),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Register as LEARNER'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Image.asset('assets/images/learner.jpg', height: 290),
              ),
              const SizedBox(height: 82),

              Text(
                'Join as a Learner',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined, color: Colors.black),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password (min 6 chars)',
                  prefixIcon: Icon(Icons.lock_outline, color: Colors.black),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: state.isLoading ? null : _register,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                child: state.isLoading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                    : const Text(
                        'Register Learner',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
