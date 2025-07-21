import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _countryController = TextEditingController();
  double _age = 20;
  String _country = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('name') ?? '';
      _usernameController.text = prefs.getString('username') ?? '';
      _age = (prefs.getInt('age') ?? 20).toDouble();
      _country = prefs.getString('country') ?? '';
      _countryController.text = _country;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', _nameController.text.trim());
    await prefs.setString('username', _usernameController.text.trim());
    await prefs.setInt('age', _age.round());
    _country = _countryController.text.trim();
    await prefs.setString('country', _country);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            Row(
              children: [
                const Text('Age:'),
                Expanded(
                  child: Slider(
                    value: _age,
                    min: 10,
                    max: 100,
                    divisions: 90,
                    label: _age.round().toString(),
                    onChanged: (v) => setState(() => _age = v),
                  ),
                ),
              ],
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Country'),
              controller: _countryController,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}

