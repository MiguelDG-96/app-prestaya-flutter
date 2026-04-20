import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_prestaya_flutter/core/theme/app_theme.dart';
import 'package:app_prestaya_flutter/features/loans/presentation/bloc/loans_bloc.dart';
import 'package:app_prestaya_flutter/features/loans/domain/entities/loan_entity.dart';
import 'package:app_prestaya_flutter/features/loans/presentation/pages/register_payment_page.dart';
import 'package:app_prestaya_flutter/features/loans/presentation/pages/payment_history_page.dart';
import 'package:app_prestaya_flutter/features/loans/presentation/pages/loan_detail_page.dart';
import 'package:intl/intl.dart';

class LoansPage extends StatefulWidget {
  const LoansPage({super.key});

  @override
  State<LoansPage> createState() => _LoansPageState();
}

class _LoansPageState extends State<LoansPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isDescending = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    context.read<LoansBloc>().add(LoadLoansRequested());
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
            child: BlocBuilder<LoansBloc, LoansState>(
              builder: (context, state) {
                if (state is LoansLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is LoansLoaded) {
                  final filteredLoans = state.loans.where((loan) {
                    final name = loan.clientName?.toLowerCase() ?? '';
                    return name.contains(_searchQuery);
                  }).toList();

                  // Ordenar por fecha de vencimiento o registro
                  filteredLoans.sort((a, b) {
                    if (_isDescending) {
                      return b.dueDate.compareTo(a.dueDate);
                    } else {
                      return a.dueDate.compareTo(b.dueDate);
                    }
                  });

                  if (filteredLoans.isEmpty) return _buildEmptyState();
                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: filteredLoans.length,
                    itemBuilder: (context, index) => _buildLoanCard(filteredLoans[index]),
                  );
                } else if (state is LoansError) {
                  return Center(child: Text(state.message));
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
            'Préstamos',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
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
                      const Icon(Icons.search, color: AppTheme.textSecondary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoanCard(LoanEntity loan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoanDetailPage(loan: loan)),
        ),
        borderRadius: BorderRadius.circular(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        loan.clientName ?? 'Cliente',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.text),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => PaymentHistoryPage(loan: loan)),
                            ),
                            child: _buildActionIcon(Icons.access_time, const Color(0xFF6366F1).withOpacity(0.1), const Color(0xFF6366F1)),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => RegisterPaymentPage(loan: loan)),
                            ),
                            child: _buildActionIcon(Icons.payments_outlined, const Color(0xFF10B981).withOpacity(0.1), const Color(0xFF10B981)),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              if ((loan.paidAmount ?? 0) > 0 || (loan.currentInstallment ?? 0) > 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No se puede eliminar un préstamo con pagos registrados.'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              _showDeleteConfirmation(context, loan);
                            },
                            child: _buildActionIcon(Icons.delete_outline, const Color(0xFFEF4444).withOpacity(0.1), const Color(0xFFEF4444)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.layers_outlined, size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Cuota: ${loan.currentInstallment ?? 0} / ${loan.installments}',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'EN CURSO',
                      style: TextStyle(color: Color(0xFFC2410C), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryItem('Monto', 'S/ ${loan.amount.toStringAsFixed(0)}'),
                  _buildSummaryItem('Interés', '${loan.interest.toStringAsFixed(0)}%'),
                  _buildSummaryItem('Pagado', 'S/ ${(loan.paidAmount ?? 0).toStringAsFixed(2)}', valueColor: const Color(0xFF10B981)),
                  _buildSummaryItem(
                    'Total', 
                    'S/ ${(loan.totalToPay ?? (loan.amount + (loan.amount * (loan.interest / 100)))).toStringAsFixed(0)}', 
                    valueColor: const Color(0xFF6366F1)
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 20),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_outlined, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    'Vence: ${DateFormat('dd/MM/yyyy').format(loan.dueDate)}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
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
            fontSize: 15,
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
          Icon(Icons.receipt_long_outlined, size: 80, color: AppTheme.border),
          SizedBox(height: 15),
          Text('No hay préstamos registrados', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
        ],
      ),
    );
  }
  void _showDeleteConfirmation(BuildContext context, LoanEntity loan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar Préstamo?'),
        content: Text('¿Estás seguro de que deseas eliminar el préstamo de ${loan.clientName}? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              context.read<LoansBloc>().add(DeleteLoanRequested(loan.id!));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Préstamo eliminado correctamente.')),
              );
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
