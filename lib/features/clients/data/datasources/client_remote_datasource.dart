import 'package:dio/dio.dart';
import '../models/client_model.dart';

abstract class ClientRemoteDataSource {
  Future<List<ClientModel>> getClients();
  Future<ClientModel> addClient(Map<String, dynamic> clientData);
  Future<ClientModel> updateClient(String id, Map<String, dynamic> clientData);
  Future<void> deleteClient(String id);
}

class ClientRemoteDataSourceImpl implements ClientRemoteDataSource {
  final Dio client;

  ClientRemoteDataSourceImpl({required this.client});

  @override
  Future<List<ClientModel>> getClients() async {
    final response = await client.get('/clients');
    final list = response.data as List;
    return list.map((e) => ClientModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<ClientModel> addClient(Map<String, dynamic> clientData) async {
    final response = await client.post('/clients', data: clientData);
    return ClientModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ClientModel> updateClient(String id, Map<String, dynamic> clientData) async {
    final response = await client.put('/clients/$id', data: clientData);
    return ClientModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteClient(String id) async {
    await client.delete('/clients/$id');
  }
}
