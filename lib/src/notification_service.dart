import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tapped logic here
      },
    );

    // Initialize Windows local_notifier
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      await localNotifier.setup(
        appName: 'Golden Paw Vault',
        shortcutPolicy: ShortcutPolicy.requireCreate,
      );
    }
  }

  Future<void> scheduleHungerNotification(DateTime expectedHungryTime) async {
    final title = 'Your Shiba is Hungry! 🦴';
    final body = 'Come back and feed your Shiba before it gets too sad.';

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      // Local Notifier for Windows doesn't support delayed scheduling out of the box in the same way,
      // but if the app is still open it could use a timer, or it could show immediately.
      // Usually, Windows local_notifier is for immediate notification.
      // To schedule in background on Windows is complex, we will show a notification if time is up.
      // For this implementation, we will skip background scheduling for Windows and just trigger it
      // when the time arrives if the app is running (handled by a Timer elsewhere).
      return;
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'shiba_hunger_channel',
      'Shiba Hunger Alerts',
      channelDescription: 'Notifications for when your Shiba gets hungry',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
    );

    if (expectedHungryTime.isAfter(DateTime.now())) {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        title,
        body,
        tz.TZDateTime.from(expectedHungryTime, tz.local),
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> scheduleBonusTimerNotification(Duration waitTime) async {
    final title = 'Bonus Ready! 🎁';
    final body = 'Your bonus timer has finished. Claim your rewards now!';
    
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      // Skip background scheduling for Windows as local_notifier only supports immediate.
      return;
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'bonus_timer_channel',
      'Bonus Timer Alerts',
      channelDescription: 'Notifications for when your bonus timer finishes',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
    );

    final scheduledTime = DateTime.now().add(waitTime);

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      1,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
