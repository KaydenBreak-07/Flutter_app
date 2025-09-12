// File: lib/screens/sports_signup_page.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'sports_login_page.dart';
import 'athlete_profile_setup.dart';

class SportsSignUpPage extends StatefulWidget {
  const SportsSignUpPage({Key? key}) : super(key: key);

  @override
  State<SportsSignUpPage> createState() => _SportsSignUpPageState();
}

class _SportsSignUpPageState extends State<SportsSignUpPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Show error/success messages
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

  // Sign up with email/password
  Future<void> _signUpWithEmail() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showMessage('Please fill in all fields');
      return;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      _showMessage('Please enter a valid email address');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showMessage('Password must be at least 6 characters long');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
      );

      _showMessage('Account created successfully! Complete your profile to continue.', isError: false);

      // Navigate to athlete profile setup
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AthleteProfileSetup())
      );

    } catch (e) {
      _showMessage(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Sign up with Google
  Future<void> _signUpWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.signInWithGoogle();

      if (result != null) {
        _showMessage('Welcome ${result.user?.displayName ?? 'User'}! Complete your profile to continue.', isError: false);

        // Navigate to athlete profile setup
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AthleteProfileSetup())
        );
      }

    } catch (e) {
      _showMessage(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Navigate to login page
  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SportsLoginPage()),
    );
  }

  // Email validation
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
              Color(0xFFE3F2FD), // Light blue
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

                  // Sports illustration at the top
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A2E6D).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: const Icon(
                      Icons.sports_tennis,
                      size: 60,
                      color: Color(0xFF0A2E6D),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Welcome text
                  const Text(
                    'Join TalentTrack!',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A2E6D),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Sports Authority of India Talent Platform',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
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
                        // Name TextField
                        _buildTextField(
                          controller: _nameController,
                          hintText: 'Full Name',
                          prefixIcon: Icons.person_outline,
                        ),

                        const SizedBox(height: 16),

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
                          hintText: 'Password (min 6 characters)',
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

                        const SizedBox(height: 32),

                        // Sign Up Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signUpWithEmail,
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
                              'Create Account',
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

                        // Google Sign Up Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _signUpWithGoogle,
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
                                    color: Color(0xFF4285F4), // Google blue
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Sign Up with Google',
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

                  // Already have account
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          color: Colors.grey,
                        ),
                      ),
                      GestureDetector(
                        onTap: _navigateToLogin,
                        child: const Text(
                          'Log In',
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