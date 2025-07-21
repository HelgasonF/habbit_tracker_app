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

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _habits = prefs.getStringList('habits') ?? [];
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
      _controller.clear();
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('habits', _habits);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added "$text"')),
    );
  }

  Future<void> _removeHabit(String habit) async {
    setState(() {
      _habits.remove(habit);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('habits', _habits);
    final notify = prefs.getStringList('notify_habits') ?? [];
    notify.remove(habit);
    await prefs.setStringList('notify_habits', notify);
    await prefs.remove('habit_${habit.replaceAll(' ', '_')}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Removed "$habit"')),
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
                return Dismissible(
                  key: ValueKey(habit),
                  onDismissed: (_) => _removeHabit(habit),
                  background: Container(color: Colors.red),
                  child: ListTile(title: Text(habit)),
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

