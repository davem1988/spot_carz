import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/database_service.dart';
import 'login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  bool _isDeleting = false;

  Future<void> _confirmAndDeleteAccount() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null || currentUser.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No authenticated user found'), backgroundColor: Colors.red),
      );
      return;
    }

    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool confirmed = false;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Confirm Deletion', style: GoogleFonts.roboto(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This action will permanently delete your data. Enter your password to confirm.',
                style: GoogleFonts.roboto(color: Colors.grey[300]),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                style: GoogleFonts.roboto(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: GoogleFonts.roboto(color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Please enter your password' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.roboto(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                confirmed = true;
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600]),
            child: Text('Delete', style: GoogleFonts.roboto(color: Colors.white)),
          ),
        ],
      ),
    );

    if (!confirmed) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      // Reauthenticate by signing in with email + password
      await _authService.signIn(email: currentUser.email!, password: passwordController.text);

      // Delete all user-owned data
      await _databaseService.deleteCurrentUserData();

      // Attempt to delete the auth user via Edge Function (requires server-side service role)
      try {
        final client = Supabase.instance.client;
        await client.functions.invoke(
          'delete-user',
          body: {'user_id': currentUser.id},
        );
      } catch (e) {
        // Ignore if the function is not deployed; we still purge data and sign out
      }

      // Sign out and return to login
      await _authService.signOut();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your data has been deleted and you have been signed out.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Settings', style: GoogleFonts.roboto(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF1a1a1a),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: Text('Delete Account', style: GoogleFonts.roboto(color: Colors.white)),
                  subtitle: Text('Permanently delete your data', style: GoogleFonts.roboto(color: Colors.grey[400])),
                  trailing: _isDeleting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                      : const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                  onTap: _isDeleting ? null : _confirmAndDeleteAccount,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


