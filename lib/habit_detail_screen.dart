import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';

class HabitDetailScreen extends StatefulWidget {
  final String habit;
  const HabitDetailScreen({super.key, required this.habit});

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  Color _color = Colors.blue;
  final TextEditingController _goalController = TextEditingController();
  final Map<int, bool> _weekDone = {for (int i = 1; i <= 7; i++) i: false};
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final colorData = prefs.getString('habit_colors');
    if (colorData != null) {
      final map = jsonDecode(colorData) as Map<String, dynamic>;
      if (map.containsKey(widget.habit)) {
        _color = Color(map[widget.habit] as int);
      }
    }
    final goalData = prefs.getString('habit_goals');
    if (goalData != null) {
      final map = jsonDecode(goalData) as Map<String, dynamic>;
      _goalController.text = map[widget.habit] ?? '';
    }

    final key = _habitKey(widget.habit);
    final completed = prefs.getStringList(key) ?? [];
    final now = DateTime.now();
    // status for current week Mon-Sun
    for (int i = 1; i <= 7; i++) {
      final date = now.subtract(Duration(days: now.weekday - i));
      final str = date.toIso8601String().split('T').first;
      _weekDone[i] = completed.contains(str);
    }
    // streak calculation
    var day = now;
    while (completed.contains(day.toIso8601String().split('T').first)) {
      _streak++;
      day = day.subtract(const Duration(days: 1));
    }
    setState(() {});
  }

  String _habitKey(String h) => 'habit_${h.replaceAll(' ', '_')}';

  Future<void> _pickColor() async {
    final selected = await showDialog<Color>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Select Color'),
          content: Wrap(
            spacing: 8,
            children: habitColorPalette
                .map(
                  (c) => GestureDetector(
                    onTap: () => Navigator.pop(context, c),
                    child: CircleAvatar(backgroundColor: c, radius: 12),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
    if (selected != null) {
      setState(() => _color = selected);
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    // save color
    final colorData = prefs.getString('habit_colors');
    final colorMap =
        colorData != null ? Map<String, dynamic>.from(jsonDecode(colorData)) : {};
    colorMap[widget.habit] = _color.value;
    await prefs.setString('habit_colors', jsonEncode(colorMap));
    // save goal
    final goalData = prefs.getString('habit_goals');
    final goalMap =
        goalData != null ? Map<String, dynamic>.from(jsonDecode(goalData)) : {};
    goalMap[widget.habit] = _goalController.text.trim();
    await prefs.setString('habit_goals', jsonEncode(goalMap));
    // save week status
    final key = _habitKey(widget.habit);
    final completed = prefs.getStringList(key) ?? [];
    final now = DateTime.now();
    for (int i = 1; i <= 7; i++) {
      final date = now.subtract(Duration(days: now.weekday - i));
      final str = date.toIso8601String().split('T').first;
      final done = _weekDone[i] ?? false;
      if (done && !completed.contains(str)) {
        completed.add(str);
      } else if (!done && completed.contains(str)) {
        completed.remove(str);
      }
    }
    await prefs.setStringList(key, completed);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  String _weekdayLabel(int w) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[w - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Habit Info ${widget.habit}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton(onPressed: _pickColor, child: const Text('Select Color')),
          const SizedBox(height: 16),
          TextField(
            controller: _goalController,
            decoration: const InputDecoration(labelText: 'Goal'),
          ),
          const SizedBox(height: 16),
          Text('$_streak days in a row'),
          const SizedBox(height: 16),
          const Text('Weekdays'),
          Wrap(
            spacing: 8,
            children: [
              for (int i = 1; i <= 7; i++)
                FilterChip(
                  label: Text(_weekdayLabel(i)),
                  selected: _weekDone[i] ?? false,
                  onSelected: (v) => setState(() => _weekDone[i] = v),
                  selectedColor: _color.withOpacity(0.2),
                )
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _save, child: const Text('Edit Habit')),
        ],
      ),
    );
  }
}

