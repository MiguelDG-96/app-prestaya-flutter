import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/loan_entity.dart';
import '../entities/payment_entity.dart';

abstract class LoansRepository {
  Future<Either<Failure, LoanEntity>> addLoan(LoanEntity loan);
  Future<Either<Failure, List<LoanEntity>>> getLoans();
  Future<Either<Failure, Unit>> addPayment(PaymentEntity payment);
  Future<Either<Failure, LoanEntity>> updateLoan(String id, Map<String, dynamic> data);
  Future<Either<Failure, Unit>> deleteLoan(String id);
}
