import 'package:app_prestaya_flutter/core/network/dio_client.dart';

abstract class StatsRemoteDataSource {
  Future<Map<String, dynamic>> getOverallStats({String filter = 'year'});
  Future<List<Map<String, dynamic>>> getMonthlyStats(int year);
  Future<Map<String, dynamic>> getDailyStats({String filter = 'today'});
  Future<List<Map<String, dynamic>>> getDailyStatsForMonth(int year, int month);
}

class StatsRemoteDataSourceImpl implements StatsRemoteDataSource {
  final DioClient client;

  StatsRemoteDataSourceImpl(this.client);

  @override
  Future<Map<String, dynamic>> getOverallStats({String filter = 'year'}) async {
    final response = await client.get('/stats/overall', queryParameters: {'filter': filter});
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<List<Map<String, dynamic>>> getMonthlyStats(int year) async {
    final response = await client.get('/stats/monthly', queryParameters: {'year': year});
    return (response.data as List).map((e) => e as Map<String, dynamic>).toList();
  }

  @override
  Future<Map<String, dynamic>> getDailyStats({String filter = 'today'}) async {
    final response = await client.get('/stats/daily', queryParameters: {'filter': filter});
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<List<Map<String, dynamic>>> getDailyStatsForMonth(int year, int month) async {
    final response = await client.get('/stats/monthly/daily', queryParameters: {'year': year, 'month': month});
    return (response.data as List).map((e) => e as Map<String, dynamic>).toList();
  }
}
