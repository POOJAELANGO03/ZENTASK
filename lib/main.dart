

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'modules/auth/view/login_screen.dart';
import 'firebase_options.dart';
import 'providers.dart';
import 'modules/auth/model/user_model.dart'; 
import 'modules/auth/viewmodel/auth_state_view_model.dart'; 


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, 
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the combined provider for User and Role data
    final authData = ref.watch(authStateViewModelProvider); 

    return MaterialApp(
      title: 'Coursehive',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        ),
      ),
      debugShowCheckedModeBanner: false,
      
      home: authData.when(
        data: (UserModel? userModel) {
          if (userModel != null) {
            // User is logged in and role is determined: route to dashboard
            return _buildRoleBasedScreen(userModel.role, ref); 
          }
          // User is NOT logged in: route to Login Screen
          return LoginScreen();
        },
        // Reverting to showing a simple loading indicator during the initial check
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.blue))),
        ),
        // On error, show a loading indicator or route directly to login
        error: (err, stack) => Scaffold(
          appBar: AppBar(title: const Text('Loading Error')),
          body: Center(child: Text('Initial check failed: $err')),
        ),
      ),
    );
  }

  // Function to return the correct screen based on the UserRole (Unchanged)
  Widget _buildRoleBasedScreen(UserRole role, WidgetRef ref) {
    // These are temporary placeholder screens
    switch (role) {
      case UserRole.trainer: 
        return Scaffold(
                appBar: AppBar(title: const Text('Trainer Dashboard')),
                body: Center(child: _buildRoleView(role, ref)));
      case UserRole.learner: 
        return Scaffold(
                appBar: AppBar(title: const Text('Learner Dashboard')),
                body: Center(child: _buildRoleView(role, ref)));
      case UserRole.admin: 
        return Scaffold(
                appBar: AppBar(title: const Text('Admin Dashboard')),
                body: Center(child: _buildRoleView(role, ref)));
      case UserRole.unknown:
      default:
        return LoginScreen();
    }
  }

  Widget _buildRoleView(UserRole role, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Logged in as: ${role.toString().split('.').last.toUpperCase()}', style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            ref.read(firebaseAuthServiceProvider).signOut();
          },
          child: const Text('Logout'),
        ),
      ],
    );
  }
}