import '../../domain/entities/payment_entity.dart';

class PaymentModel extends PaymentEntity {
  const PaymentModel({
    super.id,
    required super.loanId,
    required super.amount,
    super.paymentDate,
    super.notes,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'],
      loanId: json['loan'] != null ? json['loan']['id'] : (json['loanId'] ?? ''),
      amount: (json['amount'] as num).toDouble(),
      paymentDate: json['paymentDate'] != null ? DateTime.parse(json['paymentDate']) : null,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'loan': {
        'id': loanId,
      },
      'amount': amount,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (paymentDate != null) 'paymentDate': paymentDate!.toIso8601String().split('T')[0],
    };
  }
}
