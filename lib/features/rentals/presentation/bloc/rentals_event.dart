import 'package:equatable/equatable.dart';
import 'package:app_prestaya_flutter/features/rentals/domain/entities/rental_entity.dart';

abstract class RentalsEvent extends Equatable {
  const RentalsEvent();

  @override
  List<Object?> get props => [];
}

class AddRentalRequested extends RentalsEvent {
  final RentalEntity rental;
  const AddRentalRequested(this.rental);

  @override
  List<Object?> get props => [rental];
}

class GetRentalsRequested extends RentalsEvent {
  const GetRentalsRequested();
}

class AddRentalPaymentRequested extends RentalsEvent {
  final String rentalId;
  final double amount;
  final String? notes;

  const AddRentalPaymentRequested({
    required this.rentalId,
    required this.amount,
    this.notes,
  });

  @override
  List<Object?> get props => [rentalId, amount, notes];
}

class DeleteRentalRequested extends RentalsEvent {
  final String rentalId;
  const DeleteRentalRequested(this.rentalId);

  @override
  List<Object?> get props => [rentalId];
}

class UpdateRentalRequested extends RentalsEvent {
  final String id;
  final Map<String, dynamic> data;
  const UpdateRentalRequested(this.id, this.data);

  @override
  List<Object?> get props => [id, data];
}
