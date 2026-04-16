import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../data/datasources/auth/auth.dart';
import '../../../../data/repositories/auth/user_repository.dart';
import '../../../../data/model/user.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Stream<Either<Failure, User?>> get authStateChanges async* {
    try {
      yield* remoteDataSource.authStateChanges.map((user) {
        if (user == null) {
          return const Right(null);
        }
        return Right(user);
      });
    } catch (e) {
      if (!await networkInfo.isConnected) {
        yield const Left(
          NetworkFailure('No internet or local network connection.'),
        );
      } else {
        yield Left(AuthFailure(e.toString()));
      }
    }
  }

  @override
  Future<Either<Failure, User>> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final user = await remoteDataSource.signInWithEmailAndPassword(
        email,
        password,
      );
      return Right(user);
    } catch (e) {
      if (!await networkInfo.isConnected) {
        return const Left(
          NetworkFailure('No internet or local network connection.'),
        );
      }
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> createUserWithEmailAndPassword(
    String email,
    String password,
    String firstName,
    String lastName,
    String mobileNumber,
    String businessType,
    String businessStatus,
    String tinNumber,
    String taxCategory,
    String addressLine1,
    String? addressLine2,
    String postalCode,
    String city,
    String state,
    String country,
    String? companyName,
    String? companyLogoPath,
    String? companyRegistrationNumber,
    String? vatNumber,
  ) async {
    try {
      final user = await remoteDataSource.createUserWithEmailAndPassword(
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
      );
      return Right(user);
    } catch (e) {
      if (!await networkInfo.isConnected) {
        return const Left(
          NetworkFailure('No internet or local network connection.'),
        );
      }
      return Left(AuthFailure(e.toString()));
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
    try {
      await remoteDataSource.signOut();
      return const Right(null);
    } catch (e) {
      if (!await networkInfo.isConnected) {
        return const Left(
          NetworkFailure('No internet or local network connection.'),
        );
      }
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    try {
      await remoteDataSource.resetPassword(email);
      return const Right(null);
    } catch (e) {
      if (!await networkInfo.isConnected) {
        return const Left(
          NetworkFailure('No internet or local network connection.'),
        );
      }
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updatePassword({
    required String email,
    required String newPassword,
    String? oldPassword,
    String? resetKey,
  }) async {
    try {
      await remoteDataSource.updatePassword(
        email: email,
        newPassword: newPassword,
        oldPassword: oldPassword,
        resetKey: resetKey,
      );
      return const Right(null);
    } catch (e) {
      if (!await networkInfo.isConnected) {
        return const Left(
          NetworkFailure('No internet or local network connection.'),
        );
      }
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String mobileNumber,
  }) async {
    await remoteDataSource.updateProfile(
      firstName: firstName,
      lastName: lastName,
      mobileNumber: mobileNumber,
    );
  }
}
