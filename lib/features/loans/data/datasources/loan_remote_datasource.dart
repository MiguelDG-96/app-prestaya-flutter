import 'package:app_prestaya_flutter/core/network/dio_client.dart';
import 'package:app_prestaya_flutter/features/loans/data/models/loan_model.dart';

abstract class LoanRemoteDataSource {
  Future<LoanModel> createLoan({
    required Map<String, dynamic> loanData,
  });
  Future<List<LoanModel>> getLoans();
}

class LoanRemoteDataSourceImpl implements LoanRemoteDataSource {
  final DioClient client;

  LoanRemoteDataSourceImpl(this.client);

  @override
  Future<LoanModel> createLoan({required Map<String, dynamic> loanData}) async {
    try {
      final response = await client.post('/loans', data: loanData);
      return LoanModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<LoanModel>> getLoans() async {
    try {
      final response = await client.get('/loans');
      final list = response.data as List;
      return list.map((e) => LoanModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }
}
