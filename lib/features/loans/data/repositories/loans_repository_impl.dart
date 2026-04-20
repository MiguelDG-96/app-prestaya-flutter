import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/loan_entity.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/repositories/loans_repository.dart';
import '../models/loan_model.dart';
import '../models/payment_model.dart';

class LoansRepositoryImpl implements LoansRepository {
  final DioClient dioClient;

  LoansRepositoryImpl({required this.dioClient});

  @override
  Future<Either<Failure, LoanEntity>> addLoan(LoanEntity loan) async {
    try {
      final model = LoanModel(
        clientId: loan.clientId,
        amount: loan.amount,
        interest: loan.interest,
        installments: loan.installments,
        frequency: loan.frequency,
        dueDate: loan.dueDate,
      );

      final response = await dioClient.post('/loans', data: model.toJson());
      final result = LoanModel.fromJson(response.data);
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?['message'] ?? 'Error al registrar préstamo'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LoanEntity>>> getLoans() async {
    try {
      final response = await dioClient.get('/loans');
      final list = (response.data as List).map((e) => LoanModel.fromJson(e)).toList();
      return Right(list);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?['message'] ?? 'Error al obtener préstamos'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> addPayment(PaymentEntity payment) async {
    try {
      final model = PaymentModel(
        loanId: payment.loanId,
        amount: payment.amount,
        notes: payment.notes,
      );

      await dioClient.post('/payments', data: model.toJson());
      return const Right(unit);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?['message'] ?? 'Error al registrar pago'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, LoanEntity>> updateLoan(String id, Map<String, dynamic> data) async {
    try {
      final response = await dioClient.put('/api/loans/$id', data: data);
      return Right(LoanModel.fromJson(response.data));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteLoan(String id) async {
    try {
      await dioClient.delete('/api/loans/$id');
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
