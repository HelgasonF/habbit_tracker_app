import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart';
import 'profile_screen.dart';
import 'reports_screen.dart';
import 'notifications_screen.dart';
import 'constants.dart';
import 'habit_detail_screen.dart';
import 'habit_info_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _name = '';
  List<String> _habits = [];
  final Map<String, bool> _todayStatus = {};
  final Map<String, Color> _habitColors = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('name') ?? '';
      _habits = prefs.getStringList('habits') ?? [];
      // Restore stored colors for each habit
      final colorData = prefs.getString('habit_colors');
      if (colorData != null) {
        final map = jsonDecode(colorData) as Map<String, dynamic>;
        _habitColors.clear();
        map.forEach((k, v) => _habitColors[k] = Color(v as int));
      }
    });
    final today = DateTime.now().toIso8601String().split('T').first;
    for (final habit in _habits) {
      final key = _habitKey(habit);
      final completedDates = prefs.getStringList(key) ?? [];
      _todayStatus[habit] = completedDates.contains(today);
    }
    setState(() {});
  }

  String _habitKey(String habit) => 'habit_${habit.replaceAll(' ', '_')}';

  Future<void> _toggleHabit(String habit, bool? value) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T').first;
    final key = _habitKey(habit);
    final completedDates = prefs.getStringList(key) ?? [];
    setState(() {
      _todayStatus[habit] = value ?? false;
    });
    if (value == true) {
      if (!completedDates.contains(today)) {
        completedDates.add(today);
        await prefs.setStringList(key, completedDates);
      }
    } else {
      completedDates.remove(today);
      await prefs.setStringList(key, completedDates);
    }
  }

  Future<void> _signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _openDetail(String habit) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HabitDetailScreen(habit: habit)),
    );
    _loadData();
  }

  Widget _buildHabitRow(String habit) {
    final color = _habitColors[habit] ??
        habitColorPalette[_habits.indexOf(habit) % habitColorPalette.length];
    final done = _todayStatus[habit] ?? false;
    return GestureDetector(
      onTap: () => _openDetail(habit),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Expanded(
              child: Center(
                child: Text(
                  habit,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                done ? Icons.star : Icons.star_border,
                color: done ? Colors.yellow.shade700 : Colors.black54,
              ),
              onPressed: () => _toggleHabit(habit, !done),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orangeAccent,
        title: const Text('Home'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              child: Text(
                _name,
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              title: const Text('Reports'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportsScreen()),
                );
              },
            ),
            ListTile(
              title: const Text('Habit Info'),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HabitInfoScreen()),
                );
                Navigator.pop(context);
                _loadData();
              },
            ),
            ListTile(
              title: const Text('Profile'),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
                _loadData();
              },
            ),
            ListTile(
              title: const Text('Notifications'),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                );
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Sign Out'),
              onTap: _signOut,
            ),
          ],
        ),
      ),
      body: _habits.isEmpty
          ? const Center(child: Text('No habits yet'))
          : ListView(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: pastelBackgrounds.first,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Welcome back, $_name',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: const Text(
                    'To Do',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange),
                  ),
                ),
                if (_habits.where((h) => !(_todayStatus[h] ?? false)).isEmpty)
                  const ListTile(title: Text('All done!'))
                else
                  ..._habits
                      .where((h) => !(_todayStatus[h] ?? false))
                      .map(_buildHabitRow)
                      .toList(),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HabitInfoScreen()),
                      );
                      _loadData();
                    },
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.orangeAccent,
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: const Text(
                    'Completed Today',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange),
                  ),
                ),
                if (_habits.where((h) => _todayStatus[h] == true).isEmpty)
                  const ListTile(title: Text('Nothing yet'))
                else
                  ..._habits
                      .where((h) => _todayStatus[h] == true)
                      .map(_buildHabitRow)
                      .toList(),
              ],
            ),
    );
  }
}

