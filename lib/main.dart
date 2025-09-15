// File: lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'providers/athlete_provider.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/athlete_profile_setup.dart';
import 'screens/dashboard_screen.dart';
import 'screens/sai/sai_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/sai/pending_approval_screen.dart';
import 'services/firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AthleteProvider()),
      ],
      child: MaterialApp(
        title: 'TalentFind - SAI Talent Assessment Platform',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0A2E6D),
            brightness: Brightness.light,
          ),
          fontFamily: 'Roboto',
          useMaterial3: true,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A2E6D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
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
        ),
        debugShowCheckedModeBanner: false,
        // Named routes for all dashboards
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/roleSelection': (context) => const RoleSelectionScreen(),
          '/athleteProfileSetup': (context) => const AthleteProfileSetup(),
          '/athleteDashboard': (context) => const DashboardScreen(),
          '/officialDashboard': (context) {
            print('ROUTE DEBUG: officialDashboard route called');
            try {
              return const SAIDashboard();
            } catch (e) {
              print('ERROR: SAIDashboard failed to load: $e');
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('SAI Dashboard Error'),
                      SizedBox(height: 16),
                      Text('Check console for details'),
                    ],
                  ),
                ),
              );
            }
          },

          '/pendingApproval': (context) => const PendingApprovalScreen(),
          '/adminDashboard': (context) => const AdminDashboard(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A2E6D)),
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          // User is logged in, determine their role and route
          return RoleBasedRouter(user: snapshot.data!);
        } else {
          // User is not logged in, show role selection
          return const RoleSelectionScreen();
        }
      },
    );
  }
}

class RoleBasedRouter extends StatefulWidget {
  final User user;

  const RoleBasedRouter({Key? key, required this.user}) : super(key: key);

  @override
  State<RoleBasedRouter> createState() => _RoleBasedRouterState();
}

class _RoleBasedRouterState extends State<RoleBasedRouter> {
  bool _isLoading = true;
  String _targetRoute = '/roleSelection';

  @override
  void initState() {
    super.initState();
    _determineUserRoute();
  }

  Future<void> _determineUserRoute() async {
    try {
      await _navigateBasedOnRole(widget.user.uid);
    } catch (e) {
      print('Error determining user route: $e');
      setState(() {
        _targetRoute = '/roleSelection';
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateBasedOnRole(String userId) async {
    try {
      print('=== MAIN.DART ROUTING DEBUG ===');
      print('User ID: $userId');

      // STEP 1: Check if user is System Admin FIRST
      final adminCheck = await FirestoreService.isUserAdmin(userId);
      print('Is Admin: $adminCheck');
      if (adminCheck) {
        print('Routing to Admin Dashboard');
        if (mounted) {
          setState(() {
            _targetRoute = '/adminDashboard';
            _isLoading = false;
          });
        }
        return; // CRITICAL: Exit early for admin
      }

      // DEBUG: Check all user collections
      await FirestoreService.debugUserCollections(userId);

      // STEP 2: Get user data from Firestore
      final userData = await FirestoreService.getUserRole(userId);
      final userRole = userData['role'];
      final userStatus = userData['status'];

      print('=== LOGIN NAVIGATION DEBUG START ===');
      print('User ID: $userId');
      print('Full userData: $userData');
      print('Role: $userRole (${userRole?.runtimeType})');
      print('Status: $userStatus (${userStatus?.runtimeType})');

      // STEP 3: Handle null or empty role - route to role selection
      if (userRole == null || userRole.toString().isEmpty) {
        print('No valid role found - routing to Role Selection');
        if (mounted) {
          setState(() {
            _targetRoute = '/roleSelection';
            _isLoading = false;
          });
        }
        return; // CRITICAL: Exit early for no role
      }

      // STEP 4: Route based on role and status
      switch (userRole.toString().toLowerCase()) {
        case 'athlete':
          print('Processing athlete routing...');
          try {
            final profile = await FirestoreService.getAthleteProfile();
            if (profile?.isComplete == true) {
              if (mounted) {
                Provider.of<AthleteProvider>(context, listen: false).setProfile(profile);
              }
              print('Routing to Athlete Dashboard');
              if (mounted) {
                setState(() {
                  _targetRoute = '/athleteDashboard';
                  _isLoading = false;
                });
              }
            } else {
              print('Routing to Profile Setup');
              if (mounted) {
                setState(() {
                  _targetRoute = '/athleteProfileSetup';
                  _isLoading = false;
                });
              }
            }
          } catch (e) {
            print('Error getting athlete profile: $e');
            // Default to profile setup if error
            if (mounted) {
              setState(() {
                _targetRoute = '/athleteProfileSetup';
                _isLoading = false;
              });
            }
          }
          break;

        case 'official':
        case 'sai_official':
          print('Processing SAI official...');

          // Convert status to string and trim whitespace
          final statusString = userStatus?.toString().trim() ?? 'pending';
          print('Status check: "$statusString"');

          switch (statusString.toLowerCase()) {
            case 'approved':
              print('Status approved - navigating to SAI Dashboard');
              if (mounted) {
                setState(() {
                  _targetRoute = '/officialDashboard';
                  _isLoading = false;
                });
              }
              break;

            case 'pending':
              print('Status pending - navigating to Pending Approval');
              if (mounted) {
                setState(() {
                  _targetRoute = '/pendingApproval';
                  _isLoading = false;
                });
              }
              break;

            case 'rejected':
              print('Status rejected - navigating to Pending Approval');
              if (mounted) {
                setState(() {
                  _targetRoute = '/pendingApproval';
                  _isLoading = false;
                });
              }
              break;

            default:
              print('Unknown status ($statusString) - defaulting to pending');
              if (mounted) {
                setState(() {
                  _targetRoute = '/pendingApproval';
                  _isLoading = false;
                });
              }
              break;
          }
          break;

        default:
        // Invalid role - treat as new user
          print('Unknown role ($userRole) - routing to Role Selection');
          if (mounted) {
            setState(() {
              _targetRoute = '/roleSelection';
              _isLoading = false;
            });
          }
          break;
      }

      print('=== LOGIN NAVIGATION DEBUG END ===');
      print('Final target route: $_targetRoute');
      print('=== END ROUTING DEBUG ===');

    } catch (e) {
      print('Error in role-based navigation: $e');
      // Always fallback to role selection on error
      if (mounted) {
        setState(() {
          _targetRoute = '/roleSelection';
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A2E6D)),
              ),
              SizedBox(height: 16),
              Text(
                'Loading your dashboard...',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Navigate to the determined route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        print('Navigating to: $_targetRoute');
        Navigator.pushReplacementNamed(context, _targetRoute);
      }
    });

    // Return loading screen while navigation happens
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A2E6D)),
        ),
      ),
    );
  }
}