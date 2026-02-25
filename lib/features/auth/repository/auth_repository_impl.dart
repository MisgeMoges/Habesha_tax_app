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
    if (await networkInfo.isConnected) {
      yield* remoteDataSource.authStateChanges.asyncMap((user) async {
        if (user == null) {
          return const Right(null);
        }
        return Right(user);
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
    String mobileNumber,
    String userCategory,
    String businessType,
    String businessStatus,
    String tinNumber,
    String taxCategory,
    String addressLine1,
    String city,
    String state,
    String country,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final user = await remoteDataSource.createUserWithEmailAndPassword(
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
  Future<Either<Failure, void>> updatePassword({
    required String email,
    required String newPassword,
    String? oldPassword,
    String? resetKey,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.updatePassword(
          email: email,
          newPassword: newPassword,
          oldPassword: oldPassword,
          resetKey: resetKey,
        );
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
    required String mobileNumber,
  }) async {
    await remoteDataSource.updateProfile(
      firstName: firstName,
      lastName: lastName,
      mobileNumber: mobileNumber,
    );
  }
}
