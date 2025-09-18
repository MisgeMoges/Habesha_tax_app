import 'package:equatable/equatable.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final String? middleName;
  final String memberCategory;
  final File profileImage;

  const SignUpRequested({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.memberCategory,
    required this.profileImage,
  });

  @override
  List<Object?> get props => [
    email,
    password,
    firstName,
    lastName,
    middleName,
    memberCategory,
    profileImage,
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

class UpdateProfileRequested extends AuthEvent {
  final String firstName;
  final String lastName;
  final String? middleName;
  final String memberCategory;
  final String maritalStatus;
  final String gender;
  final String membershipType;
  final String? christeningName;
  final String? spiritualFatherName;
  final File? profileImage;
  final String? dateOfBirth;
  final String? nationality;
  final String? address;
  final String? postcode;
  final String? mobileNumber;
  final String? emergencyContactName;
  final String? emergencyContactRelation;
  final String? emergencyContactPhone;
  final bool? membershipCommitmentConfirmed;
  final bool? consentContactChurch;
  final bool? consentDataUse;
  final String? membershipApplicationSignature;
  final Timestamp? membershipApplicationDate;
  final Timestamp? applicationReceivedDate;

  const UpdateProfileRequested({
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.memberCategory,
    required this.maritalStatus,
    required this.gender,
    required this.membershipType,
    this.christeningName,
    this.spiritualFatherName,
    this.profileImage,
    this.dateOfBirth,
    this.nationality,
    this.address,
    this.postcode,
    this.mobileNumber,
    this.emergencyContactName,
    this.emergencyContactRelation,
    this.emergencyContactPhone,
    this.membershipCommitmentConfirmed,
    this.consentContactChurch,
    this.consentDataUse,
    this.membershipApplicationSignature,
    this.membershipApplicationDate,
    this.applicationReceivedDate,
  });

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    middleName,
    memberCategory,
    maritalStatus,
    gender,
    membershipType,
    christeningName,
    spiritualFatherName,
    profileImage,
    dateOfBirth,
    nationality,
    address,
    postcode,
    mobileNumber,
    emergencyContactName,
    emergencyContactRelation,
    emergencyContactPhone,
    membershipCommitmentConfirmed,
    consentContactChurch,
    consentDataUse,
    membershipApplicationSignature,
    membershipApplicationDate,
    applicationReceivedDate,
  ];
}
