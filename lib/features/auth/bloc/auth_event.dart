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
  final bool remember;

  const SignInRequested({
    required this.email,
    required this.password,
    this.remember = false,
  });

  @override
  List<Object?> get props => [email, password, remember];
}

class SignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String mobileNumber;
  final String businessType;
  final String businessStatus;
  final String tinNumber;
  final String taxCategory;
  final String addressLine1;
  final String? addressLine2;
  final String postalCode;
  final String city;
  final String state;
  final String country;
  final String? companyName;
  final String? companyLogoPath;
  final String? companyRegistrationNumber;
  final String? vatNumber;

  const SignUpRequested({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.mobileNumber,
    required this.businessType,
    required this.businessStatus,
    required this.tinNumber,
    required this.taxCategory,
    required this.addressLine1,
    this.addressLine2,
    required this.postalCode,
    required this.city,
    required this.state,
    required this.country,
    this.companyName,
    this.companyLogoPath,
    this.companyRegistrationNumber,
    this.vatNumber,
  });

  @override
  List<Object?> get props => [
    email,
    password,
    firstName,
    lastName,
    mobileNumber,
    businessType,
    businessStatus,
    tinNumber,
    taxCategory,
    addressLine1,
    addressLine2,
    postalCode,
    city,
    state,
    country,
    companyName,
    companyLogoPath,
    companyRegistrationNumber,
    vatNumber,
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
