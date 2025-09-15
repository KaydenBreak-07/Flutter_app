// File: lib/screens/sai/sai_dashboard.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import 'athletes_review_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';

class SAIDashboard extends StatefulWidget {
  const SAIDashboard({Key? key}) : super(key: key);

  @override
  State<SAIDashboard> createState() => _SAIDashboardState();
}

class _SAIDashboardState extends State<SAIDashboard> {
  int _currentIndex = 0;
  Map<String, dynamic>? _officialProfile;
  Map<String, dynamic> _dashboardStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOfficialData();
  }

  @override
  void dispose() {
    // Cancel any ongoing operations when widget is disposed
    super.dispose();
  }

  Future<void> _loadOfficialData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Load official profile
        _officialProfile = await FirestoreService.getSAIOfficialProfile(user.uid);

        // Load dashboard statistics with error handling
        try {
          _dashboardStats = await FirestoreService.getSAIDashboardStats();
        } catch (e) {
          print('Error getting SAI dashboard stats: $e');
          // Set default values if stats fail to load
          _dashboardStats = {
            'totalAthletes': 0,
            'assessmentsToday': 0,
            'pendingReviews': 0,
            'flaggedCases': 0,
          };
        }

        // CRITICAL: Check if widget is still mounted before calling setState
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading official data: $e');

      // CRITICAL: Check if widget is still mounted before calling setState
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A2E6D)),
          ),
        ),
      );
    }

    // FIXED: Check status properly - should check 'status' field, not 'approved'
    final userStatus = _officialProfile?['status']?.toString().toLowerCase() ?? 'pending';

    // If not approved, show pending screen
    if (userStatus != 'approved') {
      return _buildApprovalPendingScreen();
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _SAIDashboardHome(
            officialProfile: _officialProfile,
            dashboardStats: _dashboardStats,
          ),
          const AthletesReviewScreen(),
          const SAIAnalyticsScreen(),
          const SAISettingsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (mounted) {
              setState(() {
                _currentIndex = index;
              });
            }
          },
          selectedItemColor: const Color(0xFF0A2E6D),
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Athletes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalPendingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: const Icon(
                  Icons.hourglass_empty,
                  size: 60,
                  color: Colors.orange,
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'Account Pending Approval',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A2E6D),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Text(
                'Your SAI official account is awaiting administrator approval. You will receive access once your credentials are verified.',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(height: 8),
                    Text(
                      'Contact your system administrator if this is taking longer than expected.',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        color: Colors.blue[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: () {
                  FirebaseAuth.instance.signOut();
                },
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SAIDashboardHome extends StatelessWidget {
  final Map<String, dynamic>? officialProfile;
  final Map<String, dynamic> dashboardStats;

  const _SAIDashboardHome({
    required this.officialProfile,
    required this.dashboardStats,
  });

  @override
  Widget build(BuildContext context) {
    final officialName = officialProfile?['fullName'] ?? 'SAI Official';
    final designation = officialProfile?['designation'] ?? 'Official';

    return Container(
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(20),
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
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A2E6D).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings,
                        size: 30,
                        color: Color(0xFF0A2E6D),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back!',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            officialName,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0A2E6D),
                            ),
                          ),
                          Text(
                            designation,
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Stats Overview
              const Text(
                'Platform Overview',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A2E6D),
                ),
              ),

              const SizedBox(height: 16),

              // Stats Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _buildStatCard(
                    'Total Athletes',
                    '${dashboardStats['totalAthletes'] ?? 0}',
                    Icons.people,
                    Colors.blue,
                  ),
                  _buildStatCard(
                    'Assessments Today',
                    '${dashboardStats['assessmentsToday'] ?? 0}',
                    Icons.assessment,
                    Colors.green,
                  ),
                  _buildStatCard(
                    'Pending Reviews',
                    '${dashboardStats['pendingReviews'] ?? 0}',
                    Icons.pending_actions,
                    Colors.orange,
                  ),
                  _buildStatCard(
                    'Flagged Cases',
                    '${dashboardStats['flaggedCases'] ?? 0}',
                    Icons.flag,
                    Colors.red,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A2E6D),
                ),
              ),

              const SizedBox(height: 16),

              // Action Cards
              _buildActionCard(
                title: 'Review Athletes',
                subtitle: 'View and assess athlete performances',
                icon: Icons.people,
                color: Colors.blue,
                onTap: () {
                  // Switch to athletes tab
                  final dashboardState = context.findAncestorStateOfType<_SAIDashboardState>();
                  if (dashboardState != null && dashboardState.mounted) {
                    dashboardState.setState(() {
                      dashboardState._currentIndex = 1;
                    });
                  }
                },
              ),

              const SizedBox(height: 12),

              _buildActionCard(
                title: 'Performance Analytics',
                subtitle: 'View detailed analytics and trends',
                icon: Icons.analytics,
                color: Colors.green,
                onTap: () {
                  // Switch to analytics tab
                  final dashboardState = context.findAncestorStateOfType<_SAIDashboardState>();
                  if (dashboardState != null && dashboardState.mounted) {
                    dashboardState.setState(() {
                      dashboardState._currentIndex = 2;
                    });
                  }
                },
              ),

              const SizedBox(height: 12),

              _buildActionCard(
                title: 'Export Data',
                subtitle: 'Download athlete data and reports',
                icon: Icons.download,
                color: Colors.purple,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export functionality coming soon!')),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Recent Activity
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A2E6D),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildActivityItem(
                      'New athlete registered',
                      'Rajesh Kumar from Maharashtra',
                      '2 hours ago',
                      Icons.person_add,
                    ),
                    _buildActivityItem(
                      'Assessment completed',
                      'Vertical Jump Test by Priya Singh',
                      '4 hours ago',
                      Icons.check_circle,
                    ),
                    _buildActivityItem(
                      'Anomaly detected',
                      'Unusual performance pattern flagged',
                      '6 hours ago',
                      Icons.warning,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              color: Color(0xFF0A2E6D),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 24, color: color),
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
              color: Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, String time, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF0A2E6D).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF0A2E6D)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0A2E6D),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}