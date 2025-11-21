// lib/modules/auth/view/learner_registration_screen.dart (ALTERED - Image Size & White BG)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/model/user_model.dart';
import '../viewmodel/register_view_model.dart';

class LearnerRegistrationScreen extends ConsumerStatefulWidget {
  const LearnerRegistrationScreen({super.key});

  @override
  ConsumerState<LearnerRegistrationScreen> createState() => _LearnerRegistrationScreenState();
}

class _LearnerRegistrationScreenState extends ConsumerState<LearnerRegistrationScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final UserRole _selectedRole = UserRole.learner; 

  void _register() {
    ref.read(registerViewModelProvider.notifier).register(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _selectedRole,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerViewModelProvider);
    final theme = Theme.of(context);

    ref.listen<RegisterState>(registerViewModelProvider, (previous, current) {
      if (current.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(current.errorMessage!),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      } else if (current.isRegistered) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Learner account created! Please login.')),
        );
        Navigator.of(context).popUntil((route) => route.isFirst); 
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register as LEARNER'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black, // Ensure title is black
      ),
      backgroundColor: Colors.white, // 🔑 PURE WHITE BACKGROUND
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🔑 IMAGE HEIGHT INCREASED
              Center(
                child: Image.asset(
                  'assets/images/learner.jpg', 
                  height: 200, // Increased height
                ),
              ),
              const SizedBox(height: 24),
              
              Text(
                'Join as a Learner',
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.black),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined, color: Colors.black)),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password (min 6 chars)', prefixIcon: Icon(Icons.lock_outline, color: Colors.black)),
                obscureText: true,
              ),
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: state.isLoading ? null : _register,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black), // PURE BLACK BUTTON
                child: state.isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Register Learner', style: TextStyle(fontSize: 18, color: Colors.white)),
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