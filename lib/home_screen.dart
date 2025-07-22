import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'habits_screen.dart';
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

  Widget _buildTodoItem(String habit) {
    final color = _habitColors[habit] ?? habitColorPalette.first;
    return GestureDetector(
      onTap: () => _openDetail(habit),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(habit),
            IconButton(
              icon: Icon(Icons.check_circle, color: color),
              onPressed: () => _toggleHabit(habit, true),
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
              title: const Text('Habit Info'),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HabitInfoScreen()),
                );
                Navigator.pop(context);
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
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Welcome back, $_name',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: Text('To Do', style: TextStyle(fontSize: 18)),
                ),
                if (_habits.where((h) => !(_todayStatus[h] ?? false)).isEmpty)
                  const ListTile(title: Text('All done!'))
                else
                  ..._habits
                      .where((h) => !(_todayStatus[h] ?? false))
                      .map(_buildTodoItem)
                      .toList(),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HabitsScreen()),
                      );
                      _loadData();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: Text('Completed Today', style: TextStyle(fontSize: 18)),
                ),
                if (_habits.where((h) => _todayStatus[h] == true).isEmpty)
                  const ListTile(title: Text('Nothing yet'))
                else
                  ..._habits
                      .where((h) => _todayStatus[h] == true)
                      .map((h) => GestureDetector(
                            onTap: () => _openDetail(h),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.yellow.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.star, color: _habitColors[h] ?? Colors.blue),
                                  const SizedBox(width: 8),
                                  Text(h),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
              ],
            ),
    );
  }
}

