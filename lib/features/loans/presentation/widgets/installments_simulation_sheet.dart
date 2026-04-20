import 'package:flutter/material.dart';
import 'package:app_prestaya_flutter/core/theme/app_theme.dart';
import 'package:app_prestaya_flutter/core/widgets/custom_button.dart';
import 'package:intl/intl.dart';

class InstallmentsSimulationSheet extends StatelessWidget {
  final double amount;
  final double interestRate;
  final int installments;
  final String frequency;
  final DateTime startDate;

  const InstallmentsSimulationSheet({
    super.key,
    required this.amount,
    required this.interestRate,
    required this.installments,
    required this.frequency,
    required this.startDate,
  });

  static void show({
    required BuildContext context,
    required double amount,
    required double interestRate,
    required int installments,
    required String frequency,
    required DateTime startDate,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InstallmentsSimulationSheet(
        amount: amount,
        interestRate: interestRate,
        installments: installments,
        frequency: frequency,
        startDate: startDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final interestAmount = amount * (interestRate / 100);
    final totalAmount = amount + interestAmount;
    final installmentAmount = totalAmount / installments;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          _buildSummaryCard(interestAmount, totalAmount),
          const SizedBox(height: 20),
          _buildTableHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: installments,
              itemBuilder: (context, index) {
                final date = _calculateNextDate(startDate, index + 1, frequency);
                return _buildInstallmentRow(index + 1, date, installmentAmount);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: CustomButton(
              title: 'Cerrar Simulación',
              onPress: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 10, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Simulación de Cuotas',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.text),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double interest, double total) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Capital', 'S/ ${amount.toStringAsFixed(0)}'),
          _buildSummaryItem('Interés (${interestRate.toStringAsFixed(0)}%)', 'S/ ${interest.toStringAsFixed(0)}'),
          _buildSummaryItem('Total', 'S/ ${total.toStringAsFixed(0)}', isTotal: true),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, {bool isTotal = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isTotal ? AppTheme.primary : AppTheme.text,
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: const [
          SizedBox(width: 40, child: Text('N°', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          Expanded(child: Text('Próximo Cobro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          Text('Monto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildInstallmentRow(int n, DateTime date, double monto) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text('$n', style: const TextStyle(color: AppTheme.textSecondary))),
          Expanded(child: Text(DateFormat('dd/MM/yyyy').format(date))),
          Text(
            'S/ ${monto.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.text),
          ),
        ],
      ),
    );
  }

  DateTime _calculateNextDate(DateTime start, int installmentNum, String freq) {
    switch (freq) {
      case 'Diario':
        return start.add(Duration(days: installmentNum));
      case 'Semanal':
        return start.add(Duration(days: 7 * installmentNum));
      case 'Quincenal':
        return start.add(Duration(days: 15 * installmentNum));
      case 'Mensual':
        // Sumar meses correctamente
        return DateTime(start.year, start.month + installmentNum, start.day);
      default:
        return start;
    }
  }
}
