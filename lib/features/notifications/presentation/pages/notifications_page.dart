import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app_prestaya_flutter/core/theme/app_theme.dart';
import 'package:app_prestaya_flutter/features/notifications/domain/entities/notification_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_prestaya_flutter/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:app_prestaya_flutter/features/auth/presentation/bloc/auth_bloc.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  static Route route() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const NotificationsPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutQuart;
        var borderCurve = CurveTween(curve: curve);
        var offsetAnimation = animation.drive(Tween(begin: begin, end: end).chain(borderCurve));
        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<NotificationsBloc, NotificationsState>(
        builder: (context, state) {
          if (state is NotificationsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is NotificationsLoaded) {
            return Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      final authState = context.read<AuthBloc>().state;
                      if (authState is Authenticated) {
                        context.read<NotificationsBloc>().add(LoadNotificationsRequested(authState.user.email));
                      }
                    },
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recientes',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.text),
                            ),
                            if (state.unreadCount > 0)
                              TextButton(
                                onPressed: () {
                                  final authState = context.read<AuthBloc>().state;
                                  if (authState is Authenticated) {
                                    context.read<NotificationsBloc>().add(MarkAllAsReadRequested(authState.user.email));
                                  }
                                },
                                child: const Text(
                                  'Marcar todo como leído',
                                  style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        if (state.notifications.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 100),
                              child: Text('No tienes notificaciones', style: TextStyle(color: AppTheme.textSecondary)),
                            ),
                          ),
                        ...state.notifications.map((n) => _buildNotificationCard(n as NotificationEntity)),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          
          return const Center(child: Text('Error al cargar notificaciones'));
        },
      ),
    );
  }

  Widget _buildHeader() {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding + 10, 20, 25),
      decoration: const BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(35)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
            ),
          ),
          const Expanded(
            child: Text(
              'Notificaciones',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(width: 42),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationEntity notification) {
    final bool isUserType = notification.type == NotificationType.newClient;
    
    return GestureDetector(
      onTap: () {
        if (!notification.isRead) {
          context.read<NotificationsBloc>().add(MarkAsReadRequested(notification.id));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: IntrinsicHeight(
            child: Row(
              children: [
                if (!notification.isRead)
                  Container(
                    width: 4,
                    color: AppTheme.primary,
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isUserType ? const Color(0xFFE8F5E9) : const Color(0xFFF3F2FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isUserType ? Icons.person_add_alt_1 : Icons.notifications_none,
                            color: isUserType ? const Color(0xFF2E7D32) : AppTheme.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    notification.title,
                                    style: TextStyle(
                                      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold, 
                                      fontSize: 16,
                                      color: notification.isRead ? AppTheme.textSecondary : AppTheme.text,
                                    ),
                                  ),
                                  Text(
                                    _formatTimestamp(notification.timestamp),
                                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                notification.content,
                                style: TextStyle(
                                  color: notification.isRead ? AppTheme.textSecondary.withOpacity(0.7) : AppTheme.textSecondary, 
                                  fontSize: 13, 
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'Ahora mismo';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} horas';
    return DateFormat('d MMM').format(dt);
  }
}
