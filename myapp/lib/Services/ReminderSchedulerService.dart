import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:myapp/Models/ReminderModel.dart';
import 'package:myapp/Services/AuthService.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class ReminderSchedulerService {
  ReminderSchedulerService._();

  static final ReminderSchedulerService instance = ReminderSchedulerService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final Set<String> _recordedHistoryKeys = {};

  Timer? _foregroundTimer;
  bool _initialized = false;
  bool _syncing = false;
  List<ReminderModel> _activeReminders = [];

  bool get _supportsLocalScheduling {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  Future<void> init() async {
    if (_initialized || !_supportsLocalScheduling) return;

    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation("Asia/Jakarta"));

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings("@mipmap/ic_launcher"),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    await _notifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    await _requestPermissions();
    await _handleLaunchFromNotification();

    _initialized = true;
  }

  Future<void> syncFromBackend() async {
    if (_syncing) return;
    _syncing = true;

    try {
      final reminders = await AuthService.getReminders();
      _activeReminders = reminders
          .where((reminder) => reminder.isActive)
          .toList();
      _startForegroundHistoryMonitor();

      if (!_supportsLocalScheduling) return;
      await init();
      await _notifications.cancelAll();

      var notificationId = 1000;
      for (final reminder in _activeReminders) {
        for (final weekday in _weekdaysFrom(reminder.daysActive)) {
          await _scheduleWeeklyReminder(
            notificationId: notificationId++,
            reminder: reminder,
            weekday: weekday,
          );
        }
      }
    } finally {
      _syncing = false;
    }
  }

  Future<void> resyncSafely() async {
    try {
      await syncFromBackend();
    } catch (_) {
      // Notification scheduling must not block reminder CRUD flows.
    }
  }

  Future<void> stop() async {
    _foregroundTimer?.cancel();
    _foregroundTimer = null;
    _activeReminders = [];
    if (_supportsLocalScheduling && _initialized) {
      await _notifications.cancelAll();
    }
  }

  Future<void> _scheduleWeeklyReminder({
    required int notificationId,
    required ReminderModel reminder,
    required int weekday,
  }) async {
    final time = _parseTime(reminder.timeScheduled);
    if (time == null) return;

    await _notifications.zonedSchedule(
      id: notificationId,
      title: reminder.title,
      body: reminder.note.isEmpty ? "PocketLog reminder" : reminder.note,
      scheduledDate: _nextWeekdayTime(weekday, time),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          "pocketlog_reminders",
          "PocketLog Reminders",
          channelDescription: "Scheduled wallet reminders",
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: jsonEncode({
        "reminder_id": reminder.id,
        "title": reminder.title,
        "note": reminder.note,
      }),
    );
  }

  void _startForegroundHistoryMonitor() {
    _foregroundTimer ??= Timer.periodic(const Duration(minutes: 1), (_) {
      _recordDueHistories();
    });
    unawaited(_recordDueHistories());
  }

  Future<void> _recordDueHistories() async {
    final now = DateTime.now();
    final currentTime =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final today = now.weekday;

    for (final reminder in _activeReminders) {
      final time = _parseTime(reminder.timeScheduled);
      if (time == null) continue;
      final reminderTime =
          "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
      if (reminderTime != currentTime) continue;
      if (!_weekdaysFrom(reminder.daysActive).contains(today)) continue;

      final historyKey =
          "${reminder.id}-${now.year}-${now.month}-${now.day}-$currentTime";
      if (!_recordedHistoryKeys.add(historyKey)) continue;

      await _createHistory(
        reminderId: reminder.id,
        title: reminder.title,
        note: reminder.note,
      );
    }
  }

  Future<void> _handleLaunchFromNotification() async {
    final launchDetails = await _notifications
        .getNotificationAppLaunchDetails();
    final response = launchDetails?.notificationResponse;
    if (launchDetails?.didNotificationLaunchApp == true && response != null) {
      await _handleNotificationResponse(response);
    }
  }

  Future<void> _handleNotificationResponse(
    NotificationResponse response,
  ) async {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    try {
      final data = jsonDecode(payload);
      if (data is! Map<String, dynamic>) return;

      final reminderId = data["reminder_id"]?.toString() ?? "";
      final title = data["title"]?.toString() ?? "";
      final note = data["note"]?.toString();
      if (reminderId.isEmpty || title.isEmpty) return;

      final now = DateTime.now();
      final historyKey =
          "$reminderId-${now.year}-${now.month}-${now.day}-${now.hour}-${now.minute}";
      if (!_recordedHistoryKeys.add(historyKey)) return;

      await _createHistory(reminderId: reminderId, title: title, note: note);
    } catch (_) {
      return;
    }
  }

  Future<void> _createHistory({
    required String reminderId,
    required String title,
    String? note,
  }) async {
    try {
      await AuthService.createNotificationHistory(
        reminderId: reminderId,
        title: title,
        note: note == null || note.isEmpty ? null : note,
      );
    } catch (_) {
      // History write is best-effort because notifications should still work offline.
    }
  }

  Future<void> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.macOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  tz.TZDateTime _nextWeekdayTime(int weekday, TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    while (scheduledDate.weekday != weekday || !scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  TimeOfDay? _parseTime(String value) {
    final parts = value.split(":");
    if (parts.length < 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

    return TimeOfDay(hour: hour, minute: minute);
  }

  List<int> _weekdaysFrom(String daysActive) {
    return daysActive
        .split(",")
        .map((day) => _weekdayFromName(day.trim()))
        .whereType<int>()
        .toSet()
        .toList();
  }

  int? _weekdayFromName(String day) {
    switch (day.toLowerCase()) {
      case "monday":
      case "mon":
        return DateTime.monday;
      case "tuesday":
      case "tue":
        return DateTime.tuesday;
      case "wednesday":
      case "wed":
        return DateTime.wednesday;
      case "thursday":
      case "thu":
        return DateTime.thursday;
      case "friday":
      case "fri":
        return DateTime.friday;
      case "saturday":
      case "sat":
        return DateTime.saturday;
      case "sunday":
      case "sun":
        return DateTime.sunday;
      default:
        return null;
    }
  }
}
