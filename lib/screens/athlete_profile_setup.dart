// File: lib/screens/athlete_profile_setup.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/athlete_profile.dart';
import 'dashboard_screen.dart';

class AthleteProfileSetup extends StatefulWidget {
  const AthleteProfileSetup({Key? key}) : super(key: key);

  @override
  State<AthleteProfileSetup> createState() => _AthleteProfileSetupState();
}

class _AthleteProfileSetupState extends State<AthleteProfileSetup> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String _selectedGender = '';
  String _selectedState = '';
  String _selectedDistrict = '';
  String _selectedSport = '';

  bool _isLoading = false;

  final List<String> _genders = ['Male', 'Female', 'Other'];

  final List<String> _states = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand',
    'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur',
    'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha', 'Punjab',
    'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura',
    'Uttar Pradesh', 'Uttarakhand', 'West Bengal', 'Delhi', 'Mumbai'
  ];

  final Map<String, List<String>> _districts = {
    'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Nashik', 'Thane', 'Aurangabad'],
    'Karnataka': ['Bangalore', 'Mysore', 'Hubli', 'Mangalore', 'Belgaum'],
    'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai', 'Tiruchirappalli', 'Salem'],
    'Delhi': ['Central Delhi', 'North Delhi', 'South Delhi', 'East Delhi', 'West Delhi'],
    // Add more states and districts as needed
  };

  final List<String> _sports = [
    'Athletics', 'Football', 'Cricket', 'Hockey', 'Badminton',
    'Tennis', 'Basketball', 'Volleyball', 'Swimming', 'Boxing',
    'Wrestling', 'Weightlifting', 'Cycling', 'Table Tennis', 'Shooting'
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // Load existing profile using FirestoreService
  Future<void> _loadExistingProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final profile = await FirestoreService.getAthleteProfile();

        if (profile != null) {
          setState(() {
            _nameController.text = profile.fullName;
            _ageController.text = profile.age.toString();
            _heightController.text = profile.height.toString();
            _weightController.text = profile.weight.toString();
            _selectedGender = profile.gender;
            _selectedState = profile.state;
            _selectedDistrict = profile.district;
            _selectedSport = profile.preferredSport;
          });
        } else {
          // Pre-fill name from Firebase Auth
          _nameController.text = user.displayName ?? '';
        }
      } catch (e) {
        print('Error loading profile: $e');
        _showMessage('Error loading profile: $e');
      }
    }
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedGender.isEmpty || _selectedState.isEmpty ||
        _selectedDistrict.isEmpty || _selectedSport.isEmpty) {
      _showMessage('Please fill in all required fields');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final profile = AthleteProfile(
          uid: user.uid,
          fullName: _nameController.text.trim(),
          age: int.parse(_ageController.text.trim()),
          gender: _selectedGender,
          height: double.parse(_heightController.text.trim()),
          weight: double.parse(_weightController.text.trim()),
          state: _selectedState,
          district: _selectedDistrict,
          preferredSport: _selectedSport,
          email: user.email,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await FirestoreService.saveAthleteProfile(profile);

        _showMessage('Profile saved successfully!', isError: false);

        // Navigate to Dashboard
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen())
        );
      }
    } catch (e) {
      _showMessage('Failed to save profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // Header
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A2E6D).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Icon(
                        Icons.person_add,
                        size: 40,
                        color: Color(0xFF0A2E6D),
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Complete Your Profile',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A2E6D),
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Tell us about yourself to get started',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Form Container
                    Container(
                      padding: const EdgeInsets.all(24.0),
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
                            label: 'Full Name',
                            prefixIcon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your full name';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Age & Gender Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _ageController,
                                  label: 'Age',
                                  prefixIcon: Icons.cake_outlined,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Enter age';
                                    }
                                    final age = int.tryParse(value);
                                    if (age == null || age < 10 || age > 40) {
                                      return 'Age: 10-40';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDropdown(
                                  value: _selectedGender,
                                  label: 'Gender',
                                  items: _genders,
                                  prefixIcon: Icons.wc_outlined,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedGender = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Height & Weight Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _heightController,
                                  label: 'Height (cm)',
                                  prefixIcon: Icons.height,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Enter height';
                                    }
                                    final height = double.tryParse(value);
                                    if (height == null || height < 100 || height > 250) {
                                      return '100-250 cm';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  controller: _weightController,
                                  label: 'Weight (kg)',
                                  prefixIcon: Icons.monitor_weight_outlined,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Enter weight';
                                    }
                                    final weight = double.tryParse(value);
                                    if (weight == null || weight < 25 || weight > 150) {
                                      return '25-150 kg';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // State Dropdown
                          _buildDropdown(
                            value: _selectedState,
                            label: 'State',
                            items: _states,
                            prefixIcon: Icons.location_on_outlined,
                            onChanged: (value) {
                              setState(() {
                                _selectedState = value!;
                                _selectedDistrict = ''; // Reset district
                              });
                            },
                          ),

                          const SizedBox(height: 16),

                          // District Dropdown
                          _buildDropdown(
                            value: _selectedDistrict,
                            label: 'District',
                            items: _districts[_selectedState] ?? ['Select State First'],
                            prefixIcon: Icons.location_city_outlined,
                            enabled: _selectedState.isNotEmpty,
                            onChanged: (value) {
                              setState(() {
                                _selectedDistrict = value!;
                              });
                            },
                          ),

                          const SizedBox(height: 16),

                          // Preferred Sport Dropdown
                          _buildDropdown(
                            value: _selectedSport,
                            label: 'Preferred Sport',
                            items: _sports,
                            prefixIcon: Icons.sports_outlined,
                            onChanged: (value) {
                              setState(() {
                                _selectedSport = value!;
                              });
                            },
                          ),

                          const SizedBox(height: 32),

                          // Save Profile Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveProfile,
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
                                'Save Profile & Continue',
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          prefixIcon,
          color: const Color(0xFF0A2E6D).withOpacity(0.7),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0A2E6D), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required String label,
    required List<String> items,
    required IconData prefixIcon,
    required Function(String?) onChanged,
    bool enabled = true,
  }) {
    return DropdownButtonFormField<String>(
      value: value.isEmpty ? null : value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          prefixIcon,
          color: const Color(0xFF0A2E6D).withOpacity(0.7),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0A2E6D), width: 2),
        ),
        filled: true,
        fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade200,
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
      onChanged: enabled ? onChanged : null,
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 16,
        color: Colors.black,
      ),
    );
  }
}