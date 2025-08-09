import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(HabitTrackerApp());
}

class HabitTrackerApp extends StatefulWidget {
  const HabitTrackerApp({super.key});

  @override
  State<HabitTrackerApp> createState() => _HabitTrackerAppState();
}

class _HabitTrackerAppState extends State<HabitTrackerApp> {
  late Future<AppState> _appState;
  late ThemeService _themeService;

  Future<AppState> _checkAppState() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    
    return AppState(
      isLoggedIn: isLoggedIn,
      onboardingCompleted: onboardingCompleted,
    );
  }

  @override
  void initState() {
    super.initState();
    _themeService = ThemeService();
    _themeService.initTheme();
    _appState = _checkAppState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeService,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Habit Tracker',
          theme: ThemeService.lightTheme,
          darkTheme: ThemeService.darkTheme,
          themeMode: _themeService.themeMode,
          home: FutureBuilder<AppState>(
            future: _appState,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final appState = snapshot.data!;
              
              // Show onboarding if not completed
              if (!appState.onboardingCompleted) {
                return const OnboardingScreen();
              }
              
              // Show home or login based on auth state
              return appState.isLoggedIn ? const HomeScreen() : const LoginScreen();
            },
          ),
        );
      },
    );
  }
}

class AppState {
  final bool isLoggedIn;
  final bool onboardingCompleted;
  
  AppState({
    required this.isLoggedIn,
    required this.onboardingCompleted,
  });
}
