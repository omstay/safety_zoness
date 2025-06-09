import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:safetyzoness/screens/buisssnes_management_screen.dart';
import 'package:safetyzoness/screens/otp_login.dart';
import 'package:safetyzoness/screens/dashbord.dart';
import 'package:safetyzoness/screens/inventory_management.dart';
import 'package:safetyzoness/services/firebase_options.dart';
import 'screens/subscription_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if Firebase is already initialized
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase is already initialized, continue
    if (e.toString().contains('duplicate-app')) {
      print('Firebase already initialized');
    } else {
      print('Firebase initialization error: $e');
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaxEase GST Management',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        '/main': (context) => const MainScreen(),
        '/inventory': (context) => const InventoryManagementScreen(),
        '/subscription': (context) => const SubscriptionScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/login': (context) => const OTPLoginScreen(),
        '/gst': (context) => const GSTManagementScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        if (snapshot.hasData) {
          // User is signed in
          return const MainScreen();
        } else {
          // User is not signed in
          return const SplashScreen();
        }
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _fadeController.forward();
    _scaleController.forward();
    _pulseController.repeat(reverse: true);

    // Check authentication status after delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          Navigator.of(context).pushReplacementNamed('/main');
        } else {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const OTPLoginScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 800),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.6, 1.0],
            colors: [
              Color(0xFF1565C0),
              Color(0xFF1976D2),
              Color(0xFF1E88E5),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Logo Section
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 25,
                              offset: const Offset(0, 10),
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, -5),
                            ),
                          ],
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              Color(0xFFF8F9FA),
                            ],
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: Image.asset(
                            'lib/assets/images/logo.jpeg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white,
                                      Color(0xFFF8F9FA),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: const Icon(
                                  Icons.account_balance,
                                  size: 70,
                                  color: Color(0xFF1565C0),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
              // Title Section
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    const Text(
                      'TaxEase GST',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Management System',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'Your Professional Business Partner',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
              // Loading Section
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Loading...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late AnimationController _fabController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fabAnimation;

  final List<Widget> _screens = [
    const InventoryManagementScreen(),
    const DashboardScreen(),
    const GSTManagementScreen(),
    const SubscriptionScreen(),
  ];

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2,
      label: 'Inventory',
      color: const Color(0xFF4CAF50),
      gradient: const [Color(0xFF4CAF50), Color(0xFF81C784)],
    ),
    NavigationItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
      color: const Color(0xFF2196F3),
      gradient: const [Color(0xFF2196F3), Color(0xFF64B5F6)],
    ),
    NavigationItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long,
      label: 'GST',
      color: const Color(0xFF9C27B0),
      gradient: const [Color(0xFF9C27B0), Color(0xFFBA68C8)],
    ),
    NavigationItem(
      icon: Icons.card_membership_outlined,
      activeIcon: Icons.card_membership,
      label: 'Subscription',
      color: const Color(0xFFFF9800),
      gradient: const [Color(0xFFFF9800), Color(0xFFFFB74D)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    _fabAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout, color: Color(0xFFE53935)),
              SizedBox(width: 10),
              Text('Logout'),
            ],
          ),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'TaxEase GST',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Color(0xFF1565C0),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1565C0),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1565C0).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  // Profile action
                },
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.person,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: SizedBox(
              height: 70,
              child: Row(
                children: [
                  // Navigation Items
                  ..._navigationItems.asMap().entries.map((entry) {
                    int index = entry.key;
                    NavigationItem item = entry.value;
                    bool isSelected = _selectedIndex == index;

                    return Flexible(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _onItemTapped(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedBuilder(
                                    animation: _scaleAnimation,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: isSelected && _animationController.isAnimating
                                            ? _scaleAnimation.value
                                            : 1.0,
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 300),
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            gradient: isSelected
                                                ? LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: item.gradient,
                                            )
                                                : null,
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: isSelected
                                                ? [
                                              BoxShadow(
                                                color: item.color.withOpacity(0.25),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                                : null,
                                          ),
                                          child: Icon(
                                            isSelected ? item.activeIcon : item.icon,
                                            size: 22,
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 4),
                                  AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 300),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      color: isSelected ? item.color : Colors.grey.shade600,
                                    ),
                                    child: Text(
                                      item.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  // Logout Button
                  Flexible(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTapDown: (_) => _fabController.forward(),
                          onTapUp: (_) => _fabController.reverse(),
                          onTapCancel: () => _fabController.reverse(),
                          onTap: _showLogoutDialog,
                          child: AnimatedBuilder(
                            animation: _fabAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _fabAnimation.value,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [Color(0xFFE53935), Color(0xFFEF5350)],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFE53935).withOpacity(0.25),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.logout_rounded,
                                          size: 22,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Logout',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFE53935),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;
  final List<Color> gradient;

  NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
    required this.gradient,
  });
}