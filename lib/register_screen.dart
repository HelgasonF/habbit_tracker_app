import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _customHabitController = TextEditingController();

  double _age = 25;
  String _country = 'Iceland';
  List<String> selectedHabits = [];

  final int maxHabits = 10;

  // Basic color palette used to assign initial colors to habits
  final List<Color> _palette = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.brown,
  ];


  List<String> availableHabits = [
    'Gym',
    'Be Positive',
    'Bed Early',
    'Walk The Dog',
    'Study',
    'Drink Water',
    'Read',
    'Meditate',
    'Eat Healthy',
    'Sleep 8+ Hours',
    'No Sugar',
    'Gratitude',
    'Journal',
    'Stretch',
    'Go Outside',
  ];

  void _register() async {
    final prefs = await SharedPreferences.getInstance();
    // Persist basic profile information
    await prefs.setString('name', _nameController.text.trim());
    await prefs.setString('username', _usernameController.text.trim());
    await prefs.setString('password', _passwordController.text.trim());
    await prefs.setInt('age', _age.round());
    await prefs.setString('country', _country);
    await prefs.setStringList('habits', selectedHabits);

    // Assign a color from the palette to each selected habit
    int index = 0;
    final colorMap = <String, int>{};
    for (final habit in selectedHabits) {
      colorMap[habit] = _palette[index % _palette.length].value;
      index++;
    }
    await prefs.setString('habit_colors', jsonEncode(colorMap));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registered & saved locally!')),
    );
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
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
              _buildInputField(_nameController, 'Name'),
              const SizedBox(height: 16),
              _buildInputField(_usernameController, 'Username'),
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

