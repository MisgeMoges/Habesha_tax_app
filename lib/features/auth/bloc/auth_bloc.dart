import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../data/model/user.dart';
import '../../../../data/repositories/auth/user_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<SignInRequested>(_onSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<SignInWithGoogleRequested>(_onSignInWithGoogleRequested);
    on<SignInWithAppleRequested>(_onSignInWithAppleRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<ResetPasswordRequested>(_onResetPasswordRequested);
    on<UpdateProfileRequested>(_onUpdateProfileRequested);

    // Listen to auth state changes
    _authRepository.authStateChanges.listen((Either<Failure, User?> result) {
      result.fold(
        (failure) => emit(AuthError(failure.message ?? 'Authentication error')),
        (user) {
          if (user != null) {
            add(AuthCheckRequested());
          } else {
            emit(Unauthenticated());
          }
        },
      );
    });
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final result = await _authRepository.authStateChanges.first;
      result.fold(
        (failure) => emit(AuthError(failure.message ?? 'Authentication error')),
        (user) {
          if (user != null) {
            emit(Authenticated(user));
          } else {
            emit(Unauthenticated());
          }
        },
      );
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _authRepository.signInWithEmailAndPassword(
      event.email,
      event.password,
    );
    result.fold(
      (failure) => emit(AuthError(failure.message ?? 'Sign in failed')),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> _onSignUpRequested(
    SignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _authRepository.createUserWithEmailAndPassword(
      event.email,
      event.password,
      event.firstName,
      event.lastName,
      event.middleName,
      event.memberCategory,
      event.profileImage,
    );
    result.fold(
      (failure) => emit(AuthError(failure.message ?? 'Sign up failed')),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> _onSignInWithGoogleRequested(
    SignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _authRepository.signInWithGoogle();
    result.fold(
      (failure) => emit(AuthError(failure.message ?? 'Google sign in failed')),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> _onSignInWithAppleRequested(
    SignInWithAppleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _authRepository.signInWithApple();
    result.fold(
      (failure) => emit(AuthError(failure.message ?? 'Apple sign in failed')),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _authRepository.signOut();
    result.fold(
      (failure) => emit(AuthError(failure.message ?? 'Sign out failed')),
      (_) => emit(Unauthenticated()),
    );
  }

  Future<void> _onResetPasswordRequested(
    ResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _authRepository.resetPassword(event.email);
    result.fold(
      (failure) => emit(AuthError(failure.message ?? 'Password reset failed')),
      (_) => emit(Unauthenticated()),
    );
  }

  Future<void> _onUpdateProfileRequested(
    UpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await _authRepository.updateProfile(
      firstName: event.firstName,
      lastName: event.lastName,
      middleName: event.middleName,
      memberCategory: event.memberCategory,
      maritalStatus: event.maritalStatus,
      gender: event.gender,
      membershipType: event.membershipType,
      christeningName: event.christeningName,
      spiritualFatherName: event.spiritualFatherName,
      profilePicture: null, // or pass the correct URL if you have it
      dateOfBirth: event.dateOfBirth,
      nationality: event.nationality,
      address: event.address,
      postcode: event.postcode,
      mobileNumber: event.mobileNumber,
      emergencyContactName: event.emergencyContactName,
      emergencyContactRelation: event.emergencyContactRelation,
      emergencyContactPhone: event.emergencyContactPhone,
      membershipCommitmentConfirmed: event.membershipCommitmentConfirmed,
      consentContactChurch: event.consentContactChurch,
      consentDataUse: event.consentDataUse,
      membershipApplicationSignature: event.membershipApplicationSignature,
      membershipApplicationDate: event.membershipApplicationDate,
      applicationReceivedDate: event.applicationReceivedDate,
    );
    final result = await _authRepository.authStateChanges.first;
    result.fold(
      (failure) => emit(AuthError(failure.message ?? 'Failed to load user')),
      (user) => emit(Authenticated(user!)),
    );
  }
}
