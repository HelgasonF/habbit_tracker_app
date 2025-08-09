import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for iOS
    if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
      await _requestIOSPermissions();
    }

    // Request permissions for Android 13+
    if (!kIsWeb && Platform.isAndroid) {
      await _requestAndroidPermissions();
    }

    _initialized = true;
  }

  Future<void> _requestIOSPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> _requestAndroidPermissions() async {
    final plugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await plugin?.requestNotificationsPermission();
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    print('Notification tapped: ${response.payload}');
  }

  // Schedule daily habit reminder
  Future<void> scheduleDailyReminder({
    required String habitName,
    required int hour,
    required int minute,
    String? timeZone,
  }) async {
    await initialize();

    final id = habitName.hashCode.abs() % 100000; // Generate unique ID

    const androidDetails = AndroidNotificationDetails(
      'habit_reminders',
      'Habit Reminders',
      channelDescription: 'Daily reminders for your habits',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      'Habit Reminder',
      'Time to work on your habit: $habitName',
      _nextInstanceOfTime(hour, minute),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'habit_reminder_$habitName',
    );
  }

  // Schedule streak alert
  Future<void> scheduleStreakAlert({
    required String habitName,
    required int streak,
  }) async {
    await initialize();

    final id = ('streak_$habitName').hashCode.abs() % 100000;

    const androidDetails = AndroidNotificationDetails(
      'streak_alerts',
      'Streak Alerts',
      channelDescription: 'Notifications for habit streaks',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      'Streak Achievement! 🎉',
      'Congratulations! You have a $streak day streak for $habitName',
      notificationDetails,
      payload: 'streak_$habitName',
    );
  }

  // Schedule goal missed alert
  Future<void> scheduleGoalMissedAlert({
    required String habitName,
  }) async {
    await initialize();

    final id = ('goal_missed_$habitName').hashCode.abs() % 100000;

    const androidDetails = AndroidNotificationDetails(
      'goal_alerts',
      'Goal Alerts',
      channelDescription: 'Notifications for missed goals',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      'Goal Missed',
      'You missed your goal for $habitName today. Don\'t give up!',
      notificationDetails,
      payload: 'goal_missed_$habitName',
    );
  }

  // Send test notification
  Future<void> sendTestNotification() async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'test_notifications',
      'Test Notifications',
      channelDescription: 'Test notifications for the habit tracker',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999999,
      'Test Notification',
      'This is a test notification from Habit Tracker!',
      notificationDetails,
      payload: 'test_notification',
    );
  }

  // Cancel all notifications for a habit
  Future<void> cancelHabitNotifications(String habitName) async {
    final id = habitName.hashCode.abs() % 100000;
    await _notifications.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Setup all habit reminders based on user preferences
  Future<void> setupHabitReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notify_enabled') ?? false;
    
    if (!enabled) return;

    final habits = prefs.getStringList('habits') ?? [];
    final reminderTime = prefs.getString('reminder_time') ?? '08:00';
    final parts = reminderTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    // Cancel existing notifications
    await cancelAllNotifications();

    // Schedule new reminders for each habit
    for (final habit in habits) {
      await scheduleDailyReminder(
        habitName: habit,
        hour: hour,
        minute: minute,
      );
    }
  }

  // Check and trigger streak notifications
  Future<void> checkStreakNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final streakAlertsEnabled = prefs.getBool('streak_alert') ?? false;
    
    if (!streakAlertsEnabled) return;

    final habits = prefs.getStringList('habits') ?? [];

    for (final habit in habits) {
      final key = 'habit_${habit.replaceAll(' ', '_')}';
      final completedDates = prefs.getStringList(key) ?? [];
      
      // Calculate streak
      int streak = 0;
      var day = DateTime.now();
      while (completedDates.contains(day.toIso8601String().split('T').first)) {
        streak++;
        day = day.subtract(const Duration(days: 1));
      }

      // Send notification for milestone streaks (7, 14, 21, 30 days, etc.)
      if (streak > 0 && (streak % 7 == 0 || streak == 30)) {
        final lastNotificationKey = 'last_streak_notification_$habit';
        final lastNotificationStreak = prefs.getInt(lastNotificationKey) ?? 0;
        
        if (streak > lastNotificationStreak) {
          await scheduleStreakAlert(habitName: habit, streak: streak);
          await prefs.setInt(lastNotificationKey, streak);
        }
      }
    }
  }

  // Helper to get next instance of a specific time
  TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = TZDateTime.now(local);
    var scheduledDate = TZDateTime(local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }
}

// Initialize timezone data
void initializeTimezones() {
  tz_data.initializeTimeZones();
}

// Get local timezone
tz.Location get local => tz.getLocation('UTC');

// Type alias for convenience
typedef TZDateTime = tz.TZDateTime;