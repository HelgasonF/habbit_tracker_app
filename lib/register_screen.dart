import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _customHabitController = TextEditingController();

  double _age = 25;
  String _country = 'Iceland';
  List<String> selectedHabits = [];


  List<String> availableHabits = List.from(predefinedHabits);

  void _register() async {
    // Validation
    if (_usernameController.text.trim().isEmpty || 
        _emailController.text.trim().isEmpty || 
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username, email, and password are required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_emailController.text.trim().contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_passwordController.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters long'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    // Persist basic profile information
    await prefs.setString('username', _usernameController.text.trim());
    await prefs.setString('email', _emailController.text.trim());
    await prefs.setString('password', _passwordController.text.trim());
    await prefs.setInt('age', _age.round());
    await prefs.setString('country', _country);
    await prefs.setStringList('habits', selectedHabits);

    // Assign a color from the palette to each selected habit
    int index = 0;
    final colorMap = <String, int>{};
    for (final habit in selectedHabits) {
      colorMap[habit] =
          habitColorPalette[index % habitColorPalette.length].value;
      index++;
    }
    await prefs.setString('habit_colors', jsonEncode(colorMap));

    // Mark user as logged in and set onboarding as pending
    await prefs.setBool('isLoggedIn', true);
    await prefs.setBool('onboarding_completed', false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registered successfully!')),
    );
    if (!mounted) return;
    
    // Navigate to onboarding for new users
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  void _addCustomHabit() {
    final newHabit = _customHabitController.text.trim();
    if (newHabit.isEmpty) return;

    if (selectedHabits.length >= maxHabits) {
      _showLimitWarning();
      return;
    }

    if (!selectedHabits.contains(newHabit)) {
      setState(() {
        selectedHabits.insert(0, newHabit);
        _customHabitController.clear();
      });
    }
  }

  void _toggleHabit(String habit) {
    setState(() {
      if (selectedHabits.contains(habit)) {
        selectedHabits.remove(habit);
      } else {
        if (selectedHabits.length >= maxHabits) {
          _showLimitWarning();
          return;
        }
        selectedHabits.add(habit);
      }
    });
  }

  void _showLimitWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('You can only select up to $maxHabits habits.'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF709CF0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                },
              ),
              const Center(
                child: Text(
                  'Register',
                  style: TextStyle(
                    fontFamily: 'Pattaya',
                    fontSize: 36,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _buildInputField(_usernameController, 'Username'),
              const SizedBox(height: 16),
              _buildInputField(_emailController, 'Email'),
              const SizedBox(height: 16),
              _buildInputField(_passwordController, 'Password', obscure: true),
              const SizedBox(height: 16),
              Text('Age: ${_age.round()}',
                  style: const TextStyle(color: Colors.white, fontSize: 18)),
              Slider(
                value: _age,
                min: 10,
                max: 100,
                divisions: 90,
                activeColor: Colors.blue.shade600,
                onChanged: (value) {
                  setState(() => _age = value);
                },
              ),
              const SizedBox(height: 10),
              _buildCountryPicker(),
              const SizedBox(height: 20),
              const Text(
                'Select Your Habits',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (var habit in selectedHabits)
                    GestureDetector(
                      onTap: () => _toggleHabit(habit),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue.shade700),
                        ),
                        child: Text(
                          habit,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  for (var habit in availableHabits)
                    if (!selectedHabits.contains(habit))
                      GestureDetector(
                        onTap: () => _toggleHabit(habit),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blue.shade700),
                          ),
                          child: Text(
                            habit,
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Add Your Own Habit',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                        _customHabitController, 'Custom habit'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _addCustomHabit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
                    ),
                    child: const Text('+ Add'),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5C85D6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 80, vertical: 15),
                  ),
                  child: const Text(
                    'Register',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String hint,
      {bool obscure = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildCountryPicker() {
    return GestureDetector(
      onTap: () {
        showCountryPicker(
          context: context,
          showPhoneCode: false,
          onSelect: (country) {
            setState(() {
              _country = country.name;
            });
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.blue.shade700),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _country,
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 16,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.blue.shade700),
          ],
        ),
      ),
    );
  }
}

