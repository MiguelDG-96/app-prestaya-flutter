import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notifications_repository.dart';

// Eventos
abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();
  @override
  List<Object?> get props => [];
}

class LoadNotificationsRequested extends NotificationsEvent {
  final String email;
  const LoadNotificationsRequested(this.email);
  @override
  List<Object?> get props => [email];
}

class MarkAllAsReadRequested extends NotificationsEvent {
  final String email;
  const MarkAllAsReadRequested(this.email);
  @override
  List<Object?> get props => [email];
}

class MarkAsReadRequested extends NotificationsEvent {
  final String id;
  const MarkAsReadRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class AddNotificationRequested extends NotificationsEvent {
  final NotificationEntity notification;
  const AddNotificationRequested(this.notification);
  @override
  List<Object?> get props => [notification];
}

// Estados
abstract class NotificationsState extends Equatable {
  const NotificationsState();
  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {}

class NotificationsLoading extends NotificationsState {}

class NotificationsLoaded extends NotificationsState {
  final List<NotificationEntity> notifications;
  final int unreadCount;

  const NotificationsLoaded({
    required this.notifications,
    required this.unreadCount,
  });

  @override
  List<Object?> get props => [notifications, unreadCount];
}

class NotificationsError extends NotificationsState {
  final String message;
  const NotificationsError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationsRepository repository;

  NotificationsBloc({required this.repository}) : super(NotificationsInitial()) {
    on<LoadNotificationsRequested>((event, emit) async {
      emit(NotificationsLoading());
      try {
        final notifications = await repository.getNotifications(event.email);
        emit(NotificationsLoaded(
          notifications: notifications,
          unreadCount: notifications.where((n) => !n.isRead).length,
        ));
      } catch (e) {
        emit(NotificationsError(e.toString()));
      }
    });

    on<MarkAllAsReadRequested>((event, emit) async {
      try {
        await repository.markAllAsRead(event.email);
        if (state is NotificationsLoaded) {
          final currentState = state as NotificationsLoaded;
          final updatedNotifications = currentState.notifications.map((n_obj) {
            final n = n_obj as NotificationEntity;
            return NotificationEntity(
              id: n.id,
              title: n.title,
              content: n.content,
              timestamp: n.timestamp,
              type: n.type,
              isRead: true,
            );
          }).toList();
          
          emit(NotificationsLoaded(
            notifications: updatedNotifications,
            unreadCount: 0,
          ));
        }
      } catch (e) {
        // Silently fail or emit error
      }
    });

    on<MarkAsReadRequested>((event, emit) {
      if (state is NotificationsLoaded) {
        final currentState = state as NotificationsLoaded;
        final updatedNotifications = currentState.notifications.map((n_obj) {
          final n = n_obj as NotificationEntity;
          if (n.id == event.id) {
            return NotificationEntity(
              id: n.id,
              title: n.title,
              content: n.content,
              timestamp: n.timestamp,
              type: n.type,
              isRead: true,
            );
          }
          return n;
        }).toList();
        
        emit(NotificationsLoaded(
          notifications: updatedNotifications,
          unreadCount: updatedNotifications.where((n) => !n.isRead).length,
        ));
      }
    });

    on<AddNotificationRequested>((event, emit) {
      if (state is NotificationsLoaded) {
        final currentState = state as NotificationsLoaded;
        final updatedNotifications = [event.notification, ...currentState.notifications];
        
        emit(NotificationsLoaded(
          notifications: updatedNotifications,
          unreadCount: updatedNotifications.where((n) => !n.isRead).length,
        ));
      }
    });
  }
}
