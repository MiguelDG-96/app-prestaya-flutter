import 'package:dartz/dartz.dart';
import 'package:app_prestaya_flutter/core/error/failure.dart';
import '../../domain/entities/client_entity.dart';
import '../../domain/repositories/client_repository.dart';
import '../datasources/client_remote_datasource.dart';

class ClientRepositoryImpl implements ClientRepository {
  final ClientRemoteDataSource remoteDataSource;

  ClientRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<ClientEntity>>> getClients() async {
    try {
      final clients = await remoteDataSource.getClients();
      return Right(clients);
    } catch (e) {
      return Left(ServerFailure('Error al cargar clientes: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ClientEntity>> addClient(Map<String, dynamic> clientData) async {
    try {
      final client = await remoteDataSource.addClient(clientData);
      return Right(client);
    } catch (e) {
      return Left(ServerFailure('Error al registrar cliente: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ClientEntity>> updateClient(String id, Map<String, dynamic> clientData) async {
    try {
      final client = await remoteDataSource.updateClient(id, clientData);
      return Right(client);
    } catch (e) {
      return Left(ServerFailure('Error al actualizar cliente: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteClient(String id) async {
    try {
      await remoteDataSource.deleteClient(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al eliminar cliente: ${e.toString()}'));
    }
  }
}
