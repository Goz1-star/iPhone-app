import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class GoalNotificationService {
  GoalNotificationService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static GoalNotificationService create() {
    return GoalNotificationService(FlutterLocalNotificationsPlugin());
  }

  Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);
  }

  Future<void> showGoalReached(String goalName) async {
    const android = AndroidNotificationDetails(
      'facai_goal',
      '发财目标提醒',
      channelDescription: '存钱目标达成时提醒',
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    const details = NotificationDetails(android: android, iOS: ios);
    await _plugin.show(
      1,
      '发财了！',
      '$goalName 已经攒满，今天直接暴富。',
      details,
    );
  }
}
