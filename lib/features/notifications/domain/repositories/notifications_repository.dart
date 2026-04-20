import 'package:app_prestaya_flutter/features/notifications/domain/entities/notification_entity.dart';

abstract class NotificationsRepository {
  Future<List<NotificationEntity>> getNotifications(String email);
  Future<void> markAllAsRead(String email);
}
