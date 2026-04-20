import 'package:equatable/equatable.dart';

enum NotificationType { newClient, morningSummary, payment, rental }

class NotificationEntity extends Equatable {
  final String id;
  final String title;
  final String content;
  final DateTime timestamp;
  final NotificationType type;
  final bool isRead;

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.content,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });

  @override
  List<Object?> get props => [id, title, content, timestamp, type, isRead];
}
