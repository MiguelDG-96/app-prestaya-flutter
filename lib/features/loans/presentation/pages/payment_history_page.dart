import 'package:flutter/material.dart';
import 'package:app_prestaya_flutter/core/theme/app_theme.dart';
import 'package:app_prestaya_flutter/features/loans/domain/entities/loan_entity.dart';
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
      body: Column(
        children: [
          _buildSummaryCard(paidInstallments, totalInstallments, progress),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: totalInstallments,
              itemBuilder: (context, index) {
                final installmentNumber = index + 1;
                final isPaid = installmentNumber <= paidInstallments;
                return _buildInstallmentItem(installmentNumber, isPaid, installmentAmount);
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loan.clientName ?? 'Cliente', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text('Estado de pagos', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
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

  Widget _buildInstallmentItem(int number, bool isPaid, double amount) {
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
              if (number < loan.installments)
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
                      Text(
                        isPaid ? '15/04/2024' : 'Próximamente',
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
