import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../data/model/tax_document.dart';
import '../../../data/datasources/tax/tax_remote_data_source.dart';
import '../../../data/repositories/tax/tax_repository.dart';

class TaxRepositoryImpl implements TaxRepository {
  final TaxRemoteDataSource remoteDataSource;

  TaxRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, void>> uploadTaxDocument({
    required String userId,
    required String filePath,
    required String documentType,
    required double amount,
    required String category,
    String description = '',
  }) async {
    try {
      await remoteDataSource.uploadTaxDocument(
        userId: userId,
        filePath: filePath,
        documentType: documentType,
        amount: amount,
        category: category,
        description: description,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TaxDocument>>> getUserDocuments(
    String userId,
  ) async {
    try {
      final docs = await remoteDataSource.getUserDocuments(userId);
      return Right(docs);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, double>>> getMonthlyTaxSummary(
    String userId,
    DateTime month,
  ) async {
    try {
      final summary = await remoteDataSource.getMonthlyTaxSummary(
        userId,
        month,
      );
      return Right(summary);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
