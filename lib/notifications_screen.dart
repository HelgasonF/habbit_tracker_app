import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

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
  String _timeZone = 'Auto';

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
      _timeZone = prefs.getString('timezone') ?? 'Auto';
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
    await prefs.setString('timezone', _timeZone);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.purpleAccent,
      ),
      backgroundColor: pastelBackgrounds.first,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: SwitchListTile(
              title: const Text(
                'Enable Notifications',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              value: _enabled,
              onChanged: (v) => setState(() => _enabled = v),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: SwitchListTile(
              title: const Text(
                'Daily reminder',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              value: _dailyReminder,
              onChanged: (v) => setState(() => _dailyReminder = v),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: SwitchListTile(
              title: const Text(
                'Streak Alerts',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              value: _streakAlerts,
              onChanged: (v) => setState(() => _streakAlerts = v),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: SwitchListTile(
              title: const Text(
                'Goal missed',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              value: _goalMissed,
              onChanged: (v) => setState(() => _goalMissed = v),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Customize Alerts',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _reminderTime,
                items: const [
                  DropdownMenuItem(value: '08:00', child: Text('08:00')),
                  DropdownMenuItem(value: '12:00', child: Text('12:00')),
                  DropdownMenuItem(value: '18:00', child: Text('18:00')),
                ],
                onChanged: (v) =>
                    setState(() => _reminderTime = v ?? '08:00'),
                isExpanded: true,
                hint: const Text('Reminder Time'),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _reminderHabit,
                hint: const Text('Add habit for reminder'),
                isExpanded: true,
                items: _habits
                    .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                    .toList(),
                onChanged: (v) => setState(() => _reminderHabit = v),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _timeZone,
                hint: const Text('Select Time Zone'),
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'Auto', child: Text('Auto (System Default)')),
                  DropdownMenuItem(value: 'UTC-8 (Pacific)', child: Text('UTC-8 (Pacific)')),
                  DropdownMenuItem(value: 'UTC-5 (Eastern)', child: Text('UTC-5 (Eastern)')),
                  DropdownMenuItem(value: 'UTC+0 (GMT)', child: Text('UTC+0 (GMT)')),
                  DropdownMenuItem(value: 'UTC+1 (Central Europe)', child: Text('UTC+1 (Central Europe)')),
                  DropdownMenuItem(value: 'UTC+9 (Japan)', child: Text('UTC+9 (Japan)')),
                ],
                onChanged: (v) => setState(() => _timeZone = v ?? 'Auto'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                shape: const StadiumBorder(),
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

