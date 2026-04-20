import 'package:dartz/dartz.dart';
import 'package:app_prestaya_flutter/core/error/failure.dart';
import '../entities/client_entity.dart';
import '../repositories/client_repository.dart';

class UpdateClientUseCase {
  final ClientRepository repository;
  UpdateClientUseCase(this.repository);

  Future<Either<Failure, ClientEntity>> execute(String id, Map<String, dynamic> clientData) {
    return repository.updateClient(id, clientData);
  }
}

class DeleteClientUseCase {
  final ClientRepository repository;
  DeleteClientUseCase(this.repository);

  Future<Either<Failure, void>> execute(String id) {
    return repository.deleteClient(id);
  }
}
