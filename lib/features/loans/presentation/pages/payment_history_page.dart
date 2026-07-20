import 'package:flutter/material.dart';
import 'package:app_prestaya_flutter/core/theme/app_theme.dart';
import 'package:app_prestaya_flutter/features/loans/domain/entities/loan_entity.dart';
import 'package:app_prestaya_flutter/features/loans/domain/entities/payment_entity.dart';
import 'package:intl/intl.dart';

class PaymentHistoryPage extends StatelessWidget {
  final LoanEntity loan;
  const PaymentHistoryPage({super.key, required this.loan});

  @override
  Widget build(BuildContext context) {
    final paidInstallments = loan.currentInstallment ?? 0;
    final totalInstallments = loan.installments;
    final installmentAmount = (loan.totalToPay ?? 0) / totalInstallments;
    final progress = paidInstallments / totalInstallments;

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
      body: Builder(
        builder: (context) {
          // Ordenar pagos por fecha ascendente
          final sortedPayments = List<PaymentEntity>.from(loan.payments)
            ..sort((a, b) => (a.paymentDate ?? DateTime(2000)).compareTo(b.paymentDate ?? DateTime(2000)));

          // Encontrar el número máximo de cuota registrado en los pagos
          int totalInstallmentsLimit = loan.installments;
          for (var p in sortedPayments) {
            final regExp = RegExp(r'cuota (\d+)', caseSensitive: false);
            final match = regExp.firstMatch(p.notes ?? '');
            if (match != null) {
              final num = int.tryParse(match.group(1) ?? '');
              if (num != null && num > totalInstallmentsLimit) {
                totalInstallmentsLimit = num;
              }
            }
          }

          // Calcular cuotas pagadas reales (incluyendo forzadas por nota y adicionales)
          int effectivePaidCount = 0;
          for (int i = 1; i <= totalInstallmentsLimit; i++) {
            final isPaid = _isInstallmentPaid(loan, i);
            if (isPaid) {
              effectivePaidCount++;
            }
          }

          // Si todas las cuotas actuales están pagadas pero no se ha pagado la totalidad, añadimos una virtual
          final isFullyPaid = (loan.paidAmount ?? 0) >= (loan.totalToPay ?? 0) - 0.01;
          if (effectivePaidCount == totalInstallmentsLimit && !isFullyPaid) {
            totalInstallmentsLimit++;
          }

          final effectiveProgress = totalInstallmentsLimit > 0 ? (effectivePaidCount / totalInstallmentsLimit) : 0.0;

          return Column(
            children: [
              _buildSummaryCard(effectivePaidCount, totalInstallmentsLimit, effectiveProgress),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: totalInstallmentsLimit,
                  itemBuilder: (context, index) {
                    final installmentNumber = index + 1;
                    
                    // Filtrar los pagos que pertenecen a esta cuota específica por su nota
                    final paymentsForThisInst = sortedPayments.where((p) => 
                      (p.notes ?? '').toLowerCase().contains('cuota $installmentNumber')
                    ).toList();
                    
                    final lastPayment = paymentsForThisInst.isNotEmpty ? paymentsForThisInst.last : null;
                    final isPaid = _isInstallmentPaid(loan, installmentNumber);
                    final realDate = lastPayment?.paymentDate;
                    
                    // Calcular el total abonado específicamente a esta cuota
                    final totalPaidForThisInst = paymentsForThisInst.fold<double>(0, (sum, p) => sum + (p.amount ?? 0));
                    
                    // Calcular el monto esperado para esta cuota
                    final isExtra = installmentNumber > loan.installments;
                    final baseAmount = (loan.totalToPay ?? 0) / loan.installments;
                    double targetAmount = baseAmount;
                    if (isExtra) {
                      if (totalPaidForThisInst > 0) {
                        targetAmount = totalPaidForThisInst;
                      } else {
                        targetAmount = ((loan.totalToPay ?? 0) - (loan.paidAmount ?? 0)).clamp(0.0, baseAmount);
                      }
                    }
                    
                    final installmentDate = realDate ?? _getInstallmentDate(loan.startDate, loan.frequency, index);
                    return _buildInstallmentItem(installmentNumber, isPaid, targetAmount, totalPaidForThisInst, installmentDate, totalInstallmentsLimit);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _isInstallmentPaid(LoanEntity loan, int i) {
    if ((loan.paidAmount ?? 0) >= (loan.totalToPay ?? 0) - 0.01) {
      return true;
    }
    if (i <= (loan.currentInstallment ?? 0)) {
      return true;
    }
    final isForcedPaid = loan.payments.any((p) => 
      (p.notes ?? '').toLowerCase().contains('cuota $i') && 
      (p.notes ?? '').toLowerCase().contains('completada')
    );
    if (isForcedPaid) return true;
    
    final isExtra = i > loan.installments;
    if (isExtra) {
      final paymentsForThisInst = loan.payments.where((p) => 
        (p.notes ?? '').toLowerCase().contains('cuota $i')
      );
      final totalPaidForThisInst = paymentsForThisInst.fold<double>(0.0, (acc, p) => acc + (p.amount ?? 0.0));
      
      final baseAmount = (loan.totalToPay ?? 0) / loan.installments;
      double amount = baseAmount;
      if (totalPaidForThisInst > 0) {
        amount = totalPaidForThisInst;
      } else {
        amount = baseAmount;
      }
      
      if (totalPaidForThisInst >= amount) {
        return true;
      }
    }
    return false;
  }

  DateTime _getInstallmentDate(DateTime startDate, String frequency, int index) {
    switch (frequency.toLowerCase()) {
      case 'diario':
      case 'daily':
        return startDate.add(Duration(days: index + 1));
      case 'semanal':
      case 'weekly':
        return startDate.add(Duration(days: (index + 1) * 7));
      case 'quincenal':
      case 'fortnightly':
        return startDate.add(Duration(days: (index + 1) * 15));
      case 'mensual':
      case 'monthly':
      default:
        return DateTime(startDate.year, startDate.month + index + 1, startDate.day);
    }
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
                      loan.clientName ?? 'Cliente', 
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const Text('Estado de pagos', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
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
                  '$paid / $total',
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
              Text('${(progress * 100).toStringAsFixed(0)}% Completado', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              Text('Pendiente: S/ ${((loan.totalToPay ?? 0) - (loan.paidAmount ?? 0)).toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstallmentItem(int number, bool isPaid, double amount, double paidAmount, DateTime date, int totalLimit) {
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
                  border: Border.all(color: isPaid ? const Color(0xFF10B981) : const Color(0xFFCBD5E1), width: 2),
                ),
                child: isPaid 
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : Center(child: Text('$number', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
              ),
              if (number < totalLimit)
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
                border: Border.all(color: isPaid ? const Color(0xFF10B981).withOpacity(0.2) : Colors.transparent),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cuota $number', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(
                        isPaid ? 'Pago completado' : 'Pendiente de pago',
                        style: TextStyle(color: isPaid ? const Color(0xFF10B981) : AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                   Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('S/ ${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      if (paidAmount > 0)
                        Text(
                          'Abonado: S/ ${paidAmount.toStringAsFixed(2)}',
                          style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      Text(
                        isPaid ? DateFormat('dd/MM/yyyy').format(date) : 'Próximamente',
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
