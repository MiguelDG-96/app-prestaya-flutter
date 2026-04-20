import 'package:dartz/dartz.dart';
import 'package:app_prestaya_flutter/core/error/failure.dart';
import '../entities/client_entity.dart';
import '../repositories/client_repository.dart';

class GetClientsUseCase {
  final ClientRepository repository;

  GetClientsUseCase(this.repository);

  Future<Either<Failure, List<ClientEntity>>> execute() async {
    return await repository.getClients();
  }
}
