import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import 'package:app_prestaya_flutter/features/rentals/domain/entities/rental_entity.dart';

abstract class RentalsRepository {
  Future<Either<Failure, RentalEntity>> addRental(RentalEntity rental);
  Future<Either<Failure, List<RentalEntity>>> getRentals();
  Future<Either<Failure, void>> addPayment({
    required String rentalId,
    required double amount,
    String? notes,
  });
  Future<Either<Failure, void>> deleteRental(String id);
  Future<Either<Failure, RentalEntity>> updateRental(String id, Map<String, dynamic> data);
}
