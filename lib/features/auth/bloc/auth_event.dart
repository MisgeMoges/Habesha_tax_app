import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class SignInRequested extends AuthEvent {
  final String email;
  final String password;

  const SignInRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class SignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String mobileNumber;
  final String userCategory;
  final String businessType;
  final String businessStatus;
  final String tinNumber;
  final String taxCategory;
  final String addressLine1;
  final String city;
  final String state;
  final String country;

  const SignUpRequested({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.mobileNumber,
    required this.userCategory,
    required this.businessType,
    required this.businessStatus,
    required this.tinNumber,
    required this.taxCategory,
    required this.addressLine1,
    required this.city,
    required this.state,
    required this.country,
  });

  @override
  List<Object?> get props => [
    email,
    password,
    firstName,
    lastName,
    mobileNumber,
    userCategory,
    businessType,
    businessStatus,
    tinNumber,
    taxCategory,
    addressLine1,
    city,
    state,
    country,
  ];
}

class SignInWithGoogleRequested extends AuthEvent {}

class SignInWithAppleRequested extends AuthEvent {}

class SignOutRequested extends AuthEvent {}

class ResetPasswordRequested extends AuthEvent {
  final String email;

  const ResetPasswordRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class UpdatePasswordRequested extends AuthEvent {
  final String email;
  final String newPassword;
  final String? oldPassword;
  final String? resetKey;

  const UpdatePasswordRequested({
    required this.email,
    required this.newPassword,
    this.oldPassword,
    this.resetKey,
  });

  @override
  List<Object?> get props => [email, newPassword, oldPassword, resetKey];
}

class UpdateProfileRequested extends AuthEvent {
  final String firstName;
  final String lastName;
  final String mobileNumber;

  const UpdateProfileRequested({
    required this.firstName,
    required this.lastName,
    required this.mobileNumber,
  });

  @override
  List<Object?> get props => [firstName, lastName, mobileNumber];
}
