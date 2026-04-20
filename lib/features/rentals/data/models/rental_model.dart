import 'package:intl/intl.dart';
import 'package:app_prestaya_flutter/features/rentals/domain/entities/rental_entity.dart';
import 'package:app_prestaya_flutter/features/rentals/data/models/tenant_model.dart';

class RentalModel extends RentalEntity {
  const RentalModel({
    super.id,
    super.tenant,
    super.tenantId,
    required super.amount,
    required super.roomNumber,
    required super.startDate,
    super.dueDate,
    super.totalMonths,
    super.paidMonths,
    super.securityDeposit,
    super.status,
    super.amountPaid,
  });

  factory RentalModel.fromJson(Map<String, dynamic> json) {
    return RentalModel(
      id: json['id'],
      tenant: json['tenant'] != null ? TenantModel.fromJson(json['tenant']) : null,
      tenantId: json['tenantId'] ?? json['tenant_id'],
      amount: (json['amount'] as num).toDouble(),
      roomNumber: json['roomNumber'] ?? json['room_number'] ?? '',
      startDate: DateTime.parse(json['startDate'] ?? json['start_date']),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : (json['due_date'] != null ? DateTime.parse(json['due_date']) : null),
      totalMonths: json['totalMonths'] ?? json['total_months'] ?? 1,
      paidMonths: json['paidMonths'] ?? json['paid_months'] ?? 0,
      securityDeposit: json['securityDeposit'] != null ? (json['securityDeposit'] as num).toDouble() : (json['security_deposit'] != null ? (json['security_deposit'] as num).toDouble() : null),
      status: json['status'] ?? 'PENDING',
      amountPaid: (json['amountPaid'] ?? json['amount_paid'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'roomNumber': roomNumber,
      'startDate': DateFormat('yyyy-MM-dd').format(startDate),
      'totalMonths': totalMonths,
      'securityDeposit': securityDeposit,
      // Tenant data if nested
      'tenant': tenant != null ? (tenant as TenantModel).toJson() : null,
      'tenantId': tenantId,
    };
  }
}
