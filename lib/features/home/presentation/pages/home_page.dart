import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_prestaya_flutter/core/theme/app_theme.dart';
import 'package:app_prestaya_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:app_prestaya_flutter/features/auth/domain/entities/user_entity.dart';
import 'package:app_prestaya_flutter/features/profile/presentation/pages/profile_page.dart';
import 'package:app_prestaya_flutter/features/loans/presentation/bloc/loans_bloc.dart';
import 'package:app_prestaya_flutter/features/loans/presentation/pages/loan_detail_page.dart';
import 'package:app_prestaya_flutter/features/rentals/presentation/bloc/rentals_bloc.dart';
import 'package:app_prestaya_flutter/features/rentals/presentation/bloc/rentals_event.dart';
import 'package:app_prestaya_flutter/features/rentals/presentation/bloc/rentals_state.dart';
import 'package:app_prestaya_flutter/features/rentals/presentation/pages/add_rental_payment_page.dart';
import 'package:app_prestaya_flutter/features/rentals/presentation/pages/rental_detail_page.dart';
import 'package:app_prestaya_flutter/features/notifications/presentation/pages/notifications_page.dart';
import 'package:app_prestaya_flutter/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:app_prestaya_flutter/features/stats/presentation/pages/stats_page.dart';
import 'package:app_prestaya_flutter/features/stats/presentation/bloc/stats_bloc.dart';
import 'package:app_prestaya_flutter/core/services/firebase_service.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? onNavigateToLoans;
  const HomePage({super.key, this.onNavigateToLoans});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 0;
  String _searchQuery = '';
  bool _notificationSent = false;

  @override
  void initState() {
    super.initState();
    context.read<LoansBloc>().add(LoadLoansRequested());
    context.read<RentalsBloc>().add(GetRentalsRequested());
    context.read<StatsBloc>().add(LoadStatsRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToTab(int index) {
    if (index == 2 && widget.onNavigateToLoans != null) {
      widget.onNavigateToLoans!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: MultiBlocListener(
        listeners: [
          BlocListener<LoansBloc, LoansState>(
            listener: (context, state) {
              if (state is LoansLoaded && !_notificationSent) {
                final now = DateTime.now();
                final dueToday = state.loans.where((loan) => 
                  loan.dueDate.year == now.year && 
                  loan.dueDate.month == now.month && 
                  loan.dueDate.day == now.day
                ).toList();

                if (dueToday.isNotEmpty) {
                  _notificationSent = true;
                  final names = dueToday.map((l) => l.clientName).take(2).join(", ");
                  final more = dueToday.length > 2 ? " y ${dueToday.length - 2} más" : "";
                  
                  FirebaseService.showInstantNotification(
                    title: "📅 ¡Cobros de Préstamos!",
                    body: "Hoy vence el pago de: $names$more.",
                    payload: "CLIENT:${dueToday.first.clientId}",
                  );
                }
              }
            },
          ),
          BlocListener<RentalsBloc, RentalsState>(
            listener: (context, state) {
              if (state is RentalsLoaded && !_notificationSent) {
                final now = DateTime.now();
                final dueToday = state.rentals.where((rental) => 
                  rental.dueDate != null &&
                  rental.dueDate!.year == now.year && 
                  rental.dueDate!.month == now.month && 
                  rental.dueDate!.day == now.day
                ).toList();

                if (dueToday.isNotEmpty) {
                  _notificationSent = true;
                  final names = dueToday.map((r) => r.tenant?.name ?? 'Inquilino').take(2).join(", ");
                  final more = dueToday.length > 2 ? " y ${dueToday.length - 2} más" : "";
                  
                  FirebaseService.showInstantNotification(
                    title: "🏠 ¡Cobros de Alquiler!",
                    body: "Hoy toca cobrar a: $names$more.",
                    payload: "RENTAL:${dueToday.first.id}",
                  );
                }
              }
            },
          ),
        ],
        child: Stack(
          children: [
            BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final user = (state is Authenticated) ? state.user : null;
              
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, user),
                    const SizedBox(height: 25),
                    _buildSectionTitle(
                      'Resumen General',
                      showSeeAll: true,
                      onSeeAll: () => _navigateToTab(2),
                    ),
                    BlocBuilder<StatsBloc, StatsState>(
                      builder: (context, state) {
                        if (state is StatsLoaded) {
                          return _buildSummaryCarousel(state);
                        }
                        return _buildSummaryCarousel(null);
                      },
                    ),
                    _buildPageIndicator(),
                    const SizedBox(height: 20),
                    _buildSectionTitle(
                      'Estadísticas de Cobro',
                    ),
                    BlocBuilder<StatsBloc, StatsState>(
                      builder: (context, state) {
                        if (state is StatsLoaded) {
                          return _buildLoanStats(state);
                        }
                        return _buildLoanStats(null);
                      },
                    ),
                    const SizedBox(height: 25),
                    _buildSectionTitle(
                      'Tus Préstamos Recientes',
                      showSeeAll: true,
                      onSeeAll: () => _navigateToTab(2),
                    ),
                    _buildPortfolioStatus(),
                    const SizedBox(height: 25),
                    _buildStatsBanner(),
                    const SizedBox(height: 100), // Espacio para el BottomBar
                  ],
                ),
              );
            },
          ),
          if (_searchQuery.isNotEmpty) _buildSearchOverlay(),
        ],
      ),
    ),
    );
  }

  Widget _buildHeader(BuildContext context, UserEntity? user) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: topPadding + 10, left: 20, right: 20, bottom: 30),
      decoration: const BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('¡Bienvenido de nuevo! 👋', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    user?.name.split(' ').first ?? 'Usuario', 
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
                  ),
                ],
              ),
              Row(
                children: [
                  BlocBuilder<NotificationsBloc, NotificationsState>(
                    builder: (context, state) {
                      String? badge;
                      if (state is NotificationsLoaded && state.unreadCount > 0) {
                        badge = state.unreadCount.toString();
                      }
                      return _buildHeaderIconButton(
                        Icons.notifications_none_outlined, 
                        badge: badge,
                        onTap: () => Navigator.push(context, NotificationsPage.route()),
                      );
                    },
                  ),
                  const SizedBox(width: 15),
                  _buildHeaderAvatar(context, user),
                ],
              ),
            ],
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: AppTheme.textSecondary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Buscar un préstamo o cliente',
                            hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            suffixIcon: _searchQuery.isNotEmpty 
                              ? GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                  child: const Icon(Icons.cancel, color: AppTheme.textSecondary, size: 20),
                                )
                              : null,
                            suffixIconConstraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                height: 45,
                width: 45,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.tune_outlined, color: Colors.white, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIconButton(IconData icon, {String? badge, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
      children: [
        Container(
          height: 45,
          width: 45,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        if (badge != null)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Color(0xFFFF4B4B), shape: BoxShape.circle),
              child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    ),
  );
}

  Widget _buildHeaderAvatar(BuildContext context, UserEntity? user) {
    final photoUrl = user?.photoUrl;
    final String? fullPhotoUrl = (photoUrl != null && photoUrl.isNotEmpty)
        ? (photoUrl.startsWith('http') ? photoUrl : 'https://servicio.teamrecios.com$photoUrl')
        : null;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfilePage()),
      ),
      child: Stack(
        children: [
          Container(
            height: 65, // Aumentado para mejor visibilidad
            width: 65,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.4), width: 3),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4)),
              ],
              image: fullPhotoUrl != null 
                  ? DecorationImage(image: NetworkImage(fullPhotoUrl), fit: BoxFit.cover)
                  : const DecorationImage(image: AssetImage('assets/images/dev/developer.jpg'), fit: BoxFit.cover),
            ),
            child: (fullPhotoUrl == null && user == null)
                ? Center(
                    child: Text(
                      user?.name.substring(0, 1).toUpperCase() ?? 'U', 
                      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 24)
                    ),
                  )
                : null,
          ),
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              height: 14,
              width: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF2ECC71),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primary, width: 2.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool showSeeAll = false, VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.text)),
          if (showSeeAll)
            GestureDetector(
              onTap: onSeeAll,
              child: const Text('Ver todo', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCarousel(StatsLoaded? stats) {
    final overall = stats?.overall;
    final daily = stats?.daily;

    final summaries = [
      _SummaryData(
        title: 'Cartera Total',
        subtitle: 'Por cobrar',
        amount: 'S/ ${overall?['total_portfolio']?.toStringAsFixed(0) ?? '0'}',
        footer: 'Capital + Interés',
        color: AppTheme.primary,
        icon: Icons.account_balance_wallet_outlined,
        tags: ['Activo', 'Total'],
      ),
      _SummaryData(
        title: 'Cobros Hoy',
        subtitle: 'Planificado',
        amount: 'S/ ${daily?['today']?.toStringAsFixed(0) ?? '0'}',
        footer: 'Crecimiento: ${daily?['growth']?.toStringAsFixed(1) ?? '0'}%',
        color: const Color(0xFFFF8C00),
        icon: Icons.calendar_today_outlined,
        tags: ['Prioridad', 'Diario'],
      ),
      _SummaryData(
        title: 'Ganancia Real',
        subtitle: 'Cobrada',
        amount: 'S/ ${overall?['total_collected']?.toStringAsFixed(0) ?? '0'}',
        footer: 'Efectivo en caja',
        color: const Color(0xFF27AE60),
        icon: Icons.trending_up_outlined,
        tags: ['Efectivo', 'Real'],
      ),
      _SummaryData(
        title: 'Pendiente',
        subtitle: 'Por recuperar',
        amount: 'S/ ${overall?['total_pending']?.toStringAsFixed(0) ?? '0'}',
        footer: 'Saldo restante',
        color: const Color(0xFFFF2D55),
        icon: Icons.auto_graph_outlined,
        tags: ['Riesgo', 'Meta'],
      ),
    ];

    return SizedBox(
      height: 210,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentPage = index),
        itemCount: summaries.length,
        itemBuilder: (context, index) {
          final data = summaries[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: data.color,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(color: data.color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Icon(data.icon, color: data.color, size: 24),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(data.subtitle, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.bookmark_border, color: Colors.white, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: data.tags.map((tag) => Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(tag, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  )).toList(),
                ),
                const SizedBox(height: 12),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(data.amount, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    Text(data.footer, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            width: _currentPage == index ? 24 : 8,
            decoration: BoxDecoration(
              color: _currentPage == index ? AppTheme.primary : AppTheme.border,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLoanStats(StatsLoaded? stats) {
    final daily = stats?.daily;
    final monthly = stats?.monthly;
    
    double monthTotal = 0;
    if (monthly != null && monthly.isNotEmpty) {
      // Obtener el índice del mes actual (1-12)
      final int currentMonth = DateTime.now().month;
      // Buscamos el mes en la lista (algunos APIs devuelven 0-11, otros 1-12)
      // En nuestro backend es 1-12, pero en la lista de Flutter el índice es 0-11
      if (currentMonth <= monthly.length) {
        monthTotal = (monthly[currentMonth - 1]['paid'] ?? 0.0).toDouble();
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          _buildStatCard('Hoy', 'S/ ${daily?['today']?.toStringAsFixed(0) ?? '0'}', const Color(0xFF27AE60), Icons.calendar_today),
          const SizedBox(width: 15),
          _buildStatCard('Acum. Mes', 'S/ ${monthTotal.toStringAsFixed(0)}', AppTheme.primary, Icons.calendar_month),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioStatus() {
    return BlocBuilder<LoansBloc, LoansState>(
      builder: (context, state) {
        if (state is LoansLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is LoansLoaded) {
          final recentLoans = state.loans.take(3).toList();
          
          if (recentLoans.isEmpty) {
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 15),
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Icon(Icons.payments_outlined, size: 50, color: AppTheme.primary.withOpacity(0.2)),
                  const SizedBox(height: 15),
                  const Text('No tienes préstamos activos', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                ],
              ),
            );
          }

          return Column(
            children: recentLoans.map((loan) => _buildLoanCard(loan)).toList(),
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildLoanCard(dynamic loan) {
    String translateFrequency(String? freq) {
      switch (freq?.toUpperCase()) {
        case 'DAILY': return 'Diario';
        case 'WEEKLY': return 'Semanal';
        case 'BIWEEKLY': return 'Quincenal';
        case 'MONTHLY': return 'Mensual';
        default: return freq ?? 'No definida';
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.person_outline, color: AppTheme.primary, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loan.clientName ?? 'Cliente',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Frecuencia: ${translateFrequency(loan.frequency)}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'S/ ${loan.amount.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Activo',
                  style: TextStyle(color: Color(0xFF2E7D32), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBanner() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsPage())),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(15)),
              child: const Icon(Icons.analytics_outlined, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reportes y Análisis',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Visualiza el crecimiento de tu cartera y el estado detallado de tus cobros.',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
  Widget _buildSearchOverlay() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 180, // Bajado para no tapar el buscador ni el header curvo
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<LoansBloc>()),
            BlocProvider.value(value: context.read<RentalsBloc>()),
          ],
          child: Builder(
            builder: (context) {
              return BlocBuilder<LoansBloc, LoansState>(
                builder: (context, loanState) {
                  return BlocBuilder<RentalsBloc, RentalsState>(
                    builder: (context, rentalState) {
                      final filteredLoans = (loanState is LoansLoaded)
                          ? loanState.loans.where((l) => l.clientName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false).toList()
                          : [];
                      
                      final filteredRentals = (rentalState is RentalsLoaded)
                          ? rentalState.rentals.where((r) => r.tenant?.name.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false).toList()
                          : [];

                      if (filteredLoans.isEmpty && filteredRentals.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off_outlined, size: 80, color: AppTheme.border),
                              const SizedBox(height: 15),
                              Text('No se encontraron resultados para "$_searchQuery"', style: const TextStyle(color: AppTheme.textSecondary)),
                            ],
                          ),
                        );
                      }

                      return ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        children: [
                          if (filteredLoans.isNotEmpty) ...[
                            _buildOverlaySectionTitle('PRÉSTAMOS'),
                            ...filteredLoans.map((loan) => _buildLoanResultItem(loan)),
                            const SizedBox(height: 20),
                          ],
                          if (filteredRentals.isNotEmpty) ...[
                            _buildOverlaySectionTitle('ALQUILERES'),
                            ...filteredRentals.map((rental) => _buildRentalResultItem(rental)),
                            const SizedBox(height: 100),
                          ],
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOverlaySectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF818CF8), letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildLoanResultItem(dynamic loan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.payments_outlined, color: Color(0xFF10B981), size: 22),
        ),
        title: Text(loan.clientName ?? 'Cliente', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text('Monto: S/ ${loan.amount.toStringAsFixed(0)} • Cuotas: ${loan.currentInstallment}/${loan.installments}', 
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.border),
        onTap: () {
          _searchController.clear();
          setState(() => _searchQuery = '');
          Navigator.push(context, MaterialPageRoute(builder: (_) => LoanDetailPage(loan: loan)));
        },
      ),
    );
  }

  Widget _buildRentalResultItem(dynamic rental) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.home_outlined, color: Color(0xFFF59E0B), size: 22),
        ),
        title: Text(rental.tenant?.name ?? 'Inquilino', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text('Cuarto: ${rental.roomNumber} • Alquiler: S/ ${rental.amount.toStringAsFixed(0)}', 
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.border),
        onTap: () {
          _searchController.clear();
          setState(() => _searchQuery = '');
          Navigator.push(context, MaterialPageRoute(builder: (_) => RentalDetailPage(rental: rental)));
        },
      ),
    );
  }
}

class _SummaryData {
  final String title;
  final String subtitle;
  final String amount;
  final String footer;
  final Color color;
  final IconData icon;
  final List<String> tags;

  _SummaryData({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.footer,
    required this.color,
    required this.icon,
    required this.tags,
  });
}
