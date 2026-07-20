import 'package:dartz/dartz.dart';
import 'package:app_prestaya_flutter/core/error/failure.dart';
import '../entities/client_entity.dart';

abstract class ClientRepository {
  Future<Either<Failure, List<ClientEntity>>> getClients();
  Future<Either<Failure, ClientEntity>> addClient(Map<String, dynamic> clientData);
  Future<Either<Failure, ClientEntity>> updateClient(String id, Map<String, dynamic> clientData);
  Future<Either<Failure, void>> deleteClient(String id);
  Future<Either<Failure, bool>> checkDni(String dni);
  Future<Either<Failure, bool>> checkEmail(String email);
}
