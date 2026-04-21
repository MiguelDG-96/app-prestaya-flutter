import 'package:dartz/dartz.dart';
import 'package:app_prestaya_flutter/core/error/failure.dart';
import 'package:app_prestaya_flutter/features/stats/data/datasources/stats_remote_datasource.dart';
import 'package:dio/dio.dart';

abstract class StatsRepository {
  Future<Either<Failure, Map<String, dynamic>>> getOverallStats({String filter = 'year'});
  Future<Either<Failure, List<Map<String, dynamic>>>> getMonthlyStats(int year);
  Future<Either<Failure, Map<String, dynamic>>> getDailyStats({String filter = 'today'});
  Future<Either<Failure, List<Map<String, dynamic>>>> getDailyStatsForMonth(int year, int month);
}

class StatsRepositoryImpl implements StatsRepository {
  final StatsRemoteDataSource remoteDataSource;

  StatsRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, Map<String, dynamic>>> getOverallStats({String filter = 'year'}) async {
    try {
      final result = await remoteDataSource.getOverallStats(filter: filter);
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?['message'] ?? 'Error al obtener estadísticas generales'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getMonthlyStats(int year) async {
    try {
      final result = await remoteDataSource.getMonthlyStats(year);
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?['message'] ?? 'Error al obtener estadísticas mensuales'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getDailyStats({String filter = 'today'}) async {
    try {
      final result = await remoteDataSource.getDailyStats(filter: filter);
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?['message'] ?? 'Error al obtener estadísticas diarias'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getDailyStatsForMonth(int year, int month) async {
    try {
      final response = await remoteDataSource.getDailyStatsForMonth(year, month);
      return Right(response);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
