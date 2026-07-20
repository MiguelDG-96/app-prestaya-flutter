import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/dio_client.dart';
import 'package:app_prestaya_flutter/features/rentals/domain/entities/rental_entity.dart';
import 'package:app_prestaya_flutter/features/rentals/domain/repositories/rentals_repository.dart';
import 'package:app_prestaya_flutter/features/rentals/data/models/rental_model.dart';
import 'package:app_prestaya_flutter/features/rentals/data/models/tenant_model.dart';

class RentalsRepositoryImpl implements RentalsRepository {
  final DioClient dioClient;

  RentalsRepositoryImpl({required this.dioClient});

  @override
  Future<Either<Failure, RentalEntity>> addRental(RentalEntity rental) async {
    try {
      String? finalTenantId;
      
      // Buscar si el inquilino ya existe en la tabla tenants por DNI
      if (rental.tenant?.dni != null && rental.tenant!.dni.isNotEmpty) {
        final tenantsResponse = await dioClient.get('/tenants');
        final tenantsList = tenantsResponse.data as List;
        
        final existingTenant = tenantsList.cast<Map<String, dynamic>>().firstWhere(
          (t) => t['dni'] == rental.tenant!.dni, 
          orElse: () => <String, dynamic>{}
        );

        if (existingTenant.isNotEmpty) {
          finalTenantId = existingTenant['id'];
        }
      }
      
      // Si no existe como inquilino, lo creamos
      if (finalTenantId == null) {
        final tenantModel = TenantModel(
          name: rental.tenant!.name,
          phone: rental.tenant!.phone,
          dni: rental.tenant!.dni,
          address: rental.tenant!.address,
          roomNumber: rental.tenant!.roomNumber,
          email: rental.tenant!.email,
        );

        final tenantResponse = await dioClient.post('/tenants', data: tenantModel.toJson());
        final createdTenant = TenantModel.fromJson(tenantResponse.data);
        finalTenantId = createdTenant.id;
      }

      // 2. Crear el Alquiler con el ID del inquilino verificado
      final rentalData = {
        'tenantId': finalTenantId,
        'roomId': rental.roomNumber,
        'monthlyRent': rental.amount,
        'startDate': rental.startDate.toIso8601String().split('T')[0],
        'totalMonths': rental.totalMonths,
        'securityDeposit': rental.securityDeposit,
      };

      final rentalResponse = await dioClient.post('/rentals', data: rentalData);
      final result = RentalModel.fromJson(rentalResponse.data);
      
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?['message'] ?? 'Error al registrar alquiler'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RentalEntity>>> getRentals() async {
    try {
      final response = await dioClient.get('/rentals');
      final list = (response.data as List).map((e) => RentalModel.fromJson(e)).toList();
      return Right(list);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?['message'] ?? 'Error al obtener alquileres'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addPayment({
    required String rentalId,
    required double amount,
    String? notes,
    DateTime? paymentDate,
  }) async {
    try {
      final paymentData = {
        'rental': {'id': rentalId},
        'amount': amount,
        'notes': notes,
        if (paymentDate != null) 'paymentDate': paymentDate.toIso8601String().split('T')[0],
      };

      await dioClient.post('/payments', data: paymentData);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Error al procesar el pago'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRental(String id) async {
    try {
      await dioClient.delete('/rentals/$id');
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?['message'] ?? 'Error al eliminar el alquiler'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RentalEntity>> updateRental(String id, Map<String, dynamic> data) async {
    try {
      final response = await dioClient.patch('/rentals/$id', data: data);
      final result = RentalModel.fromJson(response.data);
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?['message'] ?? 'Error al actualizar el alquiler'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
