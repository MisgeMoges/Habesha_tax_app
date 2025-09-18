import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'dart:io';
import '../../model/user.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/targeted_notification_service.dart';
import '../../../core/services/cloudinary_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
// For BuildContext

abstract class AuthRemoteDataSource {
  Stream<auth.User?> get authStateChanges;
  Future<User> signInWithEmailAndPassword(String email, String password);
  Future<User> createUserWithEmailAndPassword(
    String email,
    String password,
    String firstName,
    String lastName,
    String? middleName,
    String memberCategory,
    File profileImage,
  );
  Future<User> signInWithGoogle();
  Future<User> signInWithApple();
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Future<void> updateFcmToken(String userId, String fcmToken);
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
    // ... implementation ...
  }
}

// Add a typedef for password prompt callback
typedef PasswordPromptCallback = Future<String?> Function(String email);

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final PasswordPromptCallback? passwordPromptCallback;

  AuthRemoteDataSourceImpl({
    auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    this.passwordPromptCallback,
  }) : _firebaseAuth = firebaseAuth ?? auth.FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<auth.User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<void> _saveFcmToken(String userId) async {
    try {
      final fcmToken = await NotificationService.getToken();
      if (fcmToken != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': fcmToken,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        print('FCM token saved for user: $userId');

        // Get user's member category and subscribe to topics
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final memberCategory = userData['memberCategory'] ?? 'Member';

          // Subscribe to topics using targeted notification service
          await TargetedNotificationService.subscribeUserToTopics(
            memberCategory,
          );
        }
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  @override
  Future<User> signInWithEmailAndPassword(String email, String password) async {
    try {
      print('Attempting to sign in with email: $email');
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user!;
      print('Successfully signed in with Firebase Auth');

      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        if (!userDoc.exists) {
          print('User document not found in Firestore');
          // Create a new user document with basic information
          final userData = User(
            id: user.uid,
            email: user.email ?? '',
            firstName: user.displayName?.split(' ').first ?? '',
            lastName: user.displayName?.split(' ').last ?? '',
            profilePicture: user.photoURL,
            memberCategory: 'Member', // Default category
          );

          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(userData.toJson());
          print('Created new user document in Firestore');

          // Save FCM token after creating user
          await _saveFcmToken(user.uid);

          return userData;
        }

        print('Successfully retrieved user document from Firestore');
        final userData = User.fromFirestore(userDoc);

        // Save FCM token after successful sign in
        await _saveFcmToken(user.uid);

        return userData;
      } catch (e) {
        print('Error retrieving/creating user document: $e');
        throw Exception(
          'Failed to retrieve or create user profile: ${e.toString()}',
        );
      }
    } catch (e) {
      print('Error in signInWithEmailAndPassword: $e');
      if (e.toString().contains('user-not-found')) {
        throw Exception('No user found with this email');
      } else if (e.toString().contains('wrong-password')) {
        throw Exception('Incorrect password');
      } else if (e.toString().contains('invalid-email')) {
        throw Exception('Invalid email format');
      } else if (e.toString().contains('user-disabled')) {
        throw Exception('This account has been disabled');
      } else {
        throw Exception('Failed to sign in: ${e.toString()}');
      }
    }
  }

  @override
  Future<User> createUserWithEmailAndPassword(
    String email,
    String password,
    String firstName,
    String lastName,
    String? middleName,
    String memberCategory,
    File profileImage,
  ) async {
    try {
      print('Starting user creation process...');
      print('Email: $email');
      print('First Name: $firstName');
      print('Last Name: $lastName');
      print('Middle Name: $middleName');
      print('Member Category: $memberCategory');

      // Check if email is already in use
      try {
        final methods = await _firebaseAuth.fetchSignInMethodsForEmail(email);
        if (methods.isNotEmpty) {
          print('Email already in use. Methods: $methods');
          throw Exception('An account already exists with this email');
        }
      } catch (e) {
        print('Error checking email: $e');
      }

      print('Creating Firebase Auth user...');
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user!;
      print('Firebase Auth user created successfully with ID: ${user.uid}');

      String? profileImageUrl;
      if (profileImage.path.isNotEmpty && profileImage.path != '') {
        print('Uploading profile image...');
        try {
          final String? imageUrl = await CloudinaryService.uploadImage(
            profileImage,
            folder: 'church_app',
          );
          profileImageUrl = imageUrl;
          print('Profile image uploaded successfully. URL: $profileImageUrl');
        } catch (e) {
          print('Error uploading profile image: $e');
          // Continue without profile image
        }
      }

      // Get FCM token
      final fcmToken = await NotificationService.getToken();

      // Create user data map directly
      final userData = {
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'middleName': middleName ?? '',
        'profilePicture': profileImageUrl ?? '',
        'memberCategory': memberCategory,
        'fcmToken': fcmToken ?? '',
      };

      print('Creating Firestore document...');
      try {
        // First create the document
        await _firestore.collection('users').doc(user.uid).set(userData);
        print('Firestore document created successfully');

        // Then read it back to verify
        final docSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        if (!docSnapshot.exists) {
          throw Exception('Failed to create user document');
        }

        // Create and return the User object
        return User(
          id: user.uid,
          email: email,
          firstName: firstName,
          lastName: lastName,
          middleName: middleName,
          profilePicture: profileImageUrl,
          memberCategory: memberCategory,
          fcmToken: fcmToken,
        );
      } catch (firestoreError) {
        print('Error creating Firestore document: $firestoreError');
        // Clean up Firebase Auth user if Firestore fails
        await user.delete();
        throw Exception(
          'Failed to create user profile in database: ${firestoreError.toString()}',
        );
      }
    } catch (e) {
      print('Error in createUserWithEmailAndPassword: $e');
      // Try to clean up if Firebase Auth user was created
      try {
        final currentUser = _firebaseAuth.currentUser;
        if (currentUser != null) {
          print('Attempting to delete Firebase Auth user due to error...');
          await currentUser.delete();
          print('Successfully deleted Firebase Auth user');
        }
      } catch (deleteError) {
        print('Error deleting Firebase Auth user: $deleteError');
      }

      if (e.toString().contains('email-already-in-use')) {
        throw Exception('An account already exists with this email');
      } else if (e.toString().contains('invalid-email')) {
        throw Exception('Invalid email format');
      } else if (e.toString().contains('weak-password')) {
        throw Exception('Password is too weak');
      } else {
        throw Exception('Failed to create user: ${e.toString()}');
      }
    }
  }

  @override
  Future<User> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign in aborted');
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      final credential = auth.GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      try {
        final userCredential = await _firebaseAuth.signInWithCredential(
          credential,
        );
        final user = userCredential.user!;

        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        if (!userDoc.exists) {
          final userData = User.fromFirebaseUser(user);
          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(userData.toJson());
          await _saveFcmToken(user.uid);
          return userData;
        }

        final userData = User.fromJson(userDoc.data() as Map<String, dynamic>);
        await _saveFcmToken(user.uid);
        return userData;
      } on auth.FirebaseAuthException catch (e) {
        if (e.code == 'account-exists-with-different-credential') {
          final email = e.email;
          final pendingCredential = e.credential;
          if (email != null && passwordPromptCallback != null) {
            // Fetch sign-in methods
            final methods = await _firebaseAuth.fetchSignInMethodsForEmail(
              email,
            );
            if (methods.contains('password')) {
              // Prompt user for password
              final password = await passwordPromptCallback!(email);
              if (password == null || password.isEmpty) {
                throw Exception('Password is required to link accounts.');
              }
              // Sign in with email/password
              final userCredential = await _firebaseAuth
                  .signInWithEmailAndPassword(email: email, password: password);
              // Link Google credential
              await userCredential.user!.linkWithCredential(pendingCredential!);
              // Now return the user data
              final userDoc = await _firestore
                  .collection('users')
                  .doc(userCredential.user!.uid)
                  .get();
              final userData = User.fromJson(
                userDoc.data() as Map<String, dynamic>,
              );
              await _saveFcmToken(userCredential.user!.uid);
              return userData;
            } else {
              throw Exception(
                'Account exists with a different sign-in method.',
              );
            }
          } else {
            throw Exception(
              'Account exists with a different credential, but no password prompt available.',
            );
          }
        } else {
          throw Exception('Failed to sign in with Google: ${e.message}');
        }
      }
    } catch (e) {
      throw Exception('Failed to sign in with Google: ${e.toString()}');
    }
  }

  /// Generate a cryptographically secure random nonce, to be included in a
  /// credential request.
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// Returns the sha256 hash of [input] in hex notation.
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  Future<User> signInWithApple() async {
    try {
      // Check if Apple Sign-In is available
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw Exception('Apple Sign-In is not available on this device');
      }

      // Generate nonce for security
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Request credential for the currently signed in Apple account
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      // Create an `OAuthCredential` from the credential returned by Apple
      final oauthCredential = auth.OAuthProvider(
        "apple.com",
      ).credential(idToken: appleCredential.identityToken, rawNonce: rawNonce);

      // Sign in the user with Firebase
      final userCredential = await _firebaseAuth.signInWithCredential(
        oauthCredential,
      );
      final user = userCredential.user!;

      // Check if user document exists
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        // Create new user document
        String firstName = '';
        String lastName = '';

        // Use Apple's provided name if available, otherwise use Firebase user's display name
        if (appleCredential.givenName != null &&
            appleCredential.familyName != null) {
          firstName = appleCredential.givenName!;
          lastName = appleCredential.familyName!;
        } else if (user.displayName != null) {
          final nameParts = user.displayName!.split(' ');
          firstName = nameParts.isNotEmpty ? nameParts.first : '';
          lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
        }

        final userData = User(
          id: user.uid,
          email: user.email ?? appleCredential.email ?? '',
          firstName: firstName,
          lastName: lastName,
          profilePicture: user.photoURL,
          memberCategory: 'Member', // Default category
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userData.toJson());

        // Save FCM token after creating user
        await _saveFcmToken(user.uid);

        return userData;
      }

      // User already exists, return existing data
      final userData = User.fromJson(userDoc.data() as Map<String, dynamic>);

      // Save FCM token after successful sign in
      await _saveFcmToken(user.uid);

      return userData;
    } on SignInWithAppleAuthorizationException catch (e) {
      switch (e.code) {
        case AuthorizationErrorCode.canceled:
          throw Exception('Apple Sign-In was canceled');
        case AuthorizationErrorCode.failed:
          throw Exception('Apple Sign-In failed');
        case AuthorizationErrorCode.invalidResponse:
          throw Exception('Invalid response from Apple');
        case AuthorizationErrorCode.notHandled:
          throw Exception('Apple Sign-In not handled');
        case AuthorizationErrorCode.unknown:
          throw Exception('Unknown error during Apple Sign-In');
        default:
          throw Exception('Apple Sign-In error: ${e.message}');
      }
    } catch (e) {
      print('Error in signInWithApple: $e');
      throw Exception('Failed to sign in with Apple: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Failed to reset password: ${e.toString()}');
    }
  }

  @override
  Future<void> updateFcmToken(String userId, String fcmToken) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': fcmToken,
      });
    } catch (e) {
      throw Exception('Failed to update FCM token: ${e.toString()}');
    }
  }

  @override
  Future<User> updateProfile({
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
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      final userDocRef = _firestore.collection('users').doc(user.uid);

      final updateData = <String, dynamic>{
        'firstName': firstName,
        'lastName': lastName,
        'middleName': middleName ?? '',
        'memberCategory': memberCategory,
        'maritalStatus': maritalStatus,
        'gender': gender,
        'membershipType': membershipType,
        'christeningName': christeningName ?? '',
        'spiritualFatherName': spiritualFatherName ?? '',
        'profilePicture': profilePicture ?? user.photoURL,
        'dateOfBirth': dateOfBirth,
        'nationality': nationality ?? '',
        'address': address ?? '',
        'postcode': postcode ?? '',
        'mobileNumber': mobileNumber ?? '',
        'emergencyContactName': emergencyContactName ?? '',
        'emergencyContactRelation': emergencyContactRelation ?? '',
        'emergencyContactPhone': emergencyContactPhone ?? '',
        'membershipCommitmentConfirmed': membershipCommitmentConfirmed ?? false,
        'consentContactChurch': consentContactChurch ?? false,
        'consentDataUse': consentDataUse ?? false,
        'membershipApplicationSignature': membershipApplicationSignature ?? '',
        'membershipApplicationDate': membershipApplicationDate,
        'applicationReceivedDate': applicationReceivedDate,
      };

      await userDocRef.update(updateData);
      print('Profile updated successfully for user: ${user.uid}');

      // Re-fetch user data to get updated profile
      final updatedUserDoc = await userDocRef.get();
      if (updatedUserDoc.exists) {
        final updatedUser = User.fromJson(
          updatedUserDoc.data() as Map<String, dynamic>,
        );
        await _saveFcmToken(user.uid); // Re-save FCM token after profile update
        return updatedUser;
      } else {
        throw Exception(
          'Failed to retrieve updated user profile from Firestore',
        );
      }
    } catch (e) {
      print('Error updating profile: $e');
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }
}

Future<void> linkGoogleAccount() async {
  final user = auth.FirebaseAuth.instance.currentUser;
  final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  final googleUser = await googleSignIn.signIn();
  if (googleUser == null) {
    throw Exception('Google sign in aborted');
  }
  final googleAuth = await googleUser.authentication;
  final idToken = googleAuth.idToken;
  final accessToken = googleAuth.accessToken;

  final credential = auth.GoogleAuthProvider.credential(
    accessToken: accessToken,
    idToken: idToken,
  );
  await user!.linkWithCredential(credential);
}

Future<void> linkAppleAccount() async {
  final user = auth.FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception('No user is currently signed in');
  }

  // Check if Apple Sign-In is available
  final isAvailable = await SignInWithApple.isAvailable();
  if (!isAvailable) {
    throw Exception('Apple Sign-In is not available on this device');
  }

  // Generate nonce for security
  const charset =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final random = Random.secure();
  final rawNonce = List.generate(
    32,
    (_) => charset[random.nextInt(charset.length)],
  ).join();
  final nonce = sha256.convert(utf8.encode(rawNonce)).toString();

  // Request credential for the currently signed in Apple account
  final appleCredential = await SignInWithApple.getAppleIDCredential(
    scopes: [
      AppleIDAuthorizationScopes.email,
      AppleIDAuthorizationScopes.fullName,
    ],
    nonce: nonce,
  );

  // Create an `OAuthCredential` from the credential returned by Apple
  final oauthCredential = auth.OAuthProvider(
    "apple.com",
  ).credential(idToken: appleCredential.identityToken, rawNonce: rawNonce);

  // Link the Apple credential to the current user
  await user.linkWithCredential(oauthCredential);
}
