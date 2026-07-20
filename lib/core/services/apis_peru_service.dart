import 'package:app_prestaya_flutter/core/network/dio_client.dart';

class ApisPeruService {
  final DioClient _dioClient;

  ApisPeruService(this._dioClient);

  Future<Map<String, dynamic>?> getDniData(String dni) async {
    try {
      // Llamamos a nuestro propio backend proxy
      final response = await _dioClient.get('/clients/consult-dni/$dni');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getRucData(String ruc) async {
    try {
      // Llamamos a nuestro propio backend proxy
      final response = await _dioClient.get('/clients/consult-ruc/$ruc');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}
