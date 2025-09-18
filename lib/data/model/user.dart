import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String? profilePicture;
  final String memberCategory;
  final String? maritalStatus;
  final String? gender;
  final String? membershipType;
  final String? christeningName;
  final String? spiritualFatherName;
  final String? fcmToken;
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

  // Define all possible member categories
  // static const List<String> validCategories = [
  //   'Clergy',
  //   'Member',
  //   'Priest',
  //   'Deacon',
  //   'Sunday Students Member',
  //   'Elder',
  //   'Youth',
  //   'Children'
  // ];

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.profilePicture,
    this.memberCategory = 'Member',
    this.maritalStatus,
    this.gender,
    this.membershipType = 'Partial',
    this.christeningName,
    this.spiritualFatherName,
    this.fcmToken,
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

  factory User.fromFirebaseUser(auth.User user) {
    final nameParts = user.displayName?.split(' ') ?? ['', ''];
    return User(
      id: user.uid,
      email: user.email ?? '',
      firstName: nameParts.first,
      lastName: nameParts.last,
      profilePicture: user.photoURL,
    );
  }

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('User data is null');

    return User(
      id: doc.id,
      email: data['email']?.toString() ?? '',
      firstName: data['firstName']?.toString() ?? '',
      lastName: data['lastName']?.toString() ?? '',
      middleName: data['middleName']?.toString(),
      profilePicture: data['profilePicture']?.toString(),
      memberCategory: data['memberCategory']?.toString() ?? 'Member',
      maritalStatus: data['maritalStatus']?.toString(),
      gender: data['gender']?.toString(),
      membershipType: data['membershipType']?.toString() ?? 'Partial',
      christeningName: data['christeningName']?.toString(),
      spiritualFatherName: data['spiritualFatherName']?.toString(),
      fcmToken: data['fcmToken']?.toString(),
      dateOfBirth: data['dateOfBirth']?.toString(),
      nationality: data['nationality']?.toString(),
      address: data['address']?.toString(),
      postcode: data['postcode']?.toString(),
      mobileNumber: data['mobileNumber']?.toString(),
      emergencyContactName: data['emergencyContactName']?.toString(),
      emergencyContactRelation: data['emergencyContactRelation']?.toString(),
      emergencyContactPhone: data['emergencyContactPhone']?.toString(),
      membershipCommitmentConfirmed:
          data['membershipCommitmentConfirmed'] as bool?,
      consentContactChurch: data['consentContactChurch'] as bool?,
      consentDataUse: data['consentDataUse'] as bool?,
      membershipApplicationSignature: data['membershipApplicationSignature']
          ?.toString(),
      membershipApplicationDate: data['membershipApplicationDate'] is Timestamp
          ? data['membershipApplicationDate'] as Timestamp
          : null,
      applicationReceivedDate: data['applicationReceivedDate'] is Timestamp
          ? data['applicationReceivedDate'] as Timestamp
          : null,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      middleName: json['middleName']?.toString(),
      profilePicture: json['profilePicture']?.toString(),
      memberCategory: json['memberCategory']?.toString() ?? 'Member',
      maritalStatus: json['maritalStatus']?.toString(),
      gender: json['gender']?.toString(),
      membershipType: json['membershipType']?.toString() ?? 'Partial',
      christeningName: json['christeningName']?.toString(),
      spiritualFatherName: json['spiritualFatherName']?.toString(),
      fcmToken: json['fcmToken']?.toString(),
      dateOfBirth: json['dateOfBirth']?.toString(),
      nationality: json['nationality']?.toString(),
      address: json['address']?.toString(),
      postcode: json['postcode']?.toString(),
      mobileNumber: json['mobileNumber']?.toString(),
      emergencyContactName: json['emergencyContactName']?.toString(),
      emergencyContactRelation: json['emergencyContactRelation']?.toString(),
      emergencyContactPhone: json['emergencyContactPhone']?.toString(),
      membershipCommitmentConfirmed:
          json['membershipCommitmentConfirmed'] as bool?,
      consentContactChurch: json['consentContactChurch'] as bool?,
      consentDataUse: json['consentDataUse'] as bool?,
      membershipApplicationSignature: json['membershipApplicationSignature']
          ?.toString(),
      membershipApplicationDate: json['membershipApplicationDate'] is Timestamp
          ? json['membershipApplicationDate'] as Timestamp
          : null,
      applicationReceivedDate: json['applicationReceivedDate'] is Timestamp
          ? json['applicationReceivedDate'] as Timestamp
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'middleName': middleName ?? '',
    'profilePicture': profilePicture ?? '',
    'memberCategory': memberCategory,
    'maritalStatus': maritalStatus ?? '',
    'gender': gender ?? '',
    'membershipType': membershipType ?? 'Partial',
    'christeningName': christeningName ?? '',
    'spiritualFatherName': spiritualFatherName ?? '',
    'fcmToken': fcmToken ?? '',
    'dateOfBirth': dateOfBirth ?? '',
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

  String get fullName => '$firstName ${middleName ?? ''} $lastName'.trim();
}
