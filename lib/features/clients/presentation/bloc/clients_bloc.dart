import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/client_entity.dart';
import '../../domain/usecases/get_clients_usecase.dart';
import '../../domain/usecases/add_client_usecase.dart';
import '../../domain/usecases/client_actions_usecases.dart';

// Eventos
abstract class ClientsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadClients extends ClientsEvent {}

class AddClient extends ClientsEvent {
  final Map<String, dynamic> clientData;
  AddClient(this.clientData);
  @override
  List<Object?> get props => [clientData];
}

class UpdateClient extends ClientsEvent {
  final String id;
  final Map<String, dynamic> clientData;
  UpdateClient(this.id, this.clientData);
  @override
  List<Object?> get props => [id, clientData];
}

class DeleteClient extends ClientsEvent {
  final String id;
  DeleteClient(this.id);
  @override
  List<Object?> get props => [id];
}

class SearchClients extends ClientsEvent {
  final String query;
  SearchClients(this.query);
  @override
  List<Object?> get props => [query];
}

class SortClientsAlphabetically extends ClientsEvent {}

// Estados
abstract class ClientsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ClientsInitial extends ClientsState {}
class ClientsLoading extends ClientsState {}
class ClientsLoaded extends ClientsState {
  final List<ClientEntity> clients;
  final List<ClientEntity> filteredClients;
  final bool isSorted;

  ClientsLoaded({
    required this.clients, 
    List<ClientEntity>? filteredClients,
    this.isSorted = false,
  }) : filteredClients = filteredClients ?? clients;

  @override
  List<Object?> get props => [clients, filteredClients, isSorted];
}
class ClientsError extends ClientsState {
  final String message;
  ClientsError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class ClientsBloc extends Bloc<ClientsEvent, ClientsState> {
  final GetClientsUseCase getClientsUseCase;
  final AddClientUseCase addClientUseCase;
  final UpdateClientUseCase updateClientUseCase;
  final DeleteClientUseCase deleteClientUseCase;

  List<ClientEntity> _allClients = [];

  ClientsBloc({
    required this.getClientsUseCase,
    required this.addClientUseCase,
    required this.updateClientUseCase,
    required this.deleteClientUseCase,
  }) : super(ClientsInitial()) {
    
    on<LoadClients>((event, emit) async {
      emit(ClientsLoading());
      final result = await getClientsUseCase.execute();
      result.fold(
        (failure) => emit(ClientsError(failure.message)),
        (clients) {
          _allClients = clients;
          emit(ClientsLoaded(clients: clients));
        },
      );
    });

    on<SearchClients>((event, emit) {
      if (state is ClientsLoaded) {
        final query = event.query.toLowerCase();
        final filtered = _allClients.where((c) {
          return c.name.toLowerCase().contains(query) || 
                 (c.dni?.contains(query) ?? false);
        }).toList();
        emit(ClientsLoaded(clients: _allClients, filteredClients: filtered));
      }
    });

    on<SortClientsAlphabetically>((event, emit) {
      if (state is ClientsLoaded) {
        final s = state as ClientsLoaded;
        final sortedList = List<ClientEntity>.from(s.filteredClients);
        final newIsSorted = !s.isSorted;
        
        sortedList.sort((a, b) {
          if (newIsSorted) {
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          } else {
            return b.name.toLowerCase().compareTo(a.name.toLowerCase());
          }
        });
        
        emit(ClientsLoaded(
          clients: _allClients, 
          filteredClients: sortedList, 
          isSorted: newIsSorted
        ));
      }
    });

    on<AddClient>((event, emit) async {
      final result = await addClientUseCase.execute(event.clientData);
      result.fold(
        (failure) => emit(ClientsError(failure.message)),
        (newClient) {
          _allClients.add(newClient);
          emit(ClientsLoaded(clients: List.from(_allClients)));
        },
      );
    });

    on<UpdateClient>((event, emit) async {
      final result = await updateClientUseCase.execute(event.id, event.clientData);
      result.fold(
        (failure) => emit(ClientsError(failure.message)),
        (updatedClient) {
          final index = _allClients.indexWhere((c) => c.id == event.id);
          if (index != -1) {
            _allClients[index] = updatedClient;
            emit(ClientsLoaded(clients: List.from(_allClients)));
          }
        },
      );
    });

    on<DeleteClient>((event, emit) async {
      final result = await deleteClientUseCase.execute(event.id);
      result.fold(
        (failure) => emit(ClientsError(failure.message)),
        (_) {
          _allClients.removeWhere((c) => c.id == event.id);
          emit(ClientsLoaded(clients: List.from(_allClients)));
        },
      );
    });
  }
}
