import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';
import 'habit_detail_screen.dart';

class HabitInfoScreen extends StatefulWidget {
  const HabitInfoScreen({super.key});

  @override
  State<HabitInfoScreen> createState() => _HabitInfoScreenState();
}

class _HabitInfoScreenState extends State<HabitInfoScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();
  List<String> _habits = [];
  final Map<String, Color> _habitColors = {};
  Color _newColor = habitColorPalette.first;

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

  bool _isPredefinedSelected(String habit) => _habits.contains(habit);

  Future<void> _togglePredefinedHabit(String habit) async {
    if (_isPredefinedSelected(habit)) {
      await _removeHabit(habit);
    } else {
      await _addHabit(habit);
    }
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
    await prefs.remove('habit_${habit.replaceAll(' ', '_')}');
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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

  Future<Color?> _pickColor(Color current) {
    return showDialog<Color>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select color'),
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
  }

  Future<void> _addHabit([String? preset]) async {
    final name = preset ?? _nameController.text.trim();
    if (name.isEmpty) return;
    if (_habits.length >= maxHabits) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum of $maxHabits habits allowed')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final color = preset != null
        ? habitColorPalette[_habitColors.length % habitColorPalette.length]
        : _newColor;
    setState(() {
      _habits.add(name);
      _habitColors[name] = color;
    });
    await prefs.setStringList('habits', _habits);
    final map = _habitColors.map((k, v) => MapEntry(k, v.value));
    await prefs.setString('habit_colors', jsonEncode(map));

    final goal = _goalController.text.trim();
    if (goal.isNotEmpty) {
      final goalData = prefs.getString('habit_goals');
      final goalMap =
          goalData != null ? Map<String, dynamic>.from(jsonDecode(goalData)) : {};
      goalMap[name] = goal;
      await prefs.setString('habit_goals', jsonEncode(goalMap));
    }

    _nameController.clear();
    _goalController.clear();
    setState(() => _newColor = habitColorPalette.first);
    _load();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added "$name"')),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF709CF0),
      appBar: AppBar(title: const Text('Habit Info')),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          ..._habits
              .map(
                (h) => ListTile(
                  title: Text(h),
                  leading: CircleAvatar(
                      backgroundColor: _habitColors[h] ?? habitColorPalette.first,
                      radius: 10),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => HabitDetailScreen(habit: h)),
                    );
                    _load();
                  },
                ),
              )
              .toList(),
          const Divider(),
          _buildInputField(_nameController, 'Habit name'),
          const SizedBox(height: 8),
          _buildInputField(_goalController, 'Goal (optional)'),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  final sel = await _pickColor(_newColor);
                  if (sel != null) setState(() => _newColor = sel);
                },
                child: CircleAvatar(backgroundColor: _newColor, radius: 12),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _addHabit,
                icon: const Icon(Icons.add),
                label: const Text('Add Habit'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Quick Add'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final h in predefinedHabits)
                FilterChip(
                  label: Text(h),
                  selected: _isPredefinedSelected(h),
                  onSelected: (_) => _togglePredefinedHabit(h),
                  selectedColor: Colors.blue.shade200,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
