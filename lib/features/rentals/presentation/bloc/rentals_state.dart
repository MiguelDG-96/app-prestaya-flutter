import 'package:equatable/equatable.dart';
import 'package:app_prestaya_flutter/features/rentals/domain/entities/rental_entity.dart';

abstract class RentalsState extends Equatable {
  const RentalsState();

  @override
  List<Object?> get props => [];
}

class RentalsInitial extends RentalsState {}

class RentalsLoading extends RentalsState {}

class RentalsLoaded extends RentalsState {
  final List<RentalEntity> rentals;
  const RentalsLoaded(this.rentals);

  @override
  List<Object?> get props => [rentals];
}

class RentalAddedSuccess extends RentalsState {
  final RentalEntity rental;
  const RentalAddedSuccess(this.rental);

  @override
  List<Object?> get props => [rental];
}

class RentalsError extends RentalsState {
  final String message;
  const RentalsError(this.message);

  @override
  List<Object?> get props => [message];
}

class RentalPaymentSuccess extends RentalsState {}
