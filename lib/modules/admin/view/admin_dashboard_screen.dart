// lib/modules/admin/view/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../providers.dart';
import '../viewmodel/admin_stats_viewmodel.dart';

// Same theme as trainer/learner
const Color primaryColor = Color(0xFF9ECAD6);
const Color backgroundColor = Color(0xFFE9E3DF);

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  Future<void> _openFirebaseConsole(BuildContext context) async {
    final Uri url = Uri.parse(
      "https://console.firebase.google.com/u/0/project/zentask-8677d/analytics",
    );

    final success = await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );

    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Could not open Firebase Console URL."),
        ),
      );
    }
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminStatsViewModelProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: primaryColor,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(adminStatsViewModelProvider.notifier).loadStats();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(firebaseAuthServiceProvider).signOut();
            },
          ),
        ],
      ),
      body: stats.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.black),
            )
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Key Platform Metrics",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ------------ ROW 1: USERS & TRAINERS ------------
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: "Total Users",
                          value: stats.totalUsers.toString(),
                          icon: Icons.group, // filled users icon
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: "Trainers",
                          value: stats.trainerCount.toString(),
                          icon: Icons.school, // trainers/teachers
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ------------ ROW 2: LEARNERS & ADMINS ------------
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: "Learners",
                          value: stats.learnerCount.toString(),
                          icon: Icons.menu_book, // learners/students
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: "Admins",
                          value: stats.adminCount.toString(),
                          icon: Icons.admin_panel_settings, // admin shield
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ------------ ROW 3: COURSES & ENROLLMENTS ------------
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: "Active Courses",
                          value: stats.totalCourses.toString(),
                          icon: Icons.library_books, // courses
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: "Total Enrollments",
                          value: stats.totalEnrollments.toString(),
                          icon: Icons.group_add, // enrollments
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    "External Analytics",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "For detailed charts and real-time usage metrics, open the Firebase Analytics console.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openFirebaseConsole(context),
                      icon: const Icon(Icons.analytics, color: Colors.black),
                      label: const Text(
                        "Open Firebase Analytics Console",
                        style: TextStyle(color: Colors.black),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  if (stats.error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      stats.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ]
                ],
              ),
            ),
    );
  }
}
