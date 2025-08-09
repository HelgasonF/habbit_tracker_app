import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/theme_service.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';

class SettingsScreen extends StatefulWidget {
  final ThemeService themeService;
  
  const SettingsScreen({super.key, required this.themeService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = false;
  bool _dataBackup = true;
  String _language = 'English';
  String _timeZone = 'Auto';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notify_enabled') ?? false;
      _dataBackup = prefs.getBool('data_backup') ?? true;
      _language = prefs.getString('language') ?? 'English';
      _timeZone = prefs.getString('timezone') ?? 'Auto';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notify_enabled', _notificationsEnabled);
    await prefs.setBool('data_backup', _dataBackup);
    await prefs.setString('language', _language);
    await prefs.setString('timezone', _timeZone);
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(children: children),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // Profile Section
          _buildSettingsSection(
            'Profile',
            [
              _buildSettingsTile(
                icon: Icons.person,
                title: 'Edit Profile',
                subtitle: 'Update your personal information',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
              _buildSettingsTile(
                icon: Icons.security,
                title: 'Account Security',
                subtitle: 'Password and security settings',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Implement account security screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Coming soon!')),
                  );
                },
              ),
            ],
          ),

          // Appearance Section
          _buildSettingsSection(
            'Appearance',
            [
              _buildSettingsTile(
                icon: Icons.dark_mode,
                title: 'Dark Mode',
                subtitle: 'Switch between light and dark themes',
                trailing: Switch(
                  value: widget.themeService.isDarkMode,
                  onChanged: (value) {
                    widget.themeService.toggleTheme();
                  },
                ),
              ),
              _buildSettingsTile(
                icon: Icons.language,
                title: 'Language',
                subtitle: _language,
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showLanguageDialog();
                },
              ),
            ],
          ),

          // Notifications Section
          _buildSettingsSection(
            'Notifications',
            [
              _buildSettingsTile(
                icon: Icons.notifications,
                title: 'Manage Notifications',
                subtitle: 'Configure habit reminders and alerts',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  );
                },
              ),
              _buildSettingsTile(
                icon: Icons.access_time,
                title: 'Time Zone',
                subtitle: _timeZone,
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showTimeZoneDialog();
                },
              ),
            ],
          ),

          // Data & Privacy Section
          _buildSettingsSection(
            'Data & Privacy',
            [
              _buildSettingsTile(
                icon: Icons.backup,
                title: 'Data Backup',
                subtitle: 'Automatically backup your habit data',
                trailing: Switch(
                  value: _dataBackup,
                  onChanged: (value) {
                    setState(() {
                      _dataBackup = value;
                    });
                    _saveSettings();
                  },
                ),
              ),
              _buildSettingsTile(
                icon: Icons.delete_forever,
                title: 'Clear All Data',
                subtitle: 'Reset all habits and progress',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showClearDataDialog();
                },
              ),
            ],
          ),

          // About Section
          _buildSettingsSection(
            'About',
            [
              _buildSettingsTile(
                icon: Icons.info,
                title: 'App Version',
                subtitle: '1.0.0',
              ),
              _buildSettingsTile(
                icon: Icons.help,
                title: 'Help & Support',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contact support: help@habittracker.com')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'English',
            'Spanish',
            'French',
            'German',
            'Italian',
          ]
              .map((lang) => RadioListTile<String>(
                    title: Text(lang),
                    value: lang,
                    groupValue: _language,
                    onChanged: (value) {
                      setState(() {
                        _language = value!;
                      });
                      _saveSettings();
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _showTimeZoneDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Time Zone'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'Auto',
            'UTC-8 (Pacific)',
            'UTC-5 (Eastern)',
            'UTC+0 (GMT)',
            'UTC+1 (Central Europe)',
            'UTC+9 (Japan)',
          ]
              .map((tz) => RadioListTile<String>(
                    title: Text(tz),
                    value: tz,
                    groupValue: _timeZone,
                    onChanged: (value) {
                      setState(() {
                        _timeZone = value!;
                      });
                      _saveSettings();
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all your habits, progress, and settings. This action cannot be undone.\n\nAre you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data cleared successfully')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );
  }
}