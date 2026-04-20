import 'package:dartz/dartz.dart';
import 'package:app_prestaya_flutter/core/error/failure.dart';
import 'package:app_prestaya_flutter/features/loans/domain/entities/loan_entity.dart';

abstract class LoanRepository {
  Future<Either<Failure, LoanEntity>> createLoan({
    required String clientId,
    required double amount,
    required double interestRate,
    required LoanFrequency frequency,
    required DateTime startDate,
    required int durationMonths,
  });

  Future<Either<Failure, List<LoanEntity>>> getLoans();
}
