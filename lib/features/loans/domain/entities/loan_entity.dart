import 'package:equatable/equatable.dart';
import 'payment_entity.dart';

class LoanEntity extends Equatable {
  final String? id;
  final String clientId;
  final double amount;
  final double interest;
  final int installments;
  final String frequency;
  final DateTime startDate;
  final DateTime dueDate;
  final String? clientName;
  final int? currentInstallment;
  final double? paidAmount;
  final double? totalToPay;
  final List<PaymentEntity> payments;

  const LoanEntity({
    this.id,
    required this.clientId,
    required this.amount,
    required this.interest,
    required this.installments,
    required this.frequency,
    required this.startDate,
    required this.dueDate,
    this.clientName,
    this.currentInstallment,
    this.paidAmount,
    this.totalToPay,
    this.payments = const [],
  });

  @override
  List<Object?> get props => [
        id,
        clientId,
        amount,
        interest,
        installments,
        frequency,
        startDate,
        dueDate,
        clientName,
        currentInstallment,
        paidAmount,
        totalToPay,
        payments,
      ];
}
