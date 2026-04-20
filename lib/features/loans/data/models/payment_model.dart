import '../../domain/entities/payment_entity.dart';

class PaymentModel extends PaymentEntity {
  const PaymentModel({
    super.id,
    required super.loanId,
    required super.amount,
    super.paymentDate,
    super.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'loan': {
        'id': loanId,
      },
      'amount': amount,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}
