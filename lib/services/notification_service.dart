
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance =
  NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> initNotification() async {
    try {
      tz_data.initializeTimeZones();

      const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(settings);

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e, stackTrace) {
      debugPrint('Error initializing notifications: $e');
      debugPrint('$stackTrace');
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) {
      debugPrint('SCHEDULE_NOTIFICATION_ERROR: Time is in the past.');
      return;
    }

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'shopping_reminder_channel',
            'تذكيرات خطة الطبخ',
            channelDescription:
            'إشعارات لتذكيرك بمكونات وعناصر خطة الطبخ',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint(
        'SCHEDULE_NOTIFICATION_SUCCESS: ID=$id, time=$scheduledTime',
      );
    } catch (e, stackTrace) {
      debugPrint('SCHEDULE_NOTIFICATION_ERROR: $e');
      debugPrint('$stackTrace');
    }
  }



  Future<void> showScheduledTestNotification() async {
    final scheduledTime = DateTime.now().add(const Duration(minutes: 1));

    debugPrint(
      'SCHEDULED_TEST: Requesting notification for $scheduledTime',
    );

    await scheduleNotification(
      id: 9998,
      title: 'Wasfaty scheduled test',
      body: 'Scheduled notifications are working!',
      scheduledTime: scheduledTime,
    );

    await checkPendingNotifications();
    await checkExactAlarmPermission();
  }



  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
    } catch (e) {
      debugPrint('Error canceling notification: $e');
    }
  }
  Future<void> checkPendingNotifications() async {
    try {
      final pending =
      await _notificationsPlugin.pendingNotificationRequests();

      debugPrint('PENDING_NOTIFICATIONS_COUNT: ${pending.length}');

      for (final notification in pending) {
        debugPrint(
          'PENDING_NOTIFICATION: '
              'ID=${notification.id}, '
              'TITLE=${notification.title}',
        );
      }

      final testExists = pending.any(
            (notification) => notification.id == 9998,
      );

      debugPrint('TEST_NOTIFICATION_9998_PENDING: $testExists');
    } catch (e, stackTrace) {
      debugPrint('CHECK_PENDING_NOTIFICATIONS_ERROR: $e');
      debugPrint('$stackTrace');
    }
  }

  Future<void> checkExactAlarmPermission() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    final canSchedule = await androidPlugin
        ?.canScheduleExactNotifications();

    debugPrint('EXACT_ALARM_PERMISSION: $canSchedule');
  }

}
