import 'package:dio/dio.dart';
import 'package:app_prestaya_flutter/core/network/dio_client.dart';
import 'package:app_prestaya_flutter/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login(String email, String password);
  Future<Map<String, dynamic>> loginWithGoogle(String idToken);
  Future<void> updatePushToken(String token);
  Future<String> uploadPhoto(String userId, String filePath);
  Future<Map<String, dynamic>> updateProfile({String? name, String? phone});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient client;

  AuthRemoteDataSourceImpl(this.client);

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await client.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    final response = await client.post('/auth/google', data: {
      'idToken': idToken,
    });
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<void> updatePushToken(String token) async {
    await client.put('/users/update-token', data: {'token': token});
  }

  @override
  Future<String> uploadPhoto(String userId, String filePath) async {
    final fileName = filePath.split('/').last;
    final formData = FormData.fromMap({
      'userId': userId,
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final response = await client.post('/users/photo', data: formData);
    return response.data['photoUrl'] as String;
  }

  @override
  Future<Map<String, dynamic>> updateProfile({String? name, String? phone}) async {
    final data = <String, String>{};
    if (name != null) data['name'] = name;
    if (phone != null) data['phone'] = phone;

    final response = await client.put('/users/profile', data: data);
    // El backend devuelve { "message": "...", "user": { ... } }
    return response.data['user'] as Map<String, dynamic>;
  }
}
