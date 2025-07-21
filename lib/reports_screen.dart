import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Map<String, int> _weeklyCounts = {};
  List<String> _habits = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final habits = prefs.getStringList('habits') ?? [];
    final now = DateTime.now();
    final last7 = [for (int i = 0; i < 7; i++) now.subtract(Duration(days: i)).toIso8601String().split('T').first];
    final counts = <String, int>{};
    for (final h in habits) {
      final key = 'habit_${h.replaceAll(' ', '_')}';
      final completed = prefs.getStringList(key) ?? [];
      counts[h] = completed.where((d) => last7.contains(d)).length;
    }
    setState(() {
      _habits = habits;
      _weeklyCounts = counts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Report')),
      body: ListView(
        children: _habits
            .map((h) => ListTile(
                  title: Text(h),
                  trailing: Text('${_weeklyCounts[h] ?? 0}/7'),
                ))
            .toList(),
      ),
    );
  }
}

