// lib/providers.dart (RECTIFIED)

import 'package:flutter_riverpod/flutter_riverpod.dart';
// 🔑 Imports for Authentication Module
import 'core/services/auth_service.dart'; 
// 🔑 Imports for Course Module
import 'modules/course/service/course_service.dart'; 

// --- AUTHENTICATION PROVIDERS ---

// The authentication service provider
final firebaseAuthServiceProvider = Provider<AuthService>((ref) => AuthService());

// --- COURSE PROVIDERS ---

// 🔑 CRITICAL FIX: The Course service provider is explicitly typed
final courseServiceProvider = Provider<CourseService>((ref) => CourseService());

// NOTE: Add other service providers here if needed.