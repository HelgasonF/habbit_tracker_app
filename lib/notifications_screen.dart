import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _enabled = false;
  List<String> _habits = [];
  final Set<String> _selectedHabits = {};
  final Map<String, bool> _timeSlots = {
    'Morning': false,
    'Afternoon': false,
    'Evening': false,
  };
  bool _dailyReminder = false;
  bool _streakAlerts = false;
  bool _goalMissed = false;
  String _reminderTime = '08:00';
  String? _reminderHabit;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enabled = prefs.getBool('notify_enabled') ?? false;
      _selectedHabits.addAll(prefs.getStringList('notify_habits') ?? []);
      _habits = prefs.getStringList('habits') ?? [];
      for (final t in _timeSlots.keys) {
        _timeSlots[t] = prefs.getBool('notify_${t.toLowerCase()}') ?? false;
      }
      _dailyReminder = prefs.getBool('daily_reminder') ?? false;
      _streakAlerts = prefs.getBool('streak_alert') ?? false;
      _goalMissed = prefs.getBool('goal_missed') ?? false;
      _reminderTime = prefs.getString('reminder_time') ?? '08:00';
      _reminderHabit = prefs.getString('reminder_habit');
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notify_enabled', _enabled);
    await prefs.setStringList('notify_habits', _selectedHabits.toList());
    for (final entry in _timeSlots.entries) {
      await prefs.setBool('notify_${entry.key.toLowerCase()}', entry.value);
    }
    await prefs.setBool('daily_reminder', _dailyReminder);
    await prefs.setBool('streak_alert', _streakAlerts);
    await prefs.setBool('goal_missed', _goalMissed);
    await prefs.setString('reminder_time', _reminderTime);
    if (_reminderHabit != null) {
      await prefs.setString('reminder_habit', _reminderHabit!);
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Enable Notifications'),
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v),
          ),
          SwitchListTile(
            title: const Text('Daily reminder'),
            value: _dailyReminder,
            onChanged: (v) => setState(() => _dailyReminder = v),
          ),
          SwitchListTile(
            title: const Text('Streak Alerts'),
            value: _streakAlerts,
            onChanged: (v) => setState(() => _streakAlerts = v),
          ),
          SwitchListTile(
            title: const Text('Goal missed'),
            value: _goalMissed,
            onChanged: (v) => setState(() => _goalMissed = v),
          ),
          const Divider(),
          const Text('Customize Alerts'),
          const SizedBox(height: 10),
          DropdownButton<String>(
            value: _reminderTime,
            items: const [
              DropdownMenuItem(value: '08:00', child: Text('08:00')),
              DropdownMenuItem(value: '12:00', child: Text('12:00')),
              DropdownMenuItem(value: '18:00', child: Text('18:00')),
            ],
            onChanged: (v) => setState(() => _reminderTime = v ?? '08:00'),
            isExpanded: true,
            hint: const Text('Reminder Time'),
          ),
          const SizedBox(height: 10),
          DropdownButton<String>(
            value: _reminderHabit,
            hint: const Text('Add habit for reminder'),
            isExpanded: true,
            items: _habits
                .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                .toList(),
            onChanged: (v) => setState(() => _reminderHabit = v),
          ),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
    );
  }
}

