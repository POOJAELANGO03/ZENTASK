// lib/providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/firebase_auth_service.dart';

// The authentication service provider
final firebaseAuthServiceProvider = Provider((ref) => FirebaseAuthService());

// You can add other global service providers here (e.g., TaskService, etc.)