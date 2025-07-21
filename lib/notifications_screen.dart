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
  final Map<String, bool> _times = {
    'Morning': false,
    'Afternoon': false,
    'Evening': false,
  };

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
      for (final t in _times.keys) {
        _times[t] = prefs.getBool('notify_${t.toLowerCase()}') ?? false;
      }
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notify_enabled', _enabled);
    await prefs.setStringList('notify_habits', _selectedHabits.toList());
    for (final entry in _times.entries) {
      await prefs.setBool('notify_${entry.key.toLowerCase()}', entry.value);
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
          const Divider(),
          const Text('Habits'),
          ..._habits.map((h) => CheckboxListTile(
                title: Text(h),
                value: _selectedHabits.contains(h),
                onChanged: (v) => setState(() {
                  if (v == true) {
                    _selectedHabits.add(h);
                  } else {
                    _selectedHabits.remove(h);
                  }
                }),
              )),
          const Divider(),
          const Text('Times'),
          ..._times.keys.map((t) => CheckboxListTile(
                title: Text(t),
                value: _times[t],
                onChanged: (v) => setState(() => _times[t] = v ?? false),
              )),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
    );
  }
}

