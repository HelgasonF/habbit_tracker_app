import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _quotesBaseUrl = 'https://api.quotable.io';
  static const String _adviceBaseUrl = 'https://api.adviceslip.com';

  // Fetch daily motivational quote
  static Future<Map<String, String>> fetchDailyQuote() async {
    try {
      final response = await http.get(
        Uri.parse('$_quotesBaseUrl/random?tags=motivational,inspirational,success'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'content': data['content'] ?? 'Stay motivated and keep going!',
          'author': data['author'] ?? 'Unknown',
        };
      }
    } catch (e) {
      print('Error fetching quote: $e');
    }
    
    // Fallback quotes if API fails
    final fallbackQuotes = [
      {'content': 'The secret of getting ahead is getting started.', 'author': 'Mark Twain'},
      {'content': 'Success is not final, failure is not fatal: it is the courage to continue that counts.', 'author': 'Winston Churchill'},
      {'content': 'The only way to do great work is to love what you do.', 'author': 'Steve Jobs'},
      {'content': 'Your limitation—it\'s only your imagination.', 'author': 'Unknown'},
      {'content': 'Push yourself, because no one else is going to do it for you.', 'author': 'Unknown'},
    ];
    
    final random = DateTime.now().day % fallbackQuotes.length;
    return fallbackQuotes[random];
  }

  // Fetch habit suggestions based on current habits
  static Future<List<String>> fetchHabitSuggestions(List<String> currentHabits) async {
    try {
      // For now, return curated suggestions based on existing habits
      // In a real app, this would call an AI service or habit database
      final allSuggestions = [
        'Meditate for 10 minutes',
        'Walk 10,000 steps',
        'Drink 8 glasses of water',
        'Read for 30 minutes',
        'Write in a journal',
        'Practice gratitude',
        'Do 20 push-ups',
        'Learn a new word',
        'Take a cold shower',
        'Stretch for 15 minutes',
        'Call a friend or family member',
        'Practice deep breathing',
        'Eat a healthy breakfast',
        'Listen to a podcast',
        'Plan tomorrow\'s tasks',
        'Take photos of nature',
        'Practice a musical instrument',
        'Do yoga',
        'Declutter one area',
        'Learn something new',
      ];

      // Filter out habits user already has and return random suggestions
      final filtered = allSuggestions
          .where((suggestion) => !currentHabits.contains(suggestion))
          .toList();
      
      filtered.shuffle();
      return filtered.take(5).toList();
    } catch (e) {
      print('Error fetching habit suggestions: $e');
      return [
        'Meditate for 10 minutes',
        'Walk 10,000 steps',
        'Read for 30 minutes',
        'Practice gratitude',
        'Drink more water',
      ];
    }
  }

  // Fetch daily advice for habits
  static Future<String> fetchDailyAdvice() async {
    try {
      final response = await http.get(
        Uri.parse('$_adviceBaseUrl/advice'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['slip']['advice'] ?? 'Focus on progress, not perfection.';
      }
    } catch (e) {
      print('Error fetching advice: $e');
    }
    
    // Fallback advice
    final fallbackAdvice = [
      'Focus on progress, not perfection.',
      'Small steps daily lead to big changes yearly.',
      'Consistency beats perfection every time.',
      'Your habits shape your identity.',
      'Start where you are, use what you have, do what you can.',
    ];
    
    final random = DateTime.now().day % fallbackAdvice.length;
    return fallbackAdvice[random];
  }
}