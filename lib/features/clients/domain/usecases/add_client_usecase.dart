import 'package:dartz/dartz.dart';
import 'package:app_prestaya_flutter/core/error/failure.dart';
import '../entities/client_entity.dart';
import '../repositories/client_repository.dart';

class AddClientUseCase {
  final ClientRepository repository;

  AddClientUseCase(this.repository);

  Future<Either<Failure, ClientEntity>> execute(Map<String, dynamic> clientData) async {
    return await repository.addClient(clientData);
  }
}
