import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final TextEditingController _controller = TextEditingController();
  List<String> _habits = [];
  final Map<String, Color> _habitColors = {};
  Color _newColor = Colors.blue;

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

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _habits = prefs.getStringList('habits') ?? [];
      final colorData = prefs.getString('habit_colors');
      if (colorData != null) {
        final map = jsonDecode(colorData) as Map<String, dynamic>;
        _habitColors.clear();
        map.forEach((k, v) => _habitColors[k] = Color(v as int));
      }
    });
  }

  Future<void> _addHabit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (_habits.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum of 10 habits allowed')),
      );
      return;
    }
    setState(() {
      _habits.add(text);
      _habitColors[text] = _newColor;
      _controller.clear();
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('habits', _habits);
    final map = _habitColors.map((k, v) => MapEntry(k, v.value));
    await prefs.setString('habit_colors', jsonEncode(map));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added "$text"')),
    );
  }

  Future<void> _removeHabit(String habit) async {
    setState(() {
      _habits.remove(habit);
      _habitColors.remove(habit);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('habits', _habits);
    final map = _habitColors.map((k, v) => MapEntry(k, v.value));
    await prefs.setString('habit_colors', jsonEncode(map));
    final notify = prefs.getStringList('notify_habits') ?? [];
    notify.remove(habit);
    await prefs.setStringList('notify_habits', notify);
    await prefs.remove('habit_${habit.replaceAll(' ', '_')}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Removed "$habit"')),
    );
  }

  Future<void> _changeColor(String habit) async {
    final selected = await _pickColor(_habitColors[habit] ?? Colors.blue);
    if (selected == null) return;
    setState(() => _habitColors[habit] = selected);
    final prefs = await SharedPreferences.getInstance();
    final map = _habitColors.map((k, v) => MapEntry(k, v.value));
    await prefs.setString('habit_colors', jsonEncode(map));
  }

  Future<Color?> _pickColor(Color current) {
    return showDialog<Color>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select color'),
          content: Wrap(
            spacing: 8,
            children: _palette
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Habits')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _habits.length,
              itemBuilder: (context, index) {
                final habit = _habits[index];
                final color = _habitColors[habit] ?? Colors.blue;
                return Dismissible(
                  key: ValueKey(habit),
                  onDismissed: (_) => _removeHabit(habit),
                  background: Container(color: Colors.red),
                  child: ListTile(
                    title: Text(habit),
                    trailing: GestureDetector(
                      onTap: () => _changeColor(habit),
                      child: CircleAvatar(backgroundColor: color, radius: 10),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'New habit'),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final sel = await _pickColor(_newColor);
                    if (sel != null) setState(() => _newColor = sel);
                  },
                  child: CircleAvatar(backgroundColor: _newColor, radius: 10),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addHabit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

