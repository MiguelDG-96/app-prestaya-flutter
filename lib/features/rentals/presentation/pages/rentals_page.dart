import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_prestaya_flutter/core/theme/app_theme.dart';
import 'package:app_prestaya_flutter/features/rentals/presentation/bloc/rentals_bloc.dart';
import 'package:app_prestaya_flutter/features/rentals/presentation/bloc/rentals_event.dart';
import 'package:app_prestaya_flutter/features/rentals/presentation/bloc/rentals_state.dart';
import 'package:app_prestaya_flutter/features/rentals/domain/entities/rental_entity.dart';
import 'add_rental_payment_page.dart';
import 'rental_payment_history_page.dart';
import 'rental_detail_page.dart';
import 'package:app_prestaya_flutter/injection_container.dart';
import 'package:intl/intl.dart';

class RentalsPage extends StatefulWidget {
  const RentalsPage({super.key});

  @override
  State<RentalsPage> createState() => _RentalsPageState();
}

class _RentalsPageState extends State<RentalsPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isDescending = true; // true: Nuevos primero, false: Antiguos primero
  String _searchQuery = '';
  int? _selectedDay; // 1: Lunes, ..., 7: Domingo

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RentalsBloc>().add(GetRentalsRequested());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: BlocBuilder<RentalsBloc, RentalsState>(
                builder: (context, state) {
                  if (state is RentalsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is RentalsLoaded) {
                    final filteredRentals = state.rentals.where((rental) {
                      final name = rental.tenant?.name.toLowerCase() ?? '';
                      final matchesSearch = name.contains(_searchQuery);

                      if (!matchesSearch) return false;

                      if (_selectedDay != null && rental.dueDate != null) {
                        return rental.dueDate!.weekday == _selectedDay;
                      }

                      return true;
                    }).toList();

                    // Ordenar por fecha (ID usualmente incremental o fecha de inicio)
                    filteredRentals.sort((a, b) {
                      if (_isDescending) {
                        return b.startDate.compareTo(a.startDate);
                      } else {
                        return a.startDate.compareTo(b.startDate);
                      }
                    });

                    if (filteredRentals.isEmpty) return _buildEmptyState();
                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: filteredRentals.length,
                      itemBuilder: (context, index) => _buildRentalCard(filteredRentals[index]),
                    );
                  } else if (state is RentalsError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 60),
                            const SizedBox(height: 16),
                            Text(state.message, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => context.read<RentalsBloc>().add(GetRentalsRequested()),
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 25),
      decoration: const BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alquileres',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const Text(
            'Gestión de cuartos e inquilinos',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 20),
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
                      Icon(Icons.search, color: AppTheme.textSecondary, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Buscar por nombre...',
                            hintStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => context.read<RentalsBloc>().add(GetRentalsRequested()),
                child: BlocBuilder<RentalsBloc, RentalsState>(
                  builder: (context, state) {
                    return Container(
                      height: 45,
                      width: 45,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: state is RentalsLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.refresh, color: Colors.white, size: 20),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isDescending = !_isDescending;
                  });
                },
                child: Container(
                  height: 45,
                  width: 45,
                  decoration: BoxDecoration(
                    color: _isDescending ? Colors.white : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isDescending ? Icons.arrow_downward : Icons.arrow_upward, 
                    color: _isDescending ? AppTheme.primary : Colors.white, 
                    size: 20
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  _showDayFilter(context);
                },
                child: Container(
                  height: 45,
                  width: 45,
                  decoration: BoxDecoration(
                    color: _selectedDay != null ? Colors.white : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.filter_list, 
                    color: _selectedDay != null ? AppTheme.primary : Colors.white, 
                    size: 20
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDayFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final days = [
          {'name': 'Todos los días', 'value': null},
          {'name': 'Lunes', 'value': 1},
          {'name': 'Martes', 'value': 2},
          {'name': 'Miércoles', 'value': 3},
          {'name': 'Jueves', 'value': 4},
          {'name': 'Viernes', 'value': 5},
          {'name': 'Sábado', 'value': 6},
          {'name': 'Domingo', 'value': 7},
        ];

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 20),
            children: [
              const Center(
                child: Text('Filtrar por día de cobro', 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                ),
              ),
              const SizedBox(height: 15),
              ...days.map((day) => ListTile(
                title: Text(day['name'] as String, style: TextStyle(
                  fontWeight: _selectedDay == day['value'] ? FontWeight.bold : FontWeight.normal,
                  color: _selectedDay == day['value'] ? AppTheme.primary : AppTheme.text,
                )),
                trailing: _selectedDay == day['value'] ? const Icon(Icons.check, color: AppTheme.primary) : null,
                onTap: () {
                  setState(() {
                    _selectedDay = day['value'] as int?;
                  });
                  Navigator.pop(context);
                },
              )).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRentalCard(RentalEntity rental) {
    final now = DateTime.now();
    final isDueToday = rental.dueDate != null && 
                       rental.dueDate!.year == now.year && 
                       rental.dueDate!.month == now.month && 
                       rental.dueDate!.day == now.day;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: isDueToday ? Border.all(color: AppTheme.primary, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: isDueToday ? AppTheme.primary.withOpacity(0.1) : Colors.black.withOpacity(0.04), 
            blurRadius: 15, 
            offset: const Offset(0, 8)
          ),
        ],
      ),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RentalDetailPage(rental: rental)),
          );
          if (context.mounted) {
            context.read<RentalsBloc>().add(GetRentalsRequested());
          }
        },
        borderRadius: BorderRadius.circular(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rental.tenant?.name ?? 'Inquilino',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cuarto ${rental.roomNumber}',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (isDueToday)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '🔥 COBRAR HOY',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'PENDIENTE',
                                style: TextStyle(
                                  color: Color(0xFFC2410C),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${rental.paidMonths}/${rental.totalMonths} Meses',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RentalPaymentHistoryPage(rental: rental),
                        ),
                      ),
                      child: _buildActionIcon(
                        Icons.access_time,
                        const Color(0xFF6366F1).withOpacity(0.1),
                        const Color(0xFF6366F1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddRentalPaymentPage(rental: rental),
                          ),
                        );
                        if (result == true) {
                          context.read<RentalsBloc>().add(GetRentalsRequested());
                        }
                      },
                      child: _buildActionIcon(
                        Icons.payments_outlined,
                        const Color(0xFF10B981).withOpacity(0.1),
                        const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Pagado',
                  'S/ ${rental.amountPaid.toStringAsFixed(0)}',
                  valueColor: const Color(0xFF10B981),
                ),
                _buildSummaryItem(
                  'Alquiler',
                  'S/ ${rental.amount.toStringAsFixed(0)}',
                  valueColor: const Color(0xFF6366F1),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 20),
            child: Row(
              children: [
                Icon(Icons.calendar_month_outlined, size: 16, color: isDueToday ? AppTheme.primary : AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'Vence: ${rental.dueDate != null ? DateFormat('d/M/yyyy').format(rental.dueDate!) : 'N/A'}',
                  style: TextStyle(
                    color: isDueToday ? AppTheme.primary : AppTheme.textSecondary, 
                    fontSize: 13,
                    fontWeight: isDueToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildActionIcon(IconData icon, Color bgColor, Color iconColor) {
    return Container(
      height: 38,
      width: 38,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: iconColor, size: 20),
    );
  }

  Widget _buildSummaryItem(String label, String value, {Color? valueColor}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppTheme.text,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.home_work_outlined, size: 80, color: AppTheme.border),
          SizedBox(height: 15),
          Text(
            'No hay alquileres registrados',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
