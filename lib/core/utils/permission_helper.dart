import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_prestaya_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:app_prestaya_flutter/features/auth/domain/entities/user_entity.dart';

class PermissionHelper {
  /// Verifica si el usuario tiene un permiso específico
  static bool hasPermission(BuildContext context, String permission) {
    final state = context.read<AuthBloc>().state;
    if (state is AuthAuthenticated) {
      return _check(state.user, permission);
    }
    return false;
  }

  /// Verifica si el usuario tiene el rol SUPER_ADMIN o ADMIN
  static bool isAdmin(BuildContext context) {
    final state = context.read<AuthBloc>().state;
    if (state is AuthAuthenticated) {
      return state.user.role == 'SUPER_ADMIN' || state.user.role == 'ADMIN';
    }
    return false;
  }

  static bool _check(UserEntity user, String permission) {
    // Si es SUPER_ADMIN tiene todos los permisos
    if (user.role == 'SUPER_ADMIN') return true;
    
    // Verificar si el permiso está en la lista
    return user.permissions.contains(permission);
  }

  /// Widget que solo se muestra si el usuario tiene el permiso
  static Widget guarded({
    required BuildContext context,
    required String permission,
    required Widget child,
    Widget fallback = const SizedBox.shrink(),
  }) {
    return hasPermission(context, permission) ? child : fallback;
  }
}

// Constantes de permisos para evitar errores de dedo
class AppPermissions {
  // Módulo Clientes
  static const String clientesView = 'CLIENTES_VIEW';
  static const String clientesCreate = 'CLIENTES_CREATE';
  static const String clientesUpdate = 'CLIENTES_UPDATE';
  static const String clientesDelete = 'CLIENTES_DELETE';

  // Módulo Préstamos
  static const String prestamosView = 'PRESTAMOS_VIEW';
  static const String prestamosCreate = 'PRESTAMOS_CREATE';
  static const String prestamosUpdate = 'PRESTAMOS_UPDATE';
  static const String prestamosDelete = 'PRESTAMOS_DELETE';

  // Módulo Alquileres
  static const String alquileresView = 'ALQUILERES_VIEW';
  static const String alquileresCreate = 'ALQUILERES_CREATE';
  static const String alquileresUpdate = 'ALQUILERES_UPDATE';
  static const String alquileresDelete = 'ALQUILERES_DELETE';

  // Módulo Estadísticas
  static const String statsView = 'STATS_VIEW';
}
