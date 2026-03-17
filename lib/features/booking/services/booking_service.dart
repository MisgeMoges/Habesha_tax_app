import 'dart:convert';

import 'package:intl/intl.dart';

import '../../../core/config/frappe_config.dart';
import '../../../core/services/frappe_client.dart';
import '../../../data/model/booking.dart';

class BookingService {
  BookingService({FrappeClient? client}) : _client = client ?? FrappeClient();

  final FrappeClient _client;
  final DateFormat _dateTimeFormatter = DateFormat('yyyy-MM-dd HH:mm:ss');

  Future<List<Booking>> fetchBookings({
    required String userEmail,
    required String fallbackFullName,
  }) async {
    final clientRecord = await _getClientRecord(
      userEmail: userEmail,
      fallbackFullName: fallbackFullName,
    );

    final response = await _client.get(
      '/api/resource/${FrappeConfig.bookingDoctype}',
      queryParameters: {
        'filters': jsonEncode([
          [FrappeConfig.bookingClientField, '=', clientRecord.id],
        ]),
        'fields': jsonEncode([
          'name',
          FrappeConfig.bookingClientField,
          FrappeConfig.bookingDateField,
          FrappeConfig.bookingFullNameField,
          FrappeConfig.bookingStatusField,
          FrappeConfig.bookingMessageField,
          FrappeConfig.bookingAdminNoteField,
          'creation',
        ]),
        'order_by': '${FrappeConfig.bookingDateField} asc',
        'limit_page_length': '200',
      },
    );

    final data = response['data'] ?? response['message'];
    if (data is! List) {
      return const [];
    }

    return data
        .whereType<Map>()
        .map((item) => Booking.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> createBooking({
    required String userEmail,
    required String fallbackFullName,
    required DateTime bookingDateTime,
    required String message,
  }) async {
    final clientRecord = await _getClientRecord(
      userEmail: userEmail,
      fallbackFullName: fallbackFullName,
    );

    await _client.post(
      '/api/resource/${FrappeConfig.bookingDoctype}',
      body: {
        FrappeConfig.bookingClientField: clientRecord.id,
        FrappeConfig.bookingDateField: _dateTimeFormatter.format(
          bookingDateTime,
        ),
        FrappeConfig.bookingFullNameField: clientRecord.fullName,
        FrappeConfig.bookingStatusField: 'Pending',
        FrappeConfig.bookingMessageField: message.trim(),
      },
    );
  }

  Future<void> updateBooking({
    required Booking booking,
    required DateTime bookingDateTime,
    required String message,
  }) async {
    await _client.put(
      '/api/resource/${FrappeConfig.bookingDoctype}/${booking.id}',
      body: {
        'data': {
          FrappeConfig.bookingDateField: _dateTimeFormatter.format(
            bookingDateTime,
          ),
          FrappeConfig.bookingMessageField: message.trim(),
          FrappeConfig.bookingStatusField: 'Reschedule',
          FrappeConfig.bookingFullNameField: booking.fullName,
          FrappeConfig.bookingClientField: booking.client,
        },
      },
    );
  }

  Future<ClientRecord> _getClientRecord({
    required String userEmail,
    required String fallbackFullName,
  }) async {
    final response = await _client.get(
      '/api/resource/${FrappeConfig.clientDoctype}',
      queryParameters: {
        'filters': jsonEncode([
          [FrappeConfig.clientUserIdField, '=', userEmail],
        ]),
        'fields': jsonEncode(['name', FrappeConfig.clientFullNameField]),
        'limit_page_length': '1',
      },
    );

    final data = response['data'] ?? response['message'];
    if (data is! List || data.isEmpty) {
      throw Exception('Client record not found for the logged-in user.');
    }

    final first = Map<String, dynamic>.from(data.first as Map);
    final id = first['name']?.toString() ?? '';
    if (id.isEmpty) {
      throw Exception('Client record not found for the logged-in user.');
    }

    final fullName = first[FrappeConfig.clientFullNameField]?.toString().trim();
    return ClientRecord(
      id: id,
      fullName: (fullName == null || fullName.isEmpty)
          ? fallbackFullName
          : fullName,
    );
  }
}

class ClientRecord {
  const ClientRecord({required this.id, required this.fullName});

  final String id;
  final String fullName;
}
