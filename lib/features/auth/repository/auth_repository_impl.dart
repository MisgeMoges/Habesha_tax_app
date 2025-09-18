import 'package:dartz/dartz.dart';
import 'dart:io';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../data/datasources/auth/auth.dart';
import '../../../../data/repositories/auth/user_repository.dart';
import '../../../../data/model/user.dart';
import '../../../../core/services/cloudinary_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Stream<Either<Failure, User?>> get authStateChanges async* {
    if (await networkInfo.isConnected) {
      yield* remoteDataSource.authStateChanges.asyncMap((user) async {
        if (user == null) {
          return const Right(null);
        }
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          if (!doc.exists) {
            return const Left(AuthFailure('User profile not found'));
          }
          return Right(User.fromFirestore(doc));
        } catch (e) {
          return Left(AuthFailure('Failed to fetch user profile: $e'));
        }
      });
    } else {
      yield const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, User>> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final user = await remoteDataSource.signInWithEmailAndPassword(
          email,
          password,
        );
        return Right(user);
      } catch (e) {
        return Left(AuthFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, User>> createUserWithEmailAndPassword(
    String email,
    String password,
    String firstName,
    String lastName,
    String? middleName,
    String memberCategory,
    File profileImage,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final user = await remoteDataSource.createUserWithEmailAndPassword(
          email,
          password,
          firstName,
          lastName,
          middleName,
          memberCategory,
          profileImage,
        );
        return Right(user);
      } catch (e) {
        return Left(AuthFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    if (await networkInfo.isConnected) {
      try {
        final user = await remoteDataSource.signInWithGoogle();
        return Right(user);
      } catch (e) {
        return Left(AuthFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, User>> signInWithApple() async {
    if (await networkInfo.isConnected) {
      try {
        final user = await remoteDataSource.signInWithApple();
        return Right(user);
      } catch (e) {
        return Left(AuthFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.signOut();
        return const Right(null);
      } catch (e) {
        return Left(AuthFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.resetPassword(email);
        return const Right(null);
      } catch (e) {
        return Left(AuthFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
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
  }) async {
    await remoteDataSource.updateProfile(
      firstName: firstName,
      lastName: lastName,
      middleName: middleName,
      memberCategory: memberCategory,
      maritalStatus: maritalStatus,
      gender: gender,
      membershipType: membershipType,
      christeningName: christeningName,
      spiritualFatherName: spiritualFatherName,
      profilePicture: profilePicture,
      dateOfBirth: dateOfBirth,
      nationality: nationality,
      address: address,
      postcode: postcode,
      mobileNumber: mobileNumber,
      emergencyContactName: emergencyContactName,
      emergencyContactRelation: emergencyContactRelation,
      emergencyContactPhone: emergencyContactPhone,
      membershipCommitmentConfirmed: membershipCommitmentConfirmed,
      consentContactChurch: consentContactChurch,
      consentDataUse: consentDataUse,
      membershipApplicationSignature: membershipApplicationSignature,
      membershipApplicationDate: membershipApplicationDate,
      applicationReceivedDate: applicationReceivedDate,
    );
  }
}
