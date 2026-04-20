import 'package:equatable/equatable.dart';
import 'tenant_entity.dart';

class RentalEntity extends Equatable {
  final String? id;
  final TenantEntity? tenant;
  final String? tenantId;
  final double amount;
  final String roomNumber;
  final DateTime startDate;
  final DateTime? dueDate;
  final int totalMonths;
  final int paidMonths;
  final double? securityDeposit;
  final String status;
  final double amountPaid;

  const RentalEntity({
    this.id,
    this.tenant,
    this.tenantId,
    required this.amount,
    required this.roomNumber,
    required this.startDate,
    this.dueDate,
    this.totalMonths = 1,
    this.paidMonths = 0,
    this.securityDeposit,
    this.status = 'PENDING',
    this.amountPaid = 0.0,
  });

  @override
  List<Object?> get props => [
        id,
        tenant,
        tenantId,
        amount,
        roomNumber,
        startDate,
        dueDate,
        totalMonths,
        paidMonths,
        securityDeposit,
        status,
        amountPaid,
      ];
}
