import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();
  
  SupabaseService._();
  
  SupabaseClient get client => Supabase.instance.client;
  
  User? get currentUser => client.auth.currentUser;
  
  bool get isLoggedIn => currentUser != null;
  
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
}
