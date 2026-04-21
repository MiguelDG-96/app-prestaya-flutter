import 'dart:io';
import 'package:app_prestaya_flutter/core/network/dio_client.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class ExportService {
  final DioClient _dioClient;

  ExportService(this._dioClient);

  Future<void> downloadAndOpenPdf({
    required String type,
    String? category,
    int? month,
    int? year,
  }) async {
    try {
      final queryParams = {
        'type': type,
        if (category != null) 'category': category,
        if (month != null) 'month': month,
        if (year != null) 'year': year,
      };

      final bytes = await _dioClient.downloadBytes('/export/pdf', queryParams);
      
      final dir = await getTemporaryDirectory();
      final fileName = 'reporte_${category ?? "general"}_${type}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${dir.path}/$fileName');
      
      await file.writeAsBytes(bytes);
      await OpenFilex.open(file.path);
    } catch (e) {
      rethrow;
    }
  }
}
