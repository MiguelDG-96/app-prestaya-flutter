import '../../domain/entities/loan_entity.dart';
import 'package:intl/intl.dart';

class LoanModel extends LoanEntity {
  const LoanModel({
    super.id,
    required super.clientId,
    required super.amount,
    required super.interest,
    required super.installments,
    required super.frequency,
    required super.dueDate,
    super.clientName,
    super.currentInstallment,
    super.paidAmount,
    super.totalToPay,
  });

  factory LoanModel.fromJson(Map<String, dynamic> json) {
    // El backend devuelve un objeto 'client' anidado
    String? name;
    if (json['client'] != null && json['client'] is Map) {
      name = json['client']['name'];
    }

    double amount = (json['amount'] != null) ? (json['amount'] as num).toDouble() : 0.0;
    double totalToPay = json['totalToPay'] != null ? (json['totalToPay'] as num).toDouble() : 0.0;
    
    // Fallback: Si el interés viene nulo o es 0, lo calculamos de la deuda total
    double interestVal = (json['interestRate'] ?? json['interest'] ?? json['interest_rate'] ?? 0.0).toDouble();
    if (interestVal == 0 && amount > 0 && totalToPay > amount) {
      interestVal = ((totalToPay / amount) - 1) * 100;
    } else if (interestVal > 0 && interestVal < 1) {
      // Si el backend lo manda como decimal (0.2), lo pasamos a porcentaje (20)
      interestVal = interestVal * 100;
    }

    return LoanModel(
      id: json['id'],
      clientId: json['clientId'] ?? json['client_id'] ?? '',
      amount: amount,
      interest: interestVal,
      installments: (json['totalInstallments'] ?? json['total_installments'] ?? 0) as int,
      frequency: json['frequency'] ?? 'MONTHLY',
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : (json['due_date'] != null ? DateTime.parse(json['due_date']) : DateTime.now()),
      clientName: name ?? json['clientName'] ?? json['client_name'],
      currentInstallment: (json['paidInstallments'] ?? json['paid_installments'] ?? 0) as int,
      paidAmount: (json['amountPaid'] ?? json['amount_paid'] ?? 0.0).toDouble(),
      totalToPay: totalToPay,
    );
  }

  Map<String, dynamic> toJson() {
    // Mapeo para LoanCreateRequest.java del backend
    return {
      'clientId': clientId,
      'amount': amount,
      'interestRate': interest,
      'totalInstallments': installments,
      'startDate': DateFormat('yyyy-MM-dd').format(DateTime.now()), // El backend pide startDate
      'paymentFrequency': _mapFrequencyToBackend(frequency),
    };
  }

  static String _mapFrequencyToBackend(String flutterFreq) {
    switch (flutterFreq.toLowerCase()) {
      case 'diario':
        return 'DAILY';
      case 'semanal':
        return 'WEEKLY';
      case 'quincenal':
        return 'WEEKLY'; // Ajuste temporal ya que el backend no tiene FORTNIGHTLY
      case 'mensual':
      default:
        return 'MONTHLY';
    }
  }
}
