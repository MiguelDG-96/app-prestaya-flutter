import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:app_prestaya_flutter/features/stats/data/repositories/stats_repository_impl.dart';

enum StatsFilter { today, week, month, year }

// Eventos
abstract class StatsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadStatsRequested extends StatsEvent {
  final int year;
  final StatsFilter filter;
  LoadStatsRequested({this.year = 2026, this.filter = StatsFilter.year});
  @override
  List<Object?> get props => [year, filter];
}

// Estados
abstract class StatsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class StatsInitial extends StatsState {}
class StatsLoading extends StatsState {}
class StatsLoaded extends StatsState {
  final Map<String, dynamic> overall;
  final List<Map<String, dynamic>> monthly;
  final Map<String, dynamic> daily;
  final StatsFilter filter;

  StatsLoaded({
    required this.overall,
    required this.monthly,
    required this.daily,
    required this.filter,
  });

  @override
  List<Object?> get props => [overall, monthly, daily, filter];
}
class StatsError extends StatsState {
  final String message;
  StatsError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class StatsBloc extends Bloc<StatsEvent, StatsState> {
  final StatsRepository repository;

  StatsBloc({required this.repository}) : super(StatsInitial()) {
    on<LoadStatsRequested>((event, emit) async {
      emit(StatsLoading());
      
      final filterStr = event.filter.name; 
      final now = DateTime.now();
      
      final overallResult = await repository.getOverallStats(filter: filterStr);
      final dailyResult = await repository.getDailyStats(filter: filterStr);
      
      // Si el filtro es "año", mostramos meses. Si es "mes", "semana" o "hoy", mostramos días del mes.
      dynamic chartResult;
      if (event.filter == StatsFilter.year) {
        chartResult = await repository.getMonthlyStats(event.year);
      } else {
        // Obtenemos los días del mes actual para mayor detalle
        chartResult = await repository.getDailyStatsForMonth(now.year, now.month);
      }

      // Combinamos los resultados
      overallResult.fold(
        (failure) => emit(StatsError(failure.message)),
        (overall) {
          dailyResult.fold(
            (failure) => emit(StatsError(failure.message)),
            (daily) {
              chartResult.fold(
                (failure) => emit(StatsError(failure.message)),
                (chartData) => emit(StatsLoaded(
                  overall: overall,
                  monthly: chartData, // Aquí 'monthly' actuará como los datos para el gráfico de barras (pueden ser días)
                  daily: daily,
                  filter: event.filter,
                )),
              );
            },
          );
        },
      );
    });
  }
}
