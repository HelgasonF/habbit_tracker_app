import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'habits_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'reports_screen.dart';
import 'notifications_screen.dart';

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

  Widget _buildHabitItem(String habit) {
    final color = _habitColors[habit];
    return CheckboxListTile(
      title: Text(habit),
      value: _todayStatus[habit] ?? false,
      activeColor: color,
      onChanged: (val) => _toggleHabit(habit, val),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hello, $_name'),
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
              title: const Text('Habits'),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HabitsScreen()),
                );
                _loadData();
                Navigator.pop(context);
              },
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
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Today', style: TextStyle(fontSize: 18)),
                ),
                ..._habits.map(_buildHabitItem).toList(),
                const Divider(),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Completed', style: TextStyle(fontSize: 18)),
              ),
              if (_habits.where((h) => _todayStatus[h] == true).isEmpty)
                const ListTile(title: Text('Nothing yet'))
              else
                ..._habits
                    .where((h) => _todayStatus[h] == true)
                    .map((h) => ListTile(
                          title: Text(h),
                          leading: CircleAvatar(
                            backgroundColor: _habitColors[h] ?? Colors.blue,
                            radius: 8,
                          ),
                        ))
                    .toList(),
              ],
            ),
    );
  }
}

