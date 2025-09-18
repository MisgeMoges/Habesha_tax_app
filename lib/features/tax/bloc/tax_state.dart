import 'package:equatable/equatable.dart';
import '../../../data/model/tax_document.dart';

abstract class TaxState extends Equatable {
  const TaxState();

  @override
  List<Object?> get props => [];
}

class TaxInitial extends TaxState {}

class TaxLoading extends TaxState {}

class TaxDocumentsLoaded extends TaxState {
  final List<TaxDocument> documents;
  const TaxDocumentsLoaded(this.documents);
  @override
  List<Object?> get props => [documents];
}

class TaxSummaryLoaded extends TaxState {
  final Map<String, double> summary;
  const TaxSummaryLoaded(this.summary);
  @override
  List<Object?> get props => [summary];
}

class TaxError extends TaxState {
  final String message;
  const TaxError(this.message);
  @override
  List<Object?> get props => [message];
}
