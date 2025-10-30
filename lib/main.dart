import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/home_page.dart';
import 'pages/dashboard_page.dart';
import 'services/auth_service.dart';
import 'widgets/background_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://xjnrmekknmrqfwewcmwt.supabase.co', // Your Supabase API URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhqbnJtZWtrbm1ycWZ3ZXdjbXd0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEwMjkwNTEsImV4cCI6MjA3NjYwNTA1MX0.YLABvrQ5uMGY3cVaPFVG9ojMjq_o0q3ibPMryU3UzPw', // Your Supabase anon key
  );
  
  runApp(const SpotCarzApp());
}

class SpotCarzApp extends StatelessWidget {
  const SpotCarzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spot Carz - Car Spotting App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[600],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    
    return BackgroundContainer(
      child: StreamBuilder<AuthState>(
        stream: authService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: CircularProgressIndicator(color: Colors.red),
              ),
            );
          }
          
          final session = snapshot.hasData ? snapshot.data!.session : null;
          
          if (session != null) {
            return const DashboardPage();
          } else {
            return const HomePage();
          }
        },
      ),
    );
  }
}
