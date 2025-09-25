// File: lib/screens/auth/sai_signup_page.dart
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../sai/pending_approval_screen.dart'; // Changed from sai_dashboard to pending_approval_screen

class SAISignUpPage extends StatefulWidget {
  const SAISignUpPage({Key? key}) : super(key: key);

  @override
  State<SAISignUpPage> createState() => _SAISignUpPageState();
}

class _SAISignUpPageState extends State<SAISignUpPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _departmentController = TextEditingController();
  final _authService = AuthService();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String _selectedDesignation = '';

  final List<String> _designations = [
    'Director General',
    'Joint Director',
    'Deputy Director',
    'Assistant Director',
    'Sports Officer',
    'Talent Scout',
    'Coach',
    'Sports Scientist',
    'Data Analyst',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _employeeIdController.dispose();
    _departmentController.dispose();
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

  Future<void> _signUpWithEmail() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _employeeIdController.text.trim().isEmpty ||
        _departmentController.text.trim().isEmpty ||
        _selectedDesignation.isEmpty) {
      _showMessage('Please fill in all fields');
      return;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      _showMessage('Please enter a valid official email address');
      return;
    }

    if (!_isValidOfficialEmail(_emailController.text.trim())) {
      _showMessage('Please use an official government email address');
      return;
    }

    if (_passwordController.text.length < 8) {
      _showMessage('Password must be at least 8 characters long');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create Firebase Auth account
      final result = await _authService.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
      );

      if (result?.user != null) {
        final userId = result!.user!.uid;

        // Set user role first
        await FirestoreService.setUserRole(userId, 'sai_official');

        // Save SAI official profile to Firestore
        final officialData = {
          'uid': userId,
          'fullName': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'employeeId': _employeeIdController.text.trim(),
          'designation': _selectedDesignation,
          'department': _departmentController.text.trim(),
          'role': 'sai_official',
          'status': 'pending', // Requires admin approval
          'createdAt': DateTime.now(),
          'permissions': {
            'view_athletes': true,
            'review_results': true,
            'export_data': false, // Depends on designation
            'manage_users': false,
          }
        };

        await FirestoreService.createSAIOfficialProfile(officialData);

        _showMessage('Account created! Awaiting admin approval.', isError: false);

        // Navigate to pending approval screen instead of dashboard
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const PendingApprovalScreen())
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

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidOfficialEmail(String email) {
    // Check for official government domains
    final officialDomains = [
      'gov.in',
      'nic.in',
      'sai.gov.in',
      'sports.gov.in',
    ];

    return officialDomains.any((domain) => email.toLowerCase().endsWith(domain));
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

                  // Header
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A2E6D).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      size: 60,
                      color: Color(0xFF0A2E6D),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'SAI Official Registration',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A2E6D),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Create your official account',
                    style: TextStyle(
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
                        // Full Name
                        _buildTextField(
                          controller: _nameController,
                          hintText: 'Full Name',
                          prefixIcon: Icons.person_outline,
                        ),

                        const SizedBox(height: 16),

                        // Official Email
                        _buildTextField(
                          controller: _emailController,
                          hintText: 'Official Email (gov.in domain)',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 16),

                        // Employee ID
                        _buildTextField(
                          controller: _employeeIdController,
                          hintText: 'Employee ID',
                          prefixIcon: Icons.badge_outlined,
                        ),

                        const SizedBox(height: 16),

                        // Designation Dropdown
                        _buildDropdown(
                          value: _selectedDesignation,
                          hintText: 'Select Designation',
                          items: _designations,
                          prefixIcon: Icons.work_outline,
                          onChanged: (value) {
                            setState(() {
                              _selectedDesignation = value!;
                            });
                          },
                        ),

                        const SizedBox(height: 16),

                        // Department
                        _buildTextField(
                          controller: _departmentController,
                          hintText: 'Department/Division',
                          prefixIcon: Icons.business_outlined,
                        ),

                        const SizedBox(height: 16),

                        // Password
                        _buildTextField(
                          controller: _passwordController,
                          hintText: 'Password (min 8 characters)',
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

                        const SizedBox(height: 24),

                        // Security Notice
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.security, color: Colors.blue, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Account requires admin approval before access',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[700],
                                    fontFamily: 'Roboto',
                                  ),
                                ),
                              ),
                            ],
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
                              'Register as SAI Official',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
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
                        onTap: () {
                          // Navigate to SAI login
                        },
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

  Widget _buildDropdown({
    required String value,
    required String hintText,
    required List<String> items,
    required IconData prefixIcon,
    required Function(String?) onChanged,
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
      child: DropdownButtonFormField<String>(
        value: value.isEmpty ? null : value,
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
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}