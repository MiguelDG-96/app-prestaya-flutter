import 'package:app_prestaya_flutter/core/network/dio_client.dart';
import 'package:app_prestaya_flutter/features/notifications/domain/entities/notification_entity.dart';
import 'package:app_prestaya_flutter/features/notifications/domain/repositories/notifications_repository.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final DioClient dioClient;

  NotificationsRepositoryImpl({required this.dioClient});

  @override
  Future<List<NotificationEntity>> getNotifications(String email) async {
    try {
      final response = await dioClient.get('/notifications/user/$email');
      final List<dynamic> data = response.data;
      
      return data.map((json) => NotificationEntity(
        id: json['id'],
        title: json['title'],
        content: json['description'] ?? '',
        timestamp: DateTime.parse(json['createdAt']),
        type: _parseType(json['type']),
        isRead: json['isRead'] ?? false,
      )).toList();
    } catch (e) {
      throw Exception('Error al obtener notificaciones: $e');
    }
  }

  @override
  Future<void> markAllAsRead(String email) async {
    try {
      await dioClient.put('/notifications/read-all/$email');
    } catch (e) {
      throw Exception('Error al marcar como leídas: $e');
    }
  }

  NotificationType _parseType(String type) {
    switch (type) {
      case 'LOAN_UPCOMING':
      case 'RENTAL_UPCOMING':
        return NotificationType.morningSummary;
      case 'LOAN_OVERDUE':
      case 'RENTAL_OVERDUE':
        return NotificationType.morningSummary; // Or add a new type if needed
      case 'PAYMENT':
        return NotificationType.newClient;
      default:
        return NotificationType.morningSummary;
    }
  }
}
