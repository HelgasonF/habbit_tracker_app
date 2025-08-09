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
              
              // If not logged in, show login screen first
              if (!appState.isLoggedIn) {
                return const LoginScreen();
              }
              
              // If logged in but onboarding not completed, show onboarding
              if (!appState.onboardingCompleted) {
                return const OnboardingScreen();
              }
              
              // If logged in and onboarding completed, show home
              return const HomeScreen();
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
