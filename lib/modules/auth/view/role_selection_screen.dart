// lib/modules/auth/view/role_selection_screen.dart (ALTERED - Pure White/B&W Theme)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'trainer_registration_screen.dart'; 
import 'learner_registration_screen.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Role'),
        backgroundColor: Colors.white,
        elevation: 1, // Keep a subtle elevation
        foregroundColor: Colors.black, // Ensure title is black
      ),
      backgroundColor: Colors.white, // 🔑 PURE WHITE BACKGROUND
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Are you here to Teach or to Learn?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              
              // 1. Trainer Role Selection Card
              _buildRoleCard(
                context,
                role: 'Trainer',
                description: 'Upload courses, manage content, and earn income.',
                icon: Icons.school_outlined,
                color: Colors.grey.shade50, // 🔑 LIGHT GRAY CARD COLOR
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TrainerRegistrationScreen()),
                  );
                },
              ),
              const SizedBox(height: 30),

              // 2. Learner Role Selection Card
              _buildRoleCard(
                context,
                role: 'Learner',
                description: 'Explore courses, view lessons, and track progress.',
                icon: Icons.book_online_outlined,
                color: Colors.grey.shade100, // 🔑 SLIGHTLY DARKER LIGHT GRAY CARD COLOR
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LearnerRegistrationScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String role,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1), // Slightly stronger shadow
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.black), // 🔑 BLACK ICON
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),
                  Text(
                    role,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black, // 🔑 BLACK TEXT
                    ),
                  ),
                  Text(description, style: TextStyle(color: Colors.grey.shade700)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}