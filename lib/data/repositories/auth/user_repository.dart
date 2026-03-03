import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../model/user.dart';

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
    String mobileNumber,
    String userCategory,
    String businessType,
    String businessStatus,
    String tinNumber,
    String taxCategory,
    String addressLine1,
    String? addressLine2,
    String? postalCode,
    String city,
    String state,
    String country,
    String? companyName,
    String? companyRegistrationNumber,
    String? vatNumber,
  );

  Future<Either<Failure, User>> signInWithGoogle();
  Future<Either<Failure, User>> signInWithApple();
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, void>> resetPassword(String email);
  Future<Either<Failure, void>> updatePassword({
    required String email,
    required String newPassword,
    String? oldPassword,
    String? resetKey,
  });
  Stream<Either<Failure, User?>> get authStateChanges;

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String mobileNumber,
  });
}
