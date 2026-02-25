import 'dart:convert';
import '../../model/user.dart';
import '../../../core/config/frappe_config.dart';
import '../../../core/services/frappe_client.dart';

abstract class AuthRemoteDataSource {
  Stream<User?> get authStateChanges;
  Future<User> signInWithEmailAndPassword(String email, String password);
  Future<User> createUserWithEmailAndPassword(
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
  );
  Future<User> signInWithGoogle();
  Future<User> signInWithApple();
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Future<void> updatePassword({
    required String email,
    required String newPassword,
    String? oldPassword,
    String? resetKey,
  });
  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String mobileNumber,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FrappeClient _client;
  User? _cachedUser;

  AuthRemoteDataSourceImpl({FrappeClient? client})
    : _client = client ?? FrappeClient();

  @override
  Stream<User?> get authStateChanges =>
      Stream<User?>.fromFuture(_getCurrentUser());

  @override
  Future<User> signInWithEmailAndPassword(String email, String password) async {
    await _client.login(email, password);
    final current = await _getCurrentUser();
    if (current != null) return current;
    final fallback = await _fetchUserByEmail(email);
    if (fallback != null) {
      _cachedUser = fallback;
      return fallback;
    }
    throw Exception('Unable to load user profile after login');
  }

  @override
  Future<User> createUserWithEmailAndPassword(
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
    final trimmedEmail = email.trim();
    final inferredUsername = trimmedEmail.contains('@')
        ? trimmedEmail.split('@').first
        : trimmedEmail;
    final fullName = '$firstName ${lastName}'.trim();

    final userPayload = <String, dynamic>{
      'email': trimmedEmail,
      'first_name': firstName,
      'last_name': lastName,
      'full_name': fullName,
      'username': inferredUsername,
      'mobile_no': mobileNumber,
      'phone_number': mobileNumber,
      'language': 'en',
      'time_zone': 'UTC',
      'country': country,
      'user_category': userCategory,
      'password': password,
    };

    final clientPayload = <String, dynamic>{
      'business_type': businessType,
      'status': businessStatus,
      'tin_number': tinNumber,
      'tax_category': taxCategory,
      'address_line_1': addressLine1,
      'address_line_2': '',
      'city': city,
      'state': state,
    };

    final response = await _client.post(
      '/api/method/${FrappeConfig.registerClientUserMethod}',
      body: {'user_data': userPayload, 'client_data': clientPayload},
    );
    print('Registration response: $response');
    final message = response['message'];
    if (message is Map<String, dynamic> && message['success'] == false) {
      throw Exception(message['message']?.toString() ?? 'Registration failed');
    }
    if (response['success'] == false) {
      throw Exception(response['message']?.toString() ?? 'Registration failed');
    }

    await _client.login(trimmedEmail, password);
    final current = await _getCurrentUser();
    if (current != null) {
      _cachedUser = current;
      return current;
    }
    final fallback = await _fetchUserByEmail(trimmedEmail);
    if (fallback != null) {
      _cachedUser = fallback;
      return fallback;
    }
    throw Exception('Registration succeeded but user profile not found');
  }

  @override
  Future<User> signInWithGoogle() async {
    throw Exception('Google sign-in is not supported with ERPNext');
  }

  @override
  Future<User> signInWithApple() async {
    throw Exception('Apple sign-in is not supported with ERPNext');
  }

  @override
  Future<void> signOut() async {
    await _client.logout();
    _cachedUser = null;
  }

  @override
  Future<void> resetPassword(String email) async {
    await _client.post(
      '/api/method/frappe.core.doctype.user.user.reset_password',
      body: {'user': email},
    );
  }

  @override
  Future<void> updatePassword({
    required String email,
    required String newPassword,
    String? oldPassword,
    String? resetKey,
  }) async {
    final payload = <String, dynamic>{'email': email, 'password': newPassword};
    if (oldPassword != null && oldPassword.isNotEmpty) {
      payload['old_password'] = oldPassword;
    }
    if (resetKey != null && resetKey.isNotEmpty) {
      payload['reset_key'] = resetKey;
    }

    final response = await _client.post(
      '/api/method/${FrappeConfig.updatePasswordMethod}',
      body: payload,
    );

    final message = response['message'];
    if (response['success'] == false) {
      throw Exception(response['message']?.toString() ?? 'Update failed');
    }
    if (message is Map<String, dynamic> && message['success'] == false) {
      throw Exception(message['message']?.toString() ?? 'Update failed');
    }
  }

  @override
  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String mobileNumber,
  }) async {
    final user = _cachedUser ?? await _getCurrentUser();
    if (user == null) throw Exception('No signed-in user');

    final updateData = <String, dynamic>{
      FrappeConfig.userFirstNameField: firstName,
      FrappeConfig.userLastNameField: lastName,
      FrappeConfig.userMobileNoField: mobileNumber,
    };

    await _client.put(
      '/api/resource/${FrappeConfig.userDoctype}/${user.id}',
      body: {'data': updateData},
    );
  }

  Future<User?> _getCurrentUser() async {
    try {
      final response = await _client.get(
        '/api/method/frappe.auth.get_logged_user',
      );
      final userId = response['message']?.toString();
      if (userId == null || userId.isEmpty) return _cachedUser;

      final userResponse = await _client.get(
        '/api/resource/${FrappeConfig.userDoctype}/$userId',
      );
      final data = userResponse['data'] as Map<String, dynamic>?;
      if (data == null) return _cachedUser;
      _cachedUser = _mapUser(data, fallbackId: userId);
      return _cachedUser;
    } catch (_) {
      return _cachedUser;
    }
  }

  Future<User?> _fetchUserByEmail(String email) async {
    final response = await _client.get(
      '/api/resource/${FrappeConfig.userDoctype}',
      queryParameters: {
        'filters': jsonEncode([
          [FrappeConfig.userEmailField, '=', email],
        ]),
        'limit_page_length': '1',
      },
    );

    final data = response['data'];
    if (data is List && data.isNotEmpty) {
      final record = data.first as Map<String, dynamic>;
      final recordId = record[FrappeConfig.userIdField]?.toString() ?? email;
      final userResponse = await _client.get(
        '/api/resource/${FrappeConfig.userDoctype}/$recordId',
      );
      final userData = userResponse['data'] as Map<String, dynamic>?;
      if (userData == null) return null;
      return _mapUser(userData, fallbackId: recordId);
    }
    return null;
  }

  User _mapUser(Map<String, dynamic> data, {String? fallbackId}) {
    final id =
        data[FrappeConfig.userIdField]?.toString() ??
        fallbackId ??
        data['name']?.toString() ??
        '';
    return User(
      id: id,
      email: data[FrappeConfig.userEmailField]?.toString() ?? '',
      firstName: data[FrappeConfig.userFirstNameField]?.toString() ?? '',
      lastName: data[FrappeConfig.userLastNameField]?.toString() ?? '',
      mobileNumber: data[FrappeConfig.userMobileNoField]?.toString() ?? '',
    );
  }
}
