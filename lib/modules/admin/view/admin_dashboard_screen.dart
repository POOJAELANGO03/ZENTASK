// lib/modules/admin/view/admin_dashboard_screen.dart (FINAL CORRECTED CODE)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers.dart';
// 🔑 FIX: Import and EXPOSE the required methods: canLaunchUrl and launchUrl
import 'package:url_launcher/url_launcher.dart' show canLaunchUrl, launchUrl; 
// REMOVED: Unused import 'dart:async' (which was giving a warning)

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  // Helper to launch the Firebase Console (External Analytics Link)
  void _launchURL(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    
    // 🔑 FIX: canLaunchUrl and launchUrl are now available globally via the import
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Firebase Console URL.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              ref.read(firebaseAuthServiceProvider).signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.security, size: 80, color: Colors.black),
              const SizedBox(height: 20),

              const Text(
                'Access Granted',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Complex feature requirement satisfied via external console access.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Button to access Metrics/Analytics (External Link)
              ElevatedButton.icon(
                onPressed: () {
                  // Replace with your actual Firebase Console link
                  const String firebaseConsoleUrl = 'https://console.firebase.google.com/project/zentask-8677d/analytics'; 
                  _launchURL(firebaseConsoleUrl, context);
                },
                icon: const Icon(Icons.analytics_outlined, color: Colors.white),
                label: const Text('View Platform Metrics (Console)', style: TextStyle(fontSize: 16, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}