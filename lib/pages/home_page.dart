import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              children: [
                const SizedBox(height: 10),
                // App Logo/Title
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.directions_car,
                        size: 60,
                        color: Colors.red[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'SPOT CARZ',
                        style: GoogleFonts.orbitron(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Track Your Dream Cars',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          color: Colors.grey[300],
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Features Section
                Column(
                  children: [
                    _buildFeatureCard(
                      icon: Icons.camera_alt,
                      title: 'Spot Cars',
                      description: 'Capture and catalog luxury, rare, and ultra-sport cars',
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 10),
                    _buildFeatureCard(
                      icon: Icons.collections,
                      title: 'Your Collection',
                      description: 'Organize cars by brand and track your progress',
                      color: Colors.green,
                    ),
                    const SizedBox(height: 10),
                    _buildFeatureCard(
                      icon: Icons.speed,
                      title: 'Sport Car Focus',
                      description: 'Specialized for high-performance and luxury vehicles',
                      color: Colors.orange,
                    ),
                  ],
                ),
                
                const SizedBox(height: 70),
                
                // Get Started Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 8,
                    ),
                    child: Text(
                      'GET STARTED',
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 5),
                
                // Login Link
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                    );
                  },
                  child: Text(
                    'Already have an account? Sign In',
                    style: GoogleFonts.roboto(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                  ),
                ),
                
                const SizedBox(height: 8), // Add extra space at bottom
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.grey[300],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
