import 'package:dartz/dartz.dart';
import '../../model/tax_document.dart';
import '../../../core/error/failures.dart';

abstract class TaxRepository {
  Future<Either<Failure, void>> uploadTaxDocument({
    required String userId,
    required String filePath,
    required String documentType,
    required double amount,
    required String category,
    String description,
  });

  Future<Either<Failure, List<TaxDocument>>> getUserDocuments(String userId);

  Future<Either<Failure, Map<String, double>>> getMonthlyTaxSummary(
    String userId,
    DateTime month,
  );
}
