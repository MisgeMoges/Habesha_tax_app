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
    on<UpdatePasswordRequested>(_onUpdatePasswordRequested);
    on<UpdateProfileRequested>(_onUpdateProfileRequested);

    // Listen to auth state changes
    _authRepository.authStateChanges.listen((Either<Failure, User?> result) {
      add(AuthCheckRequested());
    });
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final result = await _authRepository.authStateChanges.first;
      result.fold(
        (failure) => emit(
          AuthError(
            _friendlyAuthMessage(failure.message, action: 'auth-check'),
          ),
        ),
        (user) {
          if (user != null) {
            emit(Authenticated(user));
          } else {
            emit(Unauthenticated());
          }
        },
      );
    } catch (e) {
      emit(AuthError(_friendlyAuthMessage(e.toString(), action: 'auth-check')));
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
      (failure) => emit(
        AuthError(_friendlyAuthMessage(failure.message, action: 'sign-in')),
      ),
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
      event.mobileNumber,
      event.userCategory,
      event.businessType,
      event.businessStatus,
      event.tinNumber,
      event.taxCategory,
      event.addressLine1,
      event.addressLine2,
      event.postalCode,
      event.city,
      event.state,
      event.country,
      event.companyName,
      event.companyLogoPath,
      event.companyRegistrationNumber,
      event.vatNumber,
    );
    result.fold(
      (failure) => emit(
        AuthError(_friendlyAuthMessage(failure.message, action: 'sign-up')),
      ),
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
      (failure) => emit(
        AuthError(
          _friendlyAuthMessage(failure.message, action: 'google-sign-in'),
        ),
      ),
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
      (failure) => emit(
        AuthError(
          _friendlyAuthMessage(failure.message, action: 'apple-sign-in'),
        ),
      ),
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
      (failure) => emit(
        AuthError(_friendlyAuthMessage(failure.message, action: 'sign-out')),
      ),
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
      (failure) => emit(
        AuthError(
          _friendlyAuthMessage(failure.message, action: 'reset-password'),
        ),
      ),
      (_) => emit(Unauthenticated()),
    );
  }

  Future<void> _onUpdatePasswordRequested(
    UpdatePasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _authRepository.updatePassword(
      email: event.email,
      newPassword: event.newPassword,
      oldPassword: event.oldPassword,
      resetKey: event.resetKey,
    );
    result.fold(
      (failure) => emit(
        AuthError(
          _friendlyAuthMessage(failure.message, action: 'update-password'),
        ),
      ),
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
      mobileNumber: event.mobileNumber,
    );
    final result = await _authRepository.authStateChanges.first;
    result.fold(
      (failure) => emit(
        AuthError(
          _friendlyAuthMessage(failure.message, action: 'update-profile'),
        ),
      ),
      (user) => emit(Authenticated(user!)),
    );
  }

  String _friendlyAuthMessage(String? raw, {required String action}) {
    final message = (raw ?? '').trim();
    final lower = message.toLowerCase();

    final isInvalidCredentials =
        lower.contains('401') ||
        lower.contains('403') ||
        lower.contains('invalid') ||
        lower.contains('incorrect') ||
        lower.contains('wrong password') ||
        lower.contains('authentication failed') ||
        lower.contains('login failed');
    if (action == 'sign-in' && isInvalidCredentials) {
      return 'Invalid email or password. Please check your credentials and try again.';
    }

    if (lower.contains('socket') ||
        lower.contains('timeout') ||
        lower.contains('network') ||
        lower.contains('failed host lookup') ||
        lower.contains('connection')) {
      return 'Unable to connect right now. Please check your internet connection and try again.';
    }

    if (lower.contains('500') ||
        lower.contains('502') ||
        lower.contains('503') ||
        lower.contains('504') ||
        lower.contains('frappe request failed')) {
      return 'Our server is temporarily unavailable. Please try again in a moment.';
    }

    if (action == 'sign-up') {
      return 'We could not create your account right now. Please review your details and try again.';
    }

    if (action == 'reset-password' || action == 'update-password') {
      return 'We could not update your password right now. Please try again.';
    }

    if (action == 'google-sign-in' || action == 'apple-sign-in') {
      return 'This sign-in method is currently unavailable. Please use email and password.';
    }

    if (action == 'sign-out') {
      return 'We could not sign you out right now. Please try again.';
    }

    if (action == 'update-profile') {
      return 'We could not update your profile at the moment. Please try again.';
    }

    return 'Something went wrong. Please try again.';
  }
}
