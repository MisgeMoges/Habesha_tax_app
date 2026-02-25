import 'dart:convert';
import 'dart:io';
import '../../model/tax_document.dart';
import '../../../core/config/frappe_config.dart';
import '../../../core/services/frappe_client.dart';

abstract class TaxRemoteDataSource {
  Future<void> uploadTaxDocument({
    required String userId,
    required String filePath,
    required String documentType,
    required double amount,
    required String category,
    String description,
  });

  Future<List<TaxDocument>> getUserDocuments(String userId);

  Future<Map<String, double>> getMonthlyTaxSummary(
    String userId,
    DateTime month,
  );
}

class TaxRemoteDataSourceImpl implements TaxRemoteDataSource {
  final FrappeClient _client;

  TaxRemoteDataSourceImpl({FrappeClient? client})
    : _client = client ?? FrappeClient();

  @override
  Future<void> uploadTaxDocument({
    required String userId,
    required String filePath,
    required String documentType,
    required double amount,
    required String category,
    String description = '',
  }) async {
    final file = File(filePath);
    final uploadResponse = await _client.uploadFile(
      file: file,
      isPrivate: false,
    );
    final message = uploadResponse['message'] as Map<String, dynamic>?;
    final fileUrl = message?['file_url']?.toString();
    if (fileUrl == null || fileUrl.isEmpty) {
      throw Exception('Failed to upload tax document');
    }

    await _client.post(
      '/api/resource/${FrappeConfig.taxDocumentDoctype}',
      body: {
        'data': {
          FrappeConfig.taxUserIdField: userId,
          FrappeConfig.taxDocumentTypeField: documentType,
          FrappeConfig.taxFileUrlField: fileUrl,
          FrappeConfig.taxAmountField: amount,
          FrappeConfig.taxCategoryField: category,
          FrappeConfig.taxUploadDateField: DateTime.now().toIso8601String(),
          FrappeConfig.taxDescriptionField: description,
        },
      },
    );
  }

  @override
  Future<List<TaxDocument>> getUserDocuments(String userId) async {
    final response = await _client.get(
      '/api/resource/${FrappeConfig.taxDocumentDoctype}',
      queryParameters: {
        'filters': jsonEncode([
          [FrappeConfig.taxUserIdField, '=', userId],
        ]),
        'order_by': '${FrappeConfig.taxUploadDateField} desc',
        'fields': jsonEncode([
          'name',
          FrappeConfig.taxUserIdField,
          FrappeConfig.taxDocumentTypeField,
          FrappeConfig.taxFileUrlField,
          FrappeConfig.taxAmountField,
          FrappeConfig.taxCategoryField,
          FrappeConfig.taxUploadDateField,
          FrappeConfig.taxDescriptionField,
        ]),
      },
    );

    final data = response['data'];
    if (data is! List) return [];
    return data
        .map(
          (item) => TaxDocument.fromMap(
            _mapTaxFields(item as Map<String, dynamic>),
            item['name']?.toString() ?? '',
          ),
        )
        .toList();
  }

  @override
  Future<Map<String, double>> getMonthlyTaxSummary(
    String userId,
    DateTime month,
  ) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);
    final response = await _client.get(
      '/api/resource/${FrappeConfig.taxDocumentDoctype}',
      queryParameters: {
        'filters': jsonEncode([
          [FrappeConfig.taxUserIdField, '=', userId],
          [
            FrappeConfig.taxUploadDateField,
            'between',
            [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()],
          ],
        ]),
        'fields': jsonEncode([
          FrappeConfig.taxDocumentTypeField,
          FrappeConfig.taxAmountField,
        ]),
        'limit_page_length': '1000',
      },
    );
    final data = response['data'];
    final documents = data is List ? data : [];
    double totalIncome = 0;
    double totalExpenses = 0;
    for (final doc in documents) {
      final map = doc as Map<String, dynamic>;
      final documentType = map[FrappeConfig.taxDocumentTypeField]?.toString();
      final amount = (map[FrappeConfig.taxAmountField] ?? 0.0).toDouble();
      if (documentType == 'payslip' || documentType == 'revenue') {
        totalIncome += amount;
      } else if (documentType == 'expense') {
        totalExpenses += amount;
      }
    }
    return {
      'income': totalIncome,
      'expenses': totalExpenses,
      'taxableIncome': totalIncome - totalExpenses,
    };
  }

  Map<String, dynamic> _mapTaxFields(Map<String, dynamic> data) {
    return {
      'userId': data[FrappeConfig.taxUserIdField],
      'documentType': data[FrappeConfig.taxDocumentTypeField],
      'fileUrl': data[FrappeConfig.taxFileUrlField],
      'amount': data[FrappeConfig.taxAmountField],
      'category': data[FrappeConfig.taxCategoryField],
      'uploadDate': data[FrappeConfig.taxUploadDateField],
      'description': data[FrappeConfig.taxDescriptionField],
    };
  }
}
