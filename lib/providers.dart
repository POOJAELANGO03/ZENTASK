// lib/providers.dart (ALTERED)

import 'package:flutter_riverpod/flutter_riverpod.dart';
// 🔑 FIX: Import the new service file name
import 'core/services/auth_service.dart'; 

// The authentication service provider
// 🔑 FIX: Reference the new AuthService class
final firebaseAuthServiceProvider = Provider((ref) => AuthService()); 

// You can add other global service providers here (e.g., TaskService, etc.)