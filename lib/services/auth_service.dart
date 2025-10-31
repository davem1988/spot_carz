import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AuthService {
  final SupabaseService _supabase = SupabaseService.instance;
  
  // Expose supabase client for session checking
  SupabaseClient get client => _supabase.client;
  
  User? get currentUser => _supabase.currentUser;
  bool get isLoggedIn => _supabase.isLoggedIn;
  Stream<AuthState> get authStateChanges => _supabase.authStateChanges;
  
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      debugPrint('AuthService: Attempting sign up for $email');
      final response = await _supabase.client.auth.signUp(
        email: email,
        password: password,
        data: fullName != null ? {'full_name': fullName} : null,
      );
      debugPrint('AuthService: Sign up response - User: ${response.user?.email}, Session: ${response.session != null}');
      return response;
    } catch (e) {
      debugPrint('AuthService: Sign up error: $e');
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }
  
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('AuthService: Attempting sign in for $email');
      final response = await _supabase.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      debugPrint('AuthService: Sign in response - User: ${response.user?.email}, Session: ${response.session != null}');
      return response;
    } catch (e) {
      debugPrint('AuthService: Sign in error: $e');
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }
  
  Future<void> signOut() async {
    try {
      await _supabase.client.auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }
  
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.client.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Password reset failed: ${e.toString()}');
    }
  }
  
  Future<void> updateProfile({
    String? fullName,
    String? avatarUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      
      await _supabase.client.auth.updateUser(
        UserAttributes(data: updates),
      );
    } catch (e) {
      throw Exception('Profile update failed: ${e.toString()}');
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      debugPrint('AuthService: Attempting Google sign in');
      await _supabase.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'spotcarz://login-callback',
        authScreenLaunchMode: LaunchMode.platformDefault,
      );
      debugPrint('AuthService: Google sign in initiated - redirectTo: spotcarz://login-callback');
      
      // Supabase will process OAuth callback and redirect to our deep link with tokens
      // The app will receive the deep link and Supabase SDK should process it automatically
      return true;
    } catch (e) {
      debugPrint('AuthService: Google sign in error: $e');
      throw Exception('Google sign in failed: ${e.toString()}');
    }
  }
}
