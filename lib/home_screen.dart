import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart';
import 'profile_screen.dart';
import 'reports_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'habit_suggestions_screen.dart';
import 'constants.dart';
import 'habit_detail_screen.dart';
import 'habit_info_screen.dart';
import 'services/api_service.dart';
import 'services/theme_service.dart';

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
  String _dailyQuote = '';
  String _quoteAuthor = '';
  bool _isLoadingQuote = true;
  late ThemeService _themeService;

  @override
  void initState() {
    super.initState();
    _themeService = ThemeService();
    _loadData();
    _loadDailyQuote();
  }

  Future<void> _loadDailyQuote() async {
    try {
      final quote = await ApiService.fetchDailyQuote();
      setState(() {
        _dailyQuote = quote['content']!;
        _quoteAuthor = quote['author']!;
        _isLoadingQuote = false;
      });
    } catch (e) {
      setState(() {
        _dailyQuote = 'Stay motivated and keep going!';
        _quoteAuthor = 'Unknown';
        _isLoadingQuote = false;
      });
    }
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('username') ?? 'User';
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
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.track_changes,
                color: Colors.orangeAccent,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Habit Tracker'),
          ],
        ),
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
              leading: const Icon(Icons.assessment),
              title: const Text('Reports'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
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
              leading: const Icon(Icons.lightbulb),
              title: const Text('Habit Suggestions'),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HabitSuggestionsScreen()),
                );
                Navigator.pop(context);
                _loadData();
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
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
              leading: const Icon(Icons.notifications),
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
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SettingsScreen(themeService: _themeService)),
                );
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
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
                // Daily Quote Card
                if (!_isLoadingQuote)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.withOpacity(0.1), Colors.purple.withOpacity(0.1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.format_quote, color: Colors.blue[600], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Daily Inspiration',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _dailyQuote,
                          style: const TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '— $_quoteAuthor',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
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

