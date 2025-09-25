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
import 'services/ml_service.dart';
import 'services/ml_service_placeholder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize ML Services
  await initializeMLServices();

  runApp(const MyApp());
}

Future<void> initializeMLServices() async {
  print('🚀 Initializing ML Services...');

  try {
    // Try to initialize the full ML Service with TFLite
    try {
      final mlService = MLService();
      await mlService.initialize();
      print('✅ Full ML Service initialized successfully');
      print('ℹ️  TFLite models loaded and ready for analysis');
    } catch (e) {
      print('⚠️  Full ML Service initialization failed: $e');
      print('🔄 Falling back to placeholder service...');

      // Initialize placeholder service as fallback
      MLServicePlaceholder mlPlaceholder = MLServicePlaceholder.instance;
      bool isInitialized = await mlPlaceholder.initializeModel();

      if (isInitialized) {
        print('✅ ML Placeholder Service initialized successfully');
        print('ℹ️  Using mathematical simulation for development');
      } else {
        print('❌ Failed to initialize ML Placeholder Service');
      }
    }
  } catch (e) {
    print('❌ Critical error initializing ML Services: $e');
    print('ℹ️  App will continue with limited ML functionality');
  }

  print('🏁 ML Services initialization completed');
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
          // Enhanced card theme for better ML results display
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(vertical: 4),
          ),
          // Enhanced app bar theme
          appBarTheme: AppBarTheme(
            backgroundColor: const Color(0xFF0A2E6D),
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),
        ),
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
        routes: {
          '/roleSelection': (context) => const RoleSelectionScreen(),
          '/athleteProfileSetup': (context) => const AthleteProfileSetup(),
          '/athleteDashboard': (context) => const DashboardScreen(),
          '/officialDashboard': (context) => const SAIDashboard(),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A2E6D)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Initializing TalentFind Platform...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Loading AI-powered sports assessment tools',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return RoleBasedRouter(user: snapshot.data!);
        } else {
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
  Widget? _targetScreen;

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
        _targetScreen = const RoleSelectionScreen();
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateBasedOnRole(String userId) async {
    try {
      // Check if user is System Admin FIRST
      final adminCheck = await FirestoreService.isUserAdmin(userId);
      if (adminCheck) {
        setState(() {
          _targetScreen = const AdminDashboard();
          _isLoading = false;
        });
        return;
      }

      // Get user data from Firestore
      final userData = await FirestoreService.getUserRole(userId);
      final userRole = userData['role'];
      final userStatus = userData['status'];

      // Handle null or empty role - route to role selection
      if (userRole == null || userRole.toString().isEmpty) {
        setState(() {
          _targetScreen = const RoleSelectionScreen();
          _isLoading = false;
        });
        return;
      }

      // Route based on role and status
      switch (userRole.toString().toLowerCase()) {
        case 'athlete':
          try {
            final profile = await FirestoreService.getAthleteProfile();
            if (profile?.isComplete == true) {
              Provider.of<AthleteProvider>(context, listen: false).setProfile(profile);
              setState(() {
                _targetScreen = const DashboardScreen();
                _isLoading = false;
              });
            } else {
              setState(() {
                _targetScreen = const AthleteProfileSetup();
                _isLoading = false;
              });
            }
          } catch (e) {
            print('Error getting athlete profile: $e');
            setState(() {
              _targetScreen = const AthleteProfileSetup();
              _isLoading = false;
            });
          }
          break;

        case 'official':
        case 'sai_official':
          final statusString = userStatus?.toString().trim() ?? 'pending';

          switch (statusString.toLowerCase()) {
            case 'approved':
              setState(() {
                _targetScreen = const SAIDashboard();
                _isLoading = false;
              });
              break;

            case 'pending':
            case 'rejected':
            default:
              setState(() {
                _targetScreen = const PendingApprovalScreen();
                _isLoading = false;
              });
              break;
          }
          break;

        default:
          setState(() {
            _targetScreen = const RoleSelectionScreen();
            _isLoading = false;
          });
          break;
      }
    } catch (e) {
      print('Error in role-based navigation: $e');
      setState(() {
        _targetScreen = const RoleSelectionScreen();
        _isLoading = false;
      });
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
              SizedBox(height: 8),
              Text(
                'Preparing AI-powered performance analysis',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _targetScreen ?? const RoleSelectionScreen();
  }
}