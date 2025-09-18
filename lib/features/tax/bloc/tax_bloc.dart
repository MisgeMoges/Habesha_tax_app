import 'package:flutter_bloc/flutter_bloc.dart';
import 'tax_event.dart';
import 'tax_state.dart';
import '../../../data/repositories/tax/tax_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import 'package:flutter/material.dart';

class TaxBloc extends Bloc<TaxEvent, TaxState> {
  final TaxRepository taxRepository;
  final AuthBloc authBloc;

  TaxBloc({required this.taxRepository, required this.authBloc})
    : super(TaxInitial()) {
    on<UploadTaxDocumentRequested>(_onUploadTaxDocumentRequested);
    on<FetchTaxDocumentsRequested>(_onFetchTaxDocumentsRequested);
    on<FetchTaxSummaryRequested>(_onFetchTaxSummaryRequested);
  }

  String? get _userId {
    final state = authBloc.state;
    if (state is Authenticated) {
      return state.user.id;
    }
    return null;
  }

  Future<void> _onUploadTaxDocumentRequested(
    UploadTaxDocumentRequested event,
    Emitter<TaxState> emit,
  ) async {
    final userId = _userId;
    if (userId == null) {
      emit(const TaxError('User not authenticated'));
      return;
    }
    emit(TaxLoading());
    final result = await taxRepository.uploadTaxDocument(
      userId: userId,
      filePath: event.filePath,
      documentType: event.documentType,
      amount: event.amount,
      category: event.category,
      description: event.description,
    );
    result.fold(
      (failure) =>
          emit(TaxError(failure.message ?? 'Failed to upload document')),
      (_) => add(const FetchTaxDocumentsRequested()),
    );
  }

  Future<void> _onFetchTaxDocumentsRequested(
    FetchTaxDocumentsRequested event,
    Emitter<TaxState> emit,
  ) async {
    final userId = _userId;
    if (userId == null) {
      emit(const TaxError('User not authenticated'));
      return;
    }
    emit(TaxLoading());
    final result = await taxRepository.getUserDocuments(userId);
    result.fold(
      (failure) =>
          emit(TaxError(failure.message ?? 'Failed to fetch documents')),
      (documents) => emit(TaxDocumentsLoaded(documents)),
    );
  }

  Future<void> _onFetchTaxSummaryRequested(
    FetchTaxSummaryRequested event,
    Emitter<TaxState> emit,
  ) async {
    final userId = _userId;
    if (userId == null) {
      emit(const TaxError('User not authenticated'));
      return;
    }
    emit(TaxLoading());
    final result = await taxRepository.getMonthlyTaxSummary(
      userId,
      event.month,
    );
    result.fold(
      (failure) => emit(TaxError(failure.message ?? 'Failed to fetch summary')),
      (summary) => emit(TaxSummaryLoaded(summary)),
    );
  }
}
