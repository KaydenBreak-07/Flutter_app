// File: lib/screens/auth/role_selection_screen.dart
import 'package:flutter/material.dart';
import 'sports_login_page.dart';
import 'sports_signup_page.dart';
import 'sai_signup_page.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A2E6D),
              Color(0xFF1565C0),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // App Logo/Header
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: const Icon(
                    Icons.sports,
                    size: 60,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 32),

                const Text(
                  'TalentFind',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'SAI Talent Assessment Platform',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 60),

                const Text(
                  'Choose Your Role',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 32),

                // Athlete Role Card
                _buildRoleCard(
                  context: context,
                  title: 'Athlete',
                  subtitle: 'Record fitness tests & get assessed',
                  icon: Icons.sports_gymnastics,
                  features: [
                    'Record fitness test videos',
                    'Get AI-powered performance analysis',
                    'Track progress & improvements',
                    'View leaderboards & rankings',
                  ],
                  onTap: () => _showAuthOptions(context, 'athlete'),
                ),

                const SizedBox(height: 20),

                // SAI Official Role Card
                _buildRoleCard(
                  context: context,
                  title: 'SAI Official',
                  subtitle: 'Review athlete assessments & scout talent',
                  icon: Icons.admin_panel_settings,
                  features: [
                    'Access athlete performance dashboard',
                    'Review AI-processed results',
                    'Detect anomalies & flag issues',
                    'Shortlist athletes for trials',
                  ],
                  onTap: () => _showAuthOptions(context, 'sai_official'),
                ),

                const Spacer(),

                // Footer
                Text(
                  'Sports Authority of India',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAuthOptions(BuildContext context, String role) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              role == 'athlete' ? 'Athlete Access' : 'SAI Official Access',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A2E6D),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Choose an option to continue',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 32),

            // Sign Up Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (role == 'athlete') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AthleteSignupPage(userRole: 'athlete'),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SAISignUpPage(),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A2E6D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add),
                    SizedBox(width: 8),
                    Text(
                      'Create New Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Login Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SportsLoginPage(userRole: role),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF0A2E6D)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.login,
                      color: Color(0xFF0A2E6D),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Login to Existing Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A2E6D),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<String> features,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A2E6D).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    icon,
                    size: 30,
                    color: const Color(0xFF0A2E6D),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A2E6D),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF0A2E6D),
                  size: 20,
                ),
              ],
            ),

            const SizedBox(height: 20),

            ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0A2E6D),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      feature,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }
}