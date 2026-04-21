import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_prestaya_flutter/features/rentals/domain/repositories/rentals_repository.dart';
import 'package:app_prestaya_flutter/features/rentals/presentation/bloc/rentals_event.dart';
import 'package:app_prestaya_flutter/features/rentals/presentation/bloc/rentals_state.dart';

class RentalsBloc extends Bloc<RentalsEvent, RentalsState> {
  final RentalsRepository repository;

  RentalsBloc({required this.repository}) : super(RentalsInitial()) {
    on<AddRentalRequested>((event, emit) async {
      emit(RentalsLoading());
      final result = await repository.addRental(event.rental);
      result.fold(
        (failure) => emit(RentalsError(failure.message)),
        (rental) {
          emit(RentalAddedSuccess(rental));
          add(const GetRentalsRequested());
        },
      );
    });

    on<GetRentalsRequested>((event, emit) async {
      emit(RentalsLoading());
      final result = await repository.getRentals();
      result.fold(
        (failure) => emit(RentalsError(failure.message)),
        (rentals) => emit(RentalsLoaded(rentals)),
      );
    });

    on<AddRentalPaymentRequested>((event, emit) async {
      emit(RentalsLoading());
      final result = await repository.addPayment(
        rentalId: event.rentalId,
        amount: event.amount,
        notes: event.notes,
      );
      result.fold(
        (failure) => emit(RentalsError(failure.message)),
        (_) {
          emit(RentalPaymentSuccess());
          add(const GetRentalsRequested());
        },
      );
    });

    on<DeleteRentalRequested>((event, emit) async {
      emit(RentalsLoading());
      final result = await repository.deleteRental(event.rentalId);
      result.fold(
        (failure) => emit(RentalsError(failure.message)),
        (_) {
          emit(RentalsInitial()); 
          add(const GetRentalsRequested());
        },
      );
    });

    on<UpdateRentalRequested>((event, emit) async {
      emit(RentalsLoading());
      final result = await repository.updateRental(event.id, event.data);
      result.fold(
        (failure) => emit(RentalsError(failure.message)),
        (rental) {
          emit(RentalAddedSuccess(rental));
          add(const GetRentalsRequested());
        },
      );
    });
  }
}
