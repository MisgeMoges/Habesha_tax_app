import 'package:cloud_firestore/cloud_firestore.dart';

class TaxDocument {
  final String id;
  final String userId;
  final String documentType; // 'payslip', 'expense', 'revenue'
  final String fileUrl;
  final double amount;
  final String category;
  final DateTime uploadDate;
  final String description;

  TaxDocument({
    required this.id,
    required this.userId,
    required this.documentType,
    required this.fileUrl,
    required this.amount,
    required this.category,
    required this.uploadDate,
    this.description = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'documentType': documentType,
      'fileUrl': fileUrl,
      'amount': amount,
      'category': category,
      'uploadDate': Timestamp.fromDate(uploadDate),
      'description': description,
    };
  }

  factory TaxDocument.fromMap(Map<String, dynamic> map, String docId) {
    return TaxDocument(
      id: docId,
      userId: map['userId'] ?? '',
      documentType: map['documentType'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      category: map['category'] ?? '',
      uploadDate: (map['uploadDate'] as Timestamp).toDate(),
      description: map['description'] ?? '',
    );
  }
}
