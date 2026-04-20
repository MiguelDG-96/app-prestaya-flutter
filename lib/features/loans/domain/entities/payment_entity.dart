import 'package:equatable/equatable.dart';

class PaymentEntity extends Equatable {
  final String? id;
  final String loanId;
  final double amount;
  final DateTime? paymentDate;
  final String? notes;

  const PaymentEntity({
    this.id,
    required this.loanId,
    required this.amount,
    this.paymentDate,
    this.notes,
  });

  @override
  List<Object?> get props => [id, loanId, amount, paymentDate, notes];
}
