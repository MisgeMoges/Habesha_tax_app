import '../../../data/model/tax_document.dart';

abstract class TaxRepository {
  Future<void> uploadTaxDocument({
    required String filePath,
    required String documentType,
    required double amount,
    required String category,
    String description = '',
  });

  Future<List<TaxDocument>> getTaxDocuments();

  Future<Map<String, double>> getTaxSummary(DateTime month);
}
