import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

void main() {
  runApp(HabitTrackerApp());
}

class HabitTrackerApp extends StatefulWidget {
  const HabitTrackerApp({super.key});

  @override
  State<HabitTrackerApp> createState() => _HabitTrackerAppState();
}

class _HabitTrackerAppState extends State<HabitTrackerApp> {
  late Future<bool> _isLoggedIn;

  Future<bool> _check() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  @override
  void initState() {
    super.initState();
    _isLoggedIn = _check();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<bool>(
        future: _isLoggedIn,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox();
          }
          return snapshot.data! ? const HomeScreen() : const LoginScreen();
        },
      ),
    );
  }
}
