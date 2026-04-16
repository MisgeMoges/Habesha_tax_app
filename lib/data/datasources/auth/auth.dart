import 'dart:convert';
import 'dart:io';
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
  static const String _pendingApprovalCode = 'account_pending_activation';
  static const String _deletedLoginCode = 'account_deleted_or_not_found';
  static const String _deletedRecreateCode = 'account_deleted_cannot_recreate';
  static const String _alreadyExistsCode = 'account_already_exists';

  final FrappeClient _client;
  User? _cachedUser;

  AuthRemoteDataSourceImpl({FrappeClient? client})
    : _client = client ?? FrappeClient();

  @override
  Stream<User?> get authStateChanges =>
      Stream<User?>.fromFuture(_getCurrentUser());

  @override
  Future<User> signInWithEmailAndPassword(String email, String password) async {
    final normalizedEmail = email.trim();

    final preLoginRecord = await _fetchUserRecordByEmail(normalizedEmail);
    if (preLoginRecord != null &&
        !_isUserEnabled(preLoginRecord[FrappeConfig.userEnabledField])) {
      final status = await _fetchClientStatusByEmail(normalizedEmail);
      if (_isDeletedStatus(status)) {
        throw Exception(_deletedLoginCode);
      }
      throw Exception(_pendingApprovalCode);
    }

    await _client.login(email, password);
    final currentRecord = await _getCurrentUserRecord();
    if (currentRecord != null) {
      if (!_isUserEnabled(currentRecord[FrappeConfig.userEnabledField])) {
        await _safeLogout();
        final status = await _fetchClientStatusByEmail(normalizedEmail);
        if (_isDeletedStatus(status)) {
          throw Exception(_deletedLoginCode);
        }
        throw Exception(_pendingApprovalCode);
      }
      final current = _mapUser(
        currentRecord,
        fallbackId: currentRecord[FrappeConfig.userIdField]?.toString(),
      );
      _cachedUser = current;
      return current;
    }

    final fallbackRecord = await _fetchUserRecordByEmail(normalizedEmail);
    if (fallbackRecord != null) {
      if (!_isUserEnabled(fallbackRecord[FrappeConfig.userEnabledField])) {
        await _safeLogout();
        final status = await _fetchClientStatusByEmail(normalizedEmail);
        if (_isDeletedStatus(status)) {
          throw Exception(_deletedLoginCode);
        }
        throw Exception(_pendingApprovalCode);
      }
      final fallback = _mapUser(
        fallbackRecord,
        fallbackId: fallbackRecord[FrappeConfig.userIdField]?.toString(),
      );
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
    final trimmedEmail = email.trim();

    final existingRecord = await _fetchUserRecordByEmail(trimmedEmail);
    if (existingRecord != null) {
      if (!_isUserEnabled(existingRecord[FrappeConfig.userEnabledField])) {
        final status = await _fetchClientStatusByEmail(trimmedEmail);
        if (_isDeletedStatus(status)) {
          throw Exception(_deletedRecreateCode);
        }
        throw Exception(_pendingApprovalCode);
      }
      throw Exception(_alreadyExistsCode);
    }

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
      'password': password,
    };

    String companyLogoUrl = '';
    if (companyLogoPath != null && companyLogoPath.trim().isNotEmpty) {
      final uploadResponse = await _client.uploadFile(
        file: File(companyLogoPath),
      );
      final uploadedFromRoot = uploadResponse['file_url']?.toString();
      final uploadedFromMessage =
          (uploadResponse['message'] is Map<String, dynamic>)
          ? (uploadResponse['message'] as Map<String, dynamic>)['file_url']
                ?.toString()
          : null;
      companyLogoUrl = (uploadedFromRoot ?? uploadedFromMessage ?? '').trim();
    }

    final clientPayload = <String, dynamic>{
      'business_type': businessType,
      'status': businessStatus,
      'tin_number': tinNumber,
      'tax_category': taxCategory,
      'address_line_1': addressLine1,
      'address_line_2': addressLine2?.trim() ?? '',
      'postal_code': postalCode.trim(),
      'city': city,
      'state': state,
      FrappeConfig.clientCompanyNameField: companyName?.trim() ?? '',
      FrappeConfig.clientCompanyLogoField: companyLogoUrl,
      FrappeConfig.clientCompanyRegistrationNumberField:
          companyRegistrationNumber?.trim() ?? '',
      FrappeConfig.clientVatNumberField: vatNumber?.trim() ?? '',
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

    final createdUserRecord = await _fetchUserRecordByEmail(trimmedEmail);
    if (createdUserRecord != null &&
        !_isUserEnabled(createdUserRecord[FrappeConfig.userEnabledField])) {
      await _safeLogout();
      throw Exception(_pendingApprovalCode);
    }

    return signInWithEmailAndPassword(trimmedEmail, password);
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
      final data = await _getCurrentUserRecord();
      if (data == null) return _cachedUser;
      _cachedUser = _mapUser(
        data,
        fallbackId: data[FrappeConfig.userIdField]?.toString(),
      );
      return _cachedUser;
    } catch (_) {
      return _cachedUser;
    }
  }

  Future<Map<String, dynamic>?> _getCurrentUserRecord() async {
    final response = await _client.get(
      '/api/method/frappe.auth.get_logged_user',
      useTokenAuth: false,
    );
    final userId = response['message']?.toString();
    if (userId == null || userId.isEmpty) return null;

    final userResponse = await _client.get(
      '/api/resource/${FrappeConfig.userDoctype}/$userId',
      useTokenAuth: false,
    );
    return userResponse['data'] as Map<String, dynamic>?;
  }

  Future<Map<String, dynamic>?> _fetchUserRecordByEmail(String email) async {
    final response = await _client.get(
      '/api/resource/${FrappeConfig.userDoctype}',
      queryParameters: {
        'filters': jsonEncode([
          [FrappeConfig.userEmailField, '=', email],
        ]),
        'fields': jsonEncode([FrappeConfig.userIdField]),
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
      return userResponse['data'] as Map<String, dynamic>?;
    }
    return null;
  }

  bool _isUserEnabled(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value == 1;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == '1' || normalized == 'true' || normalized == 'yes';
    }
    return false;
  }

  Future<void> _safeLogout() async {
    try {
      await _client.logout();
    } catch (_) {}
  }

  Future<String?> _fetchClientStatusByEmail(String email) async {
    try {
      final response = await _client.get(
        '/api/resource/${FrappeConfig.clientDoctype}',
        queryParameters: {
          'filters': jsonEncode([
            [FrappeConfig.clientUserIdField, '=', email],
          ]),
          'fields': jsonEncode([FrappeConfig.clientStatusField]),
          'limit_page_length': '1',
        },
      );
      final data = response['data'];
      if (data is List && data.isNotEmpty) {
        final row = data.first as Map<String, dynamic>;
        return row[FrappeConfig.clientStatusField]?.toString();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  bool _isDeletedStatus(String? status) {
    final normalized = (status ?? '').trim().toLowerCase();
    return normalized == 'inactive' || normalized == 'deleted';
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
