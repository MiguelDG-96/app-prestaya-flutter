import 'package:flutter/material.dart';
import 'package:app_prestaya_flutter/core/theme/app_theme.dart';
import 'package:app_prestaya_flutter/features/rentals/domain/entities/rental_entity.dart';
import 'package:intl/intl.dart';
import 'package:app_prestaya_flutter/features/rentals/presentation/bloc/rentals_bloc.dart';
import 'package:app_prestaya_flutter/features/rentals/presentation/bloc/rentals_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'add_rental_payment_page.dart';
import 'rental_payment_history_page.dart';
import 'add_rental_page.dart';

class RentalDetailPage extends StatelessWidget {
  final RentalEntity rental;

  const RentalDetailPage({super.key, required this.rental});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMainCard(),
                  const SizedBox(height: 25),
                  const Text(
                    'DETALLES DEL CONTRATO',
                    style: TextStyle(
                      fontSize: 14, 
                      fontWeight: FontWeight.bold, 
                      color: AppTheme.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildContractDetailsCard(),
                  const SizedBox(height: 30),
                  _buildActionButtons(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding + 10, 20, 25),
      decoration: const BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(35)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'Detalle del Alquiler',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit_note, color: Colors.white),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddRentalPage(rental: rental)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  onPressed: () => _showDeleteConfirmation(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    if (rental.paidMonths > 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('No se puede eliminar', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Este alquiler ya tiene pagos registrados y no puede ser eliminado.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Eliminar alquiler?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('¿Estás seguro de que deseas eliminar el alquiler de ${rental.tenant?.name}? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<RentalsBloc>().add(DeleteRentalRequested(rental.id!));
              Navigator.pop(context); // Volver a la lista
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Alquiler eliminado correctamente')),
              );
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          const Text('INQUILINO', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            rental.tenant?.name ?? 'Sin nombre',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.text),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              rental.status == 'PENDING' ? 'Pendiente' : 'Al día',
              style: const TextStyle(color: Color(0xFFC2410C), fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 25),
          const Text('Renta Mensual', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 5),
          Text(
            'S/ ${rental.amount.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppTheme.primary),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.business_outlined, color: AppTheme.primary, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Cuarto / Local: ${rental.roomNumber}',
                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildDetailItem('Meses Totales', '${rental.totalMonths} meses')),
              Expanded(child: _buildDetailItem('Meses Pagados', '${rental.paidMonths}')),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Divider(color: Color(0xFFF1F5F9)),
          ),
          Row(
            children: [
              Expanded(child: _buildDetailItem('Depósito Garantía', 'S/ ${rental.securityDeposit?.toStringAsFixed(0) ?? '0'}')),
              Expanded(child: _buildDetailItem('Monto Cobrado', 'S/ ${rental.amountPaid.toStringAsFixed(0)}', valueColor: const Color(0xFF10B981))),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Divider(color: Color(0xFFF1F5F9)),
          ),
          Row(
            children: [
              Expanded(child: _buildDetailItem('Fecha Inicio', DateFormat('d/M/yyyy').format(rental.startDate))),
              Expanded(child: _buildDetailItem('Próximo Cobro', rental.dueDate != null ? DateFormat('d/M/yyyy').format(rental.dueDate!) : '-')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 5),
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

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            context,
            'Cobrar Mes',
            Icons.payments_outlined,
            const Color(0xFF10B981),
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddRentalPaymentPage(rental: rental)),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildActionButton(
            context,
            'Ver Pagos',
            Icons.access_time,
            const Color(0xFF6366F1),
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RentalPaymentHistoryPage(rental: rental)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
