// lib/modules/auth/view/register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/user_model.dart';
import '../viewmodel/register_view_model.dart';


class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  // Set Trainer as the default registration role (or choose Learner)
  UserRole _selectedRole = UserRole.trainer; 

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerViewModelProvider);
    final viewModel = ref.read(registerViewModelProvider.notifier);
    final theme = Theme.of(context);

    // Listen for success or error
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
          const SnackBar(content: Text('Registration successful! Please login.')),
        );
        // Clear fields on success
        _emailController.clear();
        _passwordController.clear();
        // Do NOT pop here if you want them to log in right after registration
        // Navigator.of(context).pop(); 
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Join Coursehive',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Email Field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Password Field
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password (min 6 chars)',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              
              // Role Selection
              DropdownButtonFormField<UserRole>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Select Your Role',
                  prefixIcon: Icon(Icons.person_pin_outlined),
                ),
                items: UserRole.values
                    .where((role) => role != UserRole.unknown) 
                    .map((role) {
                      String roleName = role.toString().split('.').last;
                      return DropdownMenuItem(
                          value: role,
                          // Capitalize first letter: Trainer, Learner, Admin
                          child: Text(roleName.substring(0, 1).toUpperCase() + roleName.substring(1)),
                        );
                    })
                    .toList(),
                onChanged: (UserRole? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedRole = newValue;
                    });
                  }
                },
              ),
              
              const SizedBox(height: 32),

              // Register Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: state.isLoading
                    ? null
                    : () {
                        viewModel.register(
                          _emailController.text.trim(),
                          _passwordController.text.trim(),
                          _selectedRole,
                        );
                      },
                child: state.isLoading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Register', style: TextStyle(fontSize: 18)),
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