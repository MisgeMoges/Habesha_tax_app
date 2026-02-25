class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String mobileNumber;

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
    required this.mobileNumber,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      mobileNumber: json['mobileNumber']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'mobileNumber': mobileNumber,
  };

  String get fullName => '$firstName $lastName'.trim();
}
