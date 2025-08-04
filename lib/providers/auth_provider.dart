import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated }

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
    _authStateListener();
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  void _authStateListener() {
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        try {
          final userModel = await _getUserData(user.uid);
          state = AsyncValue.data(userModel);
        } catch (e) {
          // Handle authentication errors gracefully
          print('Auth error: $e');
          // Don't sign out automatically - let user handle the error
          // Only set error state without signing out to prevent infinite loops
          state = AsyncValue.error(e, StackTrace.current);
        }
      } else {
        state = const AsyncValue.data(null);
      }
    });
  }

  Future<UserModel?> _getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap({...doc.data()!, 'id': uid});
    }
    return null;
  }

  Future<void> checkAuthState() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userModel = await _getUserData(user.uid);
        state = AsyncValue.data(userModel);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      // Handle authentication errors gracefully
      print('Auth state check error: $e');
      // Don't automatically sign out - let the UI handle the error
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    try {
      state = const AsyncValue.loading();
      
      final result = await _authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
      );
      
      state = AsyncValue.data(result);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      // Throw user-friendly error messages
      if (e.toString().contains('email-already-in-use')) {
        throw 'An account with this email already exists. Please try logging in instead.';
      } else if (e.toString().contains('weak-password')) {
        throw 'Password is too weak. Please choose a stronger password.';
      } else if (e.toString().contains('invalid-email')) {
        throw 'Please enter a valid email address.';
      } else {
        throw 'Registration failed. Please try again.';
      }
    }
  }

  Future<void> signUpAdmin({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    try {
      state = const AsyncValue.loading();
      
      final result = await _authService.createAdminUserWithEmailAndPassword(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
      );
      
      state = AsyncValue.data(result);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      // Throw user-friendly error messages
      if (e.toString().contains('email-already-in-use')) {
        throw 'An account with this email already exists. Please try logging in instead.';
      } else if (e.toString().contains('weak-password')) {
        throw 'Password is too weak. Please choose a stronger password.';
      } else if (e.toString().contains('invalid-email')) {
        throw 'Please enter a valid email address.';
      } else {
        throw 'Admin registration failed. Please try again.';
      }
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      state = const AsyncValue.loading();
      
      final result = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      state = AsyncValue.data(result);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      // Throw user-friendly error messages
      if (e.toString().contains('user-not-found')) {
        throw 'No account found with this email. Please check your email or sign up.';
      } else if (e.toString().contains('wrong-password')) {
        throw 'Incorrect password. Please try again.';
      } else if (e.toString().contains('invalid-email')) {
        throw 'Please enter a valid email address.';
      } else if (e.toString().contains('user-disabled')) {
        throw 'This account has been disabled. Please contact support.';
      } else if (e.toString().contains('too-many-requests')) {
        throw 'Too many failed attempts. Please try again later.';
      } else {
        throw 'Login failed. Please check your credentials and try again.';
      }
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? profileImageUrl,
    List<String>? addresses,
  }) async {
    final currentUser = state.value;
    if (currentUser == null) return;

    try {
      final updatedUser = currentUser.copyWith(
        firstName: firstName ?? currentUser.firstName,
        lastName: lastName ?? currentUser.lastName,
        phoneNumber: phoneNumber ?? currentUser.phoneNumber,
        profileImageUrl: profileImageUrl ?? currentUser.profileImageUrl,
        addresses: addresses ?? currentUser.addresses,
      );
      
      await _authService.updateUserProfile(updatedUser);
      state = AsyncValue.data(updatedUser);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  UserModel? get currentUser => state.value;
  bool get isAuthenticated => currentUser != null;
  bool get isAdmin => currentUser?.isAdmin ?? false;
}

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier();
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).value;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.value != null;
});

final isAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.isAdmin ?? false;
}); 