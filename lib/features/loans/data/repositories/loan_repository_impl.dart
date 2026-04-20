import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:app_prestaya_flutter/core/error/failure.dart';
import 'package:app_prestaya_flutter/features/loans/domain/entities/loan_entity.dart';
import 'package:app_prestaya_flutter/features/loans/domain/repositories/loan_repository.dart';
import 'package:app_prestaya_flutter/features/loans/data/datasources/loan_remote_datasource.dart';

class LoanRepositoryImpl implements LoanRepository {
  final LoanRemoteDataSource remoteDataSource;

  LoanRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, LoanEntity>> createLoan({
    required String clientId,
    required double amount,
    required double interestRate,
    required LoanFrequency frequency,
    required DateTime startDate,
    required int durationMonths,
  }) async {
    try {
      final loanData = {
        'clientId': clientId,
        'amount': amount,
        'interestRate': interestRate,
        'frequency': frequency.name.toUpperCase(),
        'startDate': startDate.toIso8601String(),
        'durationMonths': durationMonths,
      };

      final result = await remoteDataSource.createLoan(loanData: loanData);
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?['message'] ?? 'Error de servidor'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LoanEntity>>> getLoans() async {
    try {
      final result = await remoteDataSource.getLoans();
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?['message'] ?? 'Error al cargar préstamos'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
