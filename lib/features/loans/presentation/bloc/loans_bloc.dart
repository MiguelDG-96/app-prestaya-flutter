import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/loan_entity.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/repositories/loans_repository.dart';

// Eventos
abstract class LoansEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AddLoanRequested extends LoansEvent {
  final LoanEntity loan;
  AddLoanRequested(this.loan);
  @override
  List<Object?> get props => [loan];
}

class LoadLoansRequested extends LoansEvent {}

class DeleteLoanRequested extends LoansEvent {
  final String loanId;
  DeleteLoanRequested(this.loanId);
  @override
  List<Object?> get props => [loanId];
}

class UpdateLoanRequested extends LoansEvent {
  final String id;
  final Map<String, dynamic> data;
  UpdateLoanRequested(this.id, this.data);
  @override
  List<Object?> get props => [id, data];
}

class AddPaymentRequested extends LoansEvent {
  final PaymentEntity payment;
  AddPaymentRequested(this.payment);
  @override
  List<Object?> get props => [payment];
}

// Estados
abstract class LoansState extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoansInitial extends LoansState {}
class LoansLoading extends LoansState {}
class LoanAddedSuccess extends LoansState {
  final LoanEntity loan;
  LoanAddedSuccess(this.loan);
  @override
  List<Object?> get props => [loan];
}
class PaymentSuccess extends LoansState {}
class LoanDeletedSuccess extends LoansState {}
class LoanUpdatedSuccess extends LoansState {}
class LoansLoaded extends LoansState {
  final List<LoanEntity> loans;
  LoansLoaded(this.loans);
  @override
  List<Object?> get props => [loans];
}
class LoansError extends LoansState {
  final String message;
  LoansError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class LoansBloc extends Bloc<LoansEvent, LoansState> {
  final LoansRepository repository;

  LoansBloc({required this.repository}) : super(LoansInitial()) {
    on<AddLoanRequested>((event, emit) async {
      emit(LoansLoading());
      final result = await repository.addLoan(event.loan);
      result.fold(
        (Failure failure) => emit(LoansError(failure.message)),
        (loan) {
          emit(LoanAddedSuccess(loan));
          add(LoadLoansRequested()); // Refrescar lista tras añadir
        },
      );
    });

    on<LoadLoansRequested>((event, emit) async {
      emit(LoansLoading());
      final result = await repository.getLoans();
      result.fold(
        (Failure failure) => emit(LoansError(failure.message)),
        (loans) => emit(LoansLoaded(loans)),
      );
    });

    on<DeleteLoanRequested>((event, emit) async {
      emit(LoansLoading());
      final result = await repository.deleteLoan(event.loanId);
      result.fold(
        (Failure failure) => emit(LoansError(failure.message)),
        (_) {
          emit(LoanDeletedSuccess());
          add(LoadLoansRequested());
        },
      );
    });

    on<UpdateLoanRequested>((event, emit) async {
      emit(LoansLoading());
      final result = await repository.updateLoan(event.id, event.data);
      result.fold(
        (Failure failure) => emit(LoansError(failure.message)),
        (loan) {
          emit(LoanUpdatedSuccess());
          add(LoadLoansRequested());
        },
      );
    });

    on<AddPaymentRequested>((event, emit) async {
      emit(LoansLoading());
      final result = await repository.addPayment(event.payment);
      result.fold(
        (Failure failure) => emit(LoansError(failure.message)),
        (_) {
          emit(PaymentSuccess());
          add(LoadLoansRequested()); // Refrescar lista automáticamente
        },
      );
    });
  }
}
