import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'services/api_service.dart';
import 'constants.dart';

class HabitSuggestionsScreen extends StatefulWidget {
  const HabitSuggestionsScreen({super.key});

  @override
  State<HabitSuggestionsScreen> createState() => _HabitSuggestionsScreenState();
}

class _HabitSuggestionsScreenState extends State<HabitSuggestionsScreen> {
  List<String> _suggestions = [];
  List<String> _currentHabits = [];
  bool _isLoading = true;
  final Map<String, Color> _habitColors = {};

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _currentHabits = prefs.getStringList('habits') ?? [];
      
      // Load existing habit colors
      final colorData = prefs.getString('habit_colors');
      if (colorData != null) {
        final map = jsonDecode(colorData) as Map<String, dynamic>;
        _habitColors.clear();
        map.forEach((k, v) => _habitColors[k] = Color(v as int));
      }

      // Fetch suggestions from API
      final suggestions = await ApiService.fetchHabitSuggestions(_currentHabits);
      
      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading suggestions: $e');
      setState(() {
        _isLoading = false;
        _suggestions = [
          'Meditate for 10 minutes',
          'Walk 10,000 steps',
          'Read for 30 minutes',
          'Practice gratitude',
          'Drink more water',
        ];
      });
    }
  }

  Future<void> _addHabit(String habit) async {
    if (_currentHabits.length >= maxHabits) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum of $maxHabits habits allowed')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    
    // Add to habits list
    _currentHabits.add(habit);
    await prefs.setStringList('habits', _currentHabits);
    
    // Assign a color
    final color = habitColorPalette[_habitColors.length % habitColorPalette.length];
    _habitColors[habit] = color;
    final map = _habitColors.map((k, v) => MapEntry(k, v.value));
    await prefs.setString('habit_colors', jsonEncode(map));

    // Remove from suggestions and refresh
    setState(() {
      _suggestions.remove(habit);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "$habit" to your habits!'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(String suggestion) {
    final color = habitColorPalette[_suggestions.indexOf(suggestion) % habitColorPalette.length];
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getHabitIcon(suggestion),
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestion,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getHabitDescription(suggestion),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _addHabit(suggestion),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Add'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getHabitIcon(String habit) {
    if (habit.toLowerCase().contains('meditate')) return Icons.self_improvement;
    if (habit.toLowerCase().contains('walk') || habit.toLowerCase().contains('steps')) return Icons.directions_walk;
    if (habit.toLowerCase().contains('read')) return Icons.menu_book;
    if (habit.toLowerCase().contains('water') || habit.toLowerCase().contains('drink')) return Icons.local_drink;
    if (habit.toLowerCase().contains('gratitude')) return Icons.favorite;
    if (habit.toLowerCase().contains('push')) return Icons.fitness_center;
    if (habit.toLowerCase().contains('yoga')) return Icons.sports_gymnastics;
    if (habit.toLowerCase().contains('journal')) return Icons.edit_note;
    if (habit.toLowerCase().contains('music')) return Icons.music_note;
    if (habit.toLowerCase().contains('photo')) return Icons.photo_camera;
    return Icons.check_circle_outline;
  }

  String _getHabitDescription(String habit) {
    if (habit.toLowerCase().contains('meditate')) return 'Reduce stress and improve focus';
    if (habit.toLowerCase().contains('walk') || habit.toLowerCase().contains('steps')) return 'Stay active and healthy';
    if (habit.toLowerCase().contains('read')) return 'Expand your knowledge';
    if (habit.toLowerCase().contains('water') || habit.toLowerCase().contains('drink')) return 'Stay hydrated throughout the day';
    if (habit.toLowerCase().contains('gratitude')) return 'Improve mental well-being';
    if (habit.toLowerCase().contains('push')) return 'Build upper body strength';
    if (habit.toLowerCase().contains('yoga')) return 'Improve flexibility and balance';
    if (habit.toLowerCase().contains('journal')) return 'Reflect and organize thoughts';
    if (habit.toLowerCase().contains('music')) return 'Develop musical skills';
    if (habit.toLowerCase().contains('photo')) return 'Capture beautiful moments';
    return 'Build a positive routine';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Suggestions'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSuggestions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading personalized suggestions...'),
                ],
              ),
            )
          : Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.withOpacity(0.1), Colors.purple.withOpacity(0.1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Discover New Habits',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Based on your current habits, here are some suggestions to help you grow:',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Current habits count
                if (_currentHabits.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey[600], size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'You have ${_currentHabits.length}/$maxHabits habits',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Suggestions list
                Expanded(
                  child: _suggestions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No more suggestions available',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try refreshing or check back later!',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _suggestions.length,
                          itemBuilder: (context, index) {
                            return _buildSuggestionCard(_suggestions[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }
}