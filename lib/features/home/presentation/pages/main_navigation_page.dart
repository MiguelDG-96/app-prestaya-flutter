import 'package:flutter/material.dart';
import 'package:app_prestaya_flutter/core/theme/app_theme.dart';
import 'home_page.dart';
import 'package:app_prestaya_flutter/features/clients/presentation/pages/clients_page.dart';
import 'package:app_prestaya_flutter/features/loans/presentation/pages/loans_page.dart';
import 'package:app_prestaya_flutter/features/rentals/presentation/pages/rentals_page.dart';

import 'package:app_prestaya_flutter/core/widgets/register_options_sheet.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_prestaya_flutter/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:app_prestaya_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:app_prestaya_flutter/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:app_prestaya_flutter/core/services/firebase_service.dart';
import 'package:app_prestaya_flutter/injection_container.dart';
import 'package:app_prestaya_flutter/core/utils/permission_helper.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Cargar notificaciones al iniciar si ya está autenticado
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<NotificationsBloc>().add(LoadNotificationsRequested(authState.user.email));
      _updatePushToken();
    }
  }

  List<_NavItemData> _getNavItems() {
    final List<_NavItemData> items = [
      _NavItemData(index: 0, icon: Icons.home_filled, label: 'Inicio', page: HomePage(onNavigateToLoans: () => _onTabChangeBySubpage(2))),
    ];

    if (PermissionHelper.hasPermission(context, AppPermissions.clientesView)) {
      items.add(_NavItemData(index: 1, icon: Icons.people_alt_outlined, label: 'Clientes', page: const ClientsPage()));
    }

    if (PermissionHelper.hasPermission(context, AppPermissions.prestamosView)) {
      items.add(_NavItemData(index: 2, icon: Icons.payments_outlined, label: 'Préstamos', page: const LoansPage()));
    }

    if (PermissionHelper.hasPermission(context, AppPermissions.alquileresView)) {
      items.add(_NavItemData(index: 3, icon: Icons.apartment_outlined, label: 'Alquiler', page: const RentalsPage()));
    }

    return items;
  }

  void _onTabChangeBySubpage(int index) {
    // Buscar el índice real en la lista filtrada
    final items = _getNavItems();
    final realIndex = items.indexWhere((item) => item.index == index);
    if (realIndex != -1) {
      setState(() => _currentIndex = realIndex);
    }
  }

  Future<void> _updatePushToken() async {
    try {
      final token = await FirebaseService.getToken();
      if (token != null) {
        await sl<AuthRemoteDataSource>().updatePushToken(token);
      }
    } catch (e) {
      debugPrint('Error sincronizando Push Token: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final navItems = _getNavItems();
    final size = MediaQuery.of(context).size;
    
    // Asegurar que el índice no esté fuera de rango después de un cambio de permisos
    if (_currentIndex >= navItems.length) {
      _currentIndex = 0;
    }

    final itemWidth = size.width / (navItems.length + 1);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: navItems.map((item) => item.page).toList(),
      ),
      bottomNavigationBar: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Círculo Animado Premium
            AnimatedPositioned(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutBack,
              left: _calculateCirclePosition(itemWidth, navItems.length),
              top: 10,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
            // Iconos
            Row(
              children: _buildNavWidgets(navItems),
            ),
          ],
        ),
      ),
      floatingActionButton: _shouldShowFAB() ? FloatingActionButton(
        onPressed: () => RegisterOptionsSheet.show(
          context,
          onTabChange: (index) => _onTabChangeBySubpage(index),
        ),
        backgroundColor: AppTheme.primary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  bool _shouldShowFAB() {
    return PermissionHelper.hasPermission(context, AppPermissions.clientesCreate) ||
           PermissionHelper.hasPermission(context, AppPermissions.prestamosCreate) ||
           PermissionHelper.hasPermission(context, AppPermissions.alquileresCreate);
  }

  List<Widget> _buildNavWidgets(List<_NavItemData> navItems) {
    List<Widget> widgets = [];
    final centerIndex = (navItems.length / 2).floor();
    
    for (int i = 0; i < navItems.length; i++) {
      if (i == centerIndex) {
        widgets.add(const Expanded(child: SizedBox())); // Espacio para el FAB
      }
      widgets.add(_buildNavItem(i, navItems[i].icon, navItems[i].label));
    }
    
    // Si la lista es par, el espacio del FAB podría quedar al final, aseguramos que esté cerca del centro
    if (navItems.length % 2 == 0 && centerIndex == navItems.length) {
       // Esto no debería pasar con 1, 2, 3 o 4 tabs + FAB, pero por si acaso
    }

    return widgets;
  }

  double _calculateCirclePosition(double itemWidth, int itemsCount) {
    final centerIndex = (itemsCount / 2).floor();
    double multiplier = _currentIndex.toDouble();
    if (_currentIndex >= centerIndex) multiplier += 1;
    return (multiplier * itemWidth) + (itemWidth / 2) - 25;
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              size: isSelected ? 28 : 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItemData {
  final int index;
  final IconData icon;
  final String label;
  final Widget page;

  _NavItemData({
    required this.index,
    required this.icon,
    required this.label,
    required this.page,
  });
}
