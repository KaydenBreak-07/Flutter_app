// File: lib/screens/auth/sports_login_page.dart
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../athlete_profile_setup.dart';
import '../dashboard_screen.dart';
import '../sai/sai_dashboard.dart';
import '../admin/admin_dashboard.dart';
import '../sai/pending_approval_screen.dart';
import '../auth/role_selection_screen.dart'; // ADD: Import for role selection

class SportsLoginPage extends StatefulWidget {
  final String userRole;

  const SportsLoginPage({Key? key, required this.userRole}) : super(key: key);

  @override
  State<SportsLoginPage> createState() => _SportsLoginPageState();
}

class _SportsLoginPageState extends State<SportsLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _loginWithEmail() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showMessage('Please fill in all fields');
      return;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      _showMessage('Please enter a valid email address');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (result != null) {
        _showMessage('Welcome back!', isError: false);

        // Navigate based on user role
        await _navigateBasedOnRole(result.user!.uid);
      }

    } catch (e) {
      _showMessage(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.signInWithGoogle();

      if (result != null) {
        _showMessage('Welcome ${result.user?.displayName ?? 'User'}!', isError: false);

        // Save role if first time Google login
        await FirestoreService.setUserRole(result.user!.uid, widget.userRole);

        // Navigate based on user role
        await _navigateBasedOnRole(result.user!.uid);
      }

    } catch (e) {
      _showMessage(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // UPDATED: Enhanced debugging and fixed navigation
  Future<void> _navigateBasedOnRole(String userId) async {
    try {
      print('=== LOGIN NAVIGATION DEBUG START ===');
      print('User ID: $userId');

      // STEP 1: Check if user is admin FIRST (highest priority)
      final isAdmin = await FirestoreService.isUserAdmin(userId);
      print('Is Admin: $isAdmin');
      if (isAdmin) {
        print('Admin user detected: $userId');
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboard())
        );
        return; // Exit early for admin
      }

      // STEP 2: If not admin, get user role from collections
      final userData = await FirestoreService.getUserRole(userId);
      final userRole = userData['role'];
      final status = userData['status'];

      print('Full userData: $userData');
      print('Role: $userRole (${userRole?.runtimeType})');
      print('Status: $status (${status?.runtimeType})');

      // STEP 3: Handle null role - route to role selection or profile setup
      if (userRole == null || userRole.toString().isEmpty) {
        print('No role found, checking for existing athlete profile...');

        // Check if they have an athlete profile without proper role set
        try {
          final profile = await FirestoreService.getAthleteProfile();
          if (profile != null) {
            print('Found athlete profile, treating as athlete');
            // Set the role in database for future logins
            await FirestoreService.setUserRole(userId, 'athlete');

            if (profile.isComplete) {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardScreen())
              );
            } else {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const AthleteProfileSetup())
              );
            }
            return;
          }
        } catch (e) {
          print('Error checking athlete profile: $e');
        }

        // No profile found, send to role selection
        print('No profile found, routing to role selection');
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RoleSelectionScreen())
        );
        return;
      }

      // STEP 4: Handle based on role
      final roleString = userRole.toString().trim();

      if (roleString == 'athlete') {
        print('Processing athlete...');
        try {
          final profile = await FirestoreService.getAthleteProfile();
          if (profile?.isComplete == true) {
            print('Complete profile found, going to dashboard');
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DashboardScreen())
            );
          } else {
            print('Incomplete profile, going to setup');
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AthleteProfileSetup())
            );
          }
        } catch (e) {
          print('Error getting athlete profile: $e');
          // Default to profile setup on error
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AthleteProfileSetup())
          );
        }
      }
      else if (roleString == 'sai_official' || roleString == 'official') {
        print('Processing SAI official...');

        // Convert status to string and handle comparison properly
        final statusString = status?.toString().trim().toLowerCase() ?? 'pending';
        print('Status check: "$statusString"');

        switch (statusString) {
          case 'approved':
            print('Status approved - navigating to SAI Dashboard');
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const SAIDashboard())
            );
            break;

          case 'pending':
            print('Status pending - navigating to Pending Approval Screen');
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const PendingApprovalScreen())
            );
            break;

          case 'rejected':
            print('Status rejected - showing message and logging out');
            _showMessage('Your account application was rejected. Please contact support.');
            await _authService.signOut();
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const RoleSelectionScreen())
            );
            break;

          default:
            print('Unknown status: $statusString, defaulting to pending');
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const PendingApprovalScreen())
            );
            break;
        }
      }
      else {
        print('Unknown role: $roleString, routing to role selection');
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RoleSelectionScreen())
        );
      }

      print('=== LOGIN NAVIGATION DEBUG END ===');

    } catch (e) {
      print('Navigation error: $e');
      _showMessage('Error loading user data: $e');
      // Fallback to role selection on any error
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RoleSelectionScreen())
      );
    }
  }

  Future<void> _forgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      _showMessage('Please enter your email address first');
      return;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      _showMessage('Please enter a valid email address');
      return;
    }

    try {
      await _authService.resetPassword(email: _emailController.text.trim());
      _showMessage('Password reset email sent! Check your inbox.', isError: false);
    } catch (e) {
      _showMessage(e.toString());
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE3F2FD),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // Logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A2E6D).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Icon(
                      widget.userRole == 'athlete' ? Icons.sports_soccer : Icons.admin_panel_settings,
                      size: 60,
                      color: const Color(0xFF0A2E6D),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A2E6D),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    widget.userRole == 'athlete'
                        ? 'Sign in to continue your journey'
                        : 'Access your official dashboard',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Form container
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    margin: const EdgeInsets.symmetric(horizontal: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Email TextField
                        _buildTextField(
                          controller: _emailController,
                          hintText: 'Email Address',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 16),

                        // Password TextField
                        _buildTextField(
                          controller: _passwordController,
                          hintText: 'Password',
                          prefixIcon: Icons.lock_outline,
                          isPassword: true,
                          obscureText: !_isPasswordVisible,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Forgot password
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: _forgotPassword,
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                color: Color(0xFF0A2E6D),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _loginWithEmail,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0A2E6D),
                              foregroundColor: Colors.white,
                              elevation: 3,
                              shadowColor: const Color(0xFF0A2E6D).withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                                : const Text(
                              'Login',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Divider with "or"
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.grey.shade300,
                                thickness: 1,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'or',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.grey.shade300,
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Google Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _loginWithGoogle,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4285F4)),
                              ),
                            )
                                : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: const Icon(
                                    Icons.g_mobiledata,
                                    size: 24,
                                    color: Color(0xFF4285F4),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Continue with Google',
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 16,
                                    color: Color(0xFF333333),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Don't have account
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Don\'t have an account? ',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          color: Colors.grey,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context); // Go back to signup
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            color: Color(0xFF0A2E6D),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool isPassword = false,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade50,
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontFamily: 'Roboto',
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: const Color(0xFF0A2E6D).withOpacity(0.7),
          ),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}