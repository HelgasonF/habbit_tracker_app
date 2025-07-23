import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Map<String, int> _completedCounts = {};
  List<String> _habits = [];
  List<int> _dailyTotals = List.filled(7, 0);
  double _averageStreak = 0;
  double _completionRate = 0;
  String _bestDay = '';

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
    final daily = List<int>.filled(7, 0);
    double streakSum = 0;
    for (final h in habits) {
      final key = 'habit_${h.replaceAll(' ', '_')}';
      final completed = prefs.getStringList(key) ?? [];
      counts[h] = completed.where((d) => last7.contains(d)).length;
      // streak calculation
      int streak = 0;
      var day = now;
      while (completed.contains(day.toIso8601String().split('T').first)) {
        streak++;
        day = day.subtract(const Duration(days: 1));
      }
      streakSum += streak;
      // daily totals
      for (int i = 0; i < 7; i++) {
        if (completed.contains(last7[i])) {
          daily[i] += 1;
        }
      }
    }
    // compute completion rate & best day
    int totalCompletions = daily.fold(0, (a, b) => a + b);
    double compRate = habits.isEmpty ? 0 : (totalCompletions / (habits.length * 7)) * 100;
    int bestIndex = daily.indexOf(daily.reduce((a, b) => a > b ? a : b));
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    setState(() {
      _habits = habits;
      _completedCounts = counts;
      _dailyTotals = daily.reversed.toList();
      _averageStreak = habits.isEmpty ? 0 : streakSum / habits.length;
      _completionRate = compRate;
      _bestDay = days[(6 - bestIndex) % 7];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Report')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int i = 0; i < 7; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: (_habits.isEmpty
                                    ? 0.0
                                    : (_dailyTotals[i] / _habits.length) * 100)
                                .clamp(0.0, 100.0),
                            decoration: BoxDecoration(
                              color: habitColorPalette[i % habitColorPalette.length],
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][i]),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text('Best day: $_bestDay'),
          ),
          const Divider(height: 40),
          ..._habits.map(
            (h) => ListTile(
              title: Text(h),
              subtitle: LinearProgressIndicator(
                value: (_completedCounts[h] ?? 0) / 7,
                minHeight: 6,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Done ${_completedCounts[h] ?? 0}'),
                  Text('Missed ${7 - (_completedCounts[h] ?? 0)}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  
}

