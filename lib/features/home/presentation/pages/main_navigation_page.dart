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

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(onNavigateToLoans: () => setState(() => _currentIndex = 2)),
      const ClientsPage(),
      const LoansPage(),
      const RentalsPage(),
    ];

    // Cargar notificaciones al iniciar si ya está autenticado
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<NotificationsBloc>().add(LoadNotificationsRequested(authState.user.email));
      _updatePushToken();
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
    final size = MediaQuery.of(context).size;
    final itemWidth = size.width / 5;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
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
              left: _calculateCirclePosition(itemWidth),
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
              children: [
                _buildNavItem(0, Icons.home_filled, 'Inicio'),
                _buildNavItem(1, Icons.people_alt_outlined, 'Clientes'),
                SizedBox(width: itemWidth), // Espacio FAB
                _buildNavItem(2, Icons.payments_outlined, 'Préstamos'),
                _buildNavItem(3, Icons.apartment_outlined, 'Alquiler'),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => RegisterOptionsSheet.show(
          context,
          onTabChange: (index) => setState(() => _currentIndex = index),
        ),
        backgroundColor: AppTheme.primary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  double _calculateCirclePosition(double itemWidth) {
    double indexToMultiply = _currentIndex.toDouble();
    if (_currentIndex >= 2) indexToMultiply += 1;
    return (indexToMultiply * itemWidth) + (itemWidth / 2) - 25;
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
