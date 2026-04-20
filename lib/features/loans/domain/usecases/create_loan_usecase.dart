import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:app_prestaya_flutter/core/error/failure.dart';
import 'package:app_prestaya_flutter/features/loans/domain/entities/loan_entity.dart';
import 'package:app_prestaya_flutter/features/loans/domain/repositories/loan_repository.dart';

class CreateLoanUseCase {
  final LoanRepository repository;

  CreateLoanUseCase(this.repository);

  Future<Either<Failure, LoanEntity>> execute(CreateLoanParams params) async {
    return await repository.createLoan(
      clientId: params.clientId,
      amount: params.amount,
      interestRate: params.interestRate,
      frequency: params.frequency,
      startDate: params.startDate,
      durationMonths: params.durationMonths,
    );
  }
}

class CreateLoanParams extends Equatable {
  final String clientId;
  final double amount;
  final double interestRate;
  final LoanFrequency frequency;
  final DateTime startDate;
  final int durationMonths;

  const CreateLoanParams({
    required this.clientId,
    required this.amount,
    required this.interestRate,
    required this.frequency,
    required this.startDate,
    required this.durationMonths,
  });

  @override
  List<Object> get props => [
        clientId,
        amount,
        interestRate,
        frequency,
        startDate,
        durationMonths,
      ];
}
