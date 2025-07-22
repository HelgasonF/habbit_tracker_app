import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'habit_detail_screen.dart';

class HabitInfoScreen extends StatefulWidget {
  const HabitInfoScreen({super.key});

  @override
  State<HabitInfoScreen> createState() => _HabitInfoScreenState();
}

class _HabitInfoScreenState extends State<HabitInfoScreen> {
  List<String> _habits = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _habits = prefs.getStringList('habits') ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Habit Info')),
      body: ListView(
        children: _habits
            .map(
              (h) => ListTile(
                title: Text(h),
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
      ),
    );
  }
}
