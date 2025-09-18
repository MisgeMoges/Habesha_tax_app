import 'package:dartz/dartz.dart';
import 'dart:io';
import '../../../../core/error/failures.dart';
import '../../model/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> signInWithEmailAndPassword(
    String email,
    String password,
  );

  Future<Either<Failure, User>> createUserWithEmailAndPassword(
    String email,
    String password,
    String firstName,
    String lastName,
    String? middleName,
    String memberCategory,
    File profileImage,
  );

  Future<Either<Failure, User>> signInWithGoogle();
  Future<Either<Failure, User>> signInWithApple();
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, void>> resetPassword(String email);
  Stream<Either<Failure, User?>> get authStateChanges;

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    String? middleName,
    required String memberCategory,
    required String maritalStatus,
    required String gender,
    required String membershipType,
    String? christeningName,
    String? spiritualFatherName,
    String? profilePicture,
    String? dateOfBirth,
    String? nationality,
    String? address,
    String? postcode,
    String? mobileNumber,
    String? emergencyContactName,
    String? emergencyContactRelation,
    String? emergencyContactPhone,
    bool? membershipCommitmentConfirmed,
    bool? consentContactChurch,
    bool? consentDataUse,
    String? membershipApplicationSignature,
    Timestamp? membershipApplicationDate,
    Timestamp? applicationReceivedDate,
  });
}
