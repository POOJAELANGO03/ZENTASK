// lib/main.dart (FINAL ROUTING IMPLEMENTATION)

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'modules/auth/view/login_screen.dart';
import 'firebase_options.dart';
import 'providers.dart';
import 'modules/auth/model/user_model.dart'; 
import 'modules/auth/viewmodel/auth_state_view_model.dart'; 

// CRITICAL IMPORT: Dashboard Screens
import 'modules/course/view/trainer_dashboard_screen.dart'; 
import 'modules/course/view/learner_dashboard_screen.dart'; 
// 🔑 NEW IMPORT: Admin Dashboard
import 'modules/admin/view/admin_dashboard_screen.dart'; 


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
        primarySwatch: Colors.blue,fontFamily: 'LibertinusSans',
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        ),
      ),
      debugShowCheckedModeBanner: false,
      
      home: authData.when(
        data: (UserModel? userModel) {
          if (userModel != null) {
            // User is logged in and role is determined
            return _buildRoleBasedScreen(userModel.role, ref); 
          }
          // User is NOT logged in
          return LoginScreen();
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.blue))),
        ),
        error: (err, stack) => Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: Center(child: Text('An error occurred: $err')),
        ),
      ),
    );
  }

  // Function to return the correct screen based on the UserRole
  Widget _buildRoleBasedScreen(UserRole role, WidgetRef ref) {
    switch (role) {
      case UserRole.trainer: 
        return const TrainerDashboardScreen();
        
      case UserRole.learner: 
        return const LearnerDashboardScreen(); 
        
      case UserRole.admin: 
        // 🔑 FIX: Navigate to the actual Admin Dashboard
        return const AdminDashboardScreen();
        
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