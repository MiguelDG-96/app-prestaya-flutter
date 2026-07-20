import 'package:flutter/material.dart';
import 'package:app_prestaya_flutter/core/theme/app_theme.dart';
import 'package:app_prestaya_flutter/features/rentals/domain/entities/rental_entity.dart';
import 'package:intl/intl.dart';

class RentalPaymentHistoryPage extends StatelessWidget {
  final RentalEntity rental;
  const RentalPaymentHistoryPage({super.key, required this.rental});

  @override
  Widget build(BuildContext context) {
    final paidMonths = rental.paidMonths;
    final totalMonths = rental.totalMonths;
    final monthlyRent = rental.amount;
    final progress = totalMonths > 0 ? paidMonths / totalMonths : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Historial de Pagos',
          style: TextStyle(color: AppTheme.text, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSummaryCard(paidMonths, totalMonths, progress),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: totalMonths,
              itemBuilder: (context, index) {
                final monthNumber = index + 1;
                final isPaid = monthNumber <= paidMonths;
                
                // Intentar obtener la fecha real del pago si existe
                DateTime? realPaymentDate;
                if (isPaid && rental.payments.length > index) {
                  realPaymentDate = rental.payments[index].paymentDate;
                }

                // Calcular fecha programada de cada mes
                final scheduledDate = DateTime(
                  rental.startDate.year,
                  rental.startDate.month + index,
                  rental.startDate.day,
                );

                final displayDate = realPaymentDate ?? scheduledDate;

                return _buildMonthItem(monthNumber, isPaid, monthlyRent, displayDate);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(int paid, int total, double progress) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rental.tenant?.name ?? 'Inquilino',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      'Cuarto: ${rental.roomNumber}',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$paid / $total Meses',
                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(0)}% Pagado',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              Text(
                'Total: S/ ${(rental.amount * total).toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthItem(int number, bool isPaid, double amount, DateTime date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isPaid ? const Color(0xFF10B981) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isPaid ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                    width: 2,
                  ),
                ),
                child: isPaid 
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : Center(
                      child: Text(
                        '$number',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ),
              ),
              if (number < rental.totalMonths)
                Container(
                  width: 2,
                  height: 40,
                  color: const Color(0xFFCBD5E1),
                ),
            ],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isPaid ? const Color(0xFF10B981).withOpacity(0.2) : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mes $number',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        isPaid ? 'Renta pagada' : 'Pendiente de pago',
                        style: TextStyle(
                          color: isPaid ? const Color(0xFF10B981) : AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'S/ ${amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        DateFormat('MMMM yyyy', 'es').format(date),
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
