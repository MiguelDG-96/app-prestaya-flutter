import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:app_prestaya_flutter/core/error/failure.dart';
import 'package:app_prestaya_flutter/core/network/dio_client.dart';
import 'package:app_prestaya_flutter/features/auth/domain/entities/user_entity.dart';
import 'package:app_prestaya_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:app_prestaya_flutter/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:app_prestaya_flutter/features/auth/data/models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final FlutterSecureStorage storage;

  AuthRepositoryImpl(this.remoteDataSource, this.storage);

  @override
  Future<Either<Failure, UserEntity>> login(String email, String password) async {
    try {
      final data = await remoteDataSource.login(email, password);
      final token = data['token'] as String;
      
      final userMap = data['user'] != null ? data['user'] as Map<String, dynamic> : data;
      
      if (userMap['id'] == null && userMap['_id'] != null) {
        userMap['id'] = userMap['_id'];
      }
      
      final userModel = UserModel.fromJson(userMap);

      await storage.write(key: DioClient.tokenKey, value: token);
      await storage.write(key: '@user_profile', value: jsonEncode(userModel.toJson()));

      return Right(userModel);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?['message'] ?? 'Error de credenciales'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> loginWithGoogle(String idToken) async {
    try {
      final data = await remoteDataSource.loginWithGoogle(idToken);
      final token = data['token'] as String;
      
      final userMap = data['user'] != null ? data['user'] as Map<String, dynamic> : data;
      
      if (userMap['id'] == null && userMap['_id'] != null) {
        userMap['id'] = userMap['_id'];
      }
      
      final userModel = UserModel.fromJson(userMap);

      await storage.write(key: DioClient.tokenKey, value: token);
      await storage.write(key: '@user_profile', value: jsonEncode(userModel.toJson()));

      return Right(userModel);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?['message'] ?? 'Error con Google'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<void> logout() async {
    await storage.delete(key: DioClient.tokenKey);
    await storage.delete(key: '@user_profile');
  }

  @override
  Future<Option<UserEntity>> getLoggedInUser() async {
    try {
      final userJson = await storage.read(key: '@user_profile');
      if (userJson != null) {
        final userData = jsonDecode(userJson) as Map<String, dynamic>;
        return some(UserModel.fromJson(userData));
      }
    } catch (e) {
      // Error silencioso en producción
    }
    return none();
  }

  @override
  Future<Either<Failure, UserEntity>> uploadPhoto(String userId, String filePath) async {
    try {
      final photoUrl = await remoteDataSource.uploadPhoto(userId, filePath);
      
      final userJson = await storage.read(key: '@user_profile');
      if (userJson != null) {
        final userData = jsonDecode(userJson) as Map<String, dynamic>;
        userData['photoUrl'] = photoUrl;
        
        final updatedUserModel = UserModel.fromJson(userData);
        await storage.write(key: '@user_profile', value: jsonEncode(updatedUserModel.toJson()));
        
        return Right(updatedUserModel);
      }
      
      return Left(ServerFailure('No se encontró sesión de usuario activa'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile({String? name, String? phone}) async {
    try {
      final userMap = await remoteDataSource.updateProfile(name: name, phone: phone);
      
      if (userMap['id'] == null && userMap['_id'] != null) {
        userMap['id'] = userMap['_id'];
      }
      
      final updatedUserModel = UserModel.fromJson(userMap);
      await storage.write(key: '@user_profile', value: jsonEncode(updatedUserModel.toJson()));
      
      return Right(updatedUserModel);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?['message'] ?? 'Error al actualizar perfil'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
