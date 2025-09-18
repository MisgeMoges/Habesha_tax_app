import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../model/tax_document.dart';

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
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  TaxRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : firestore = firestore ?? FirebaseFirestore.instance,
       storage = storage ?? FirebaseStorage.instance;

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
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final storageRef = storage
        .ref()
        .child('tax_documents')
        .child(userId)
        .child(fileName);
    final uploadTask = await storageRef.putFile(file);
    final fileUrl = await uploadTask.ref.getDownloadURL();

    final document = TaxDocument(
      id: '', // Firestore will generate this
      userId: userId,
      documentType: documentType,
      fileUrl: fileUrl,
      amount: amount,
      category: category,
      uploadDate: DateTime.now(),
      description: description,
    );
    await firestore.collection('tax_documents').add(document.toMap());
  }

  @override
  Future<List<TaxDocument>> getUserDocuments(String userId) async {
    final querySnapshot = await firestore
        .collection('tax_documents')
        .where('userId', isEqualTo: userId)
        .orderBy('uploadDate', descending: true)
        .get();
    return querySnapshot.docs
        .map((doc) => TaxDocument.fromMap(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<Map<String, double>> getMonthlyTaxSummary(
    String userId,
    DateTime month,
  ) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);
    final querySnapshot = await firestore
        .collection('tax_documents')
        .where('userId', isEqualTo: userId)
        .where(
          'uploadDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
        )
        .where(
          'uploadDate',
          isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth),
        )
        .get();
    double totalIncome = 0;
    double totalExpenses = 0;
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      if (data['documentType'] == 'payslip' ||
          data['documentType'] == 'revenue') {
        totalIncome += (data['amount'] ?? 0.0).toDouble();
      } else if (data['documentType'] == 'expense') {
        totalExpenses += (data['amount'] ?? 0.0).toDouble();
      }
    }
    return {
      'income': totalIncome,
      'expenses': totalExpenses,
      'taxableIncome': totalIncome - totalExpenses,
    };
  }
}
