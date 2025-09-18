import 'package:equatable/equatable.dart';

abstract class TaxEvent extends Equatable {
  const TaxEvent();

  @override
  List<Object?> get props => [];
}

class UploadTaxDocumentRequested extends TaxEvent {
  final String filePath;
  final String documentType;
  final double amount;
  final String category;
  final String description;

  const UploadTaxDocumentRequested({
    required this.filePath,
    required this.documentType,
    required this.amount,
    required this.category,
    this.description = '',
  });

  @override
  List<Object?> get props => [
    filePath,
    documentType,
    amount,
    category,
    description,
  ];
}

class FetchTaxDocumentsRequested extends TaxEvent {
  const FetchTaxDocumentsRequested();
}

class FetchTaxSummaryRequested extends TaxEvent {
  final DateTime month;
  const FetchTaxSummaryRequested(this.month);

  @override
  List<Object?> get props => [month];
}
