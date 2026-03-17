import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

import '../../core/config/frappe_config.dart';

class Booking extends Equatable {
  const Booking({
    required this.id,
    required this.client,
    required this.bookingDate,
    required this.fullName,
    required this.status,
    required this.message,
    required this.adminNote,
    this.creation,
  });

  final String id;
  final String client;
  final DateTime bookingDate;
  final String fullName;
  final String status;
  final String message;
  final String adminNote;
  final DateTime? creation;

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['name']?.toString() ?? '',
      client: json[FrappeConfig.bookingClientField]?.toString() ?? '',
      bookingDate: _parseBookingDateTime(
        json[FrappeConfig.bookingDateField]?.toString(),
        legacyTime: json[FrappeConfig.bookingTimeField]?.toString(),
      ),
      fullName: json[FrappeConfig.bookingFullNameField]?.toString() ?? '',
      status: json[FrappeConfig.bookingStatusField]?.toString() ?? 'Pending',
      message: json[FrappeConfig.bookingMessageField]?.toString() ?? '',
      adminNote: json[FrappeConfig.bookingAdminNoteField]?.toString() ?? '',
      creation: _tryParseDateTime(json['creation']?.toString()),
    );
  }

  DateTime get dateTime => bookingDate;

  String get displayTime => DateFormat.jm().format(bookingDate);

  String get displayDateTime =>
      DateFormat('EEE, MMM d • h:mm a').format(bookingDate);

  static DateTime _parseBookingDateTime(
    String? rawValue, {
    String? legacyTime,
  }) {
    if (rawValue == null || rawValue.trim().isEmpty) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, 9);
    }

    final parsedDateTime = DateTime.tryParse(rawValue)?.toLocal();
    if (parsedDateTime != null) {
      if (_hasTimeComponent(rawValue)) {
        return parsedDateTime;
      }

      final parsedTime = parseTimeOfDay(legacyTime ?? '');
      return DateTime(
        parsedDateTime.year,
        parsedDateTime.month,
        parsedDateTime.day,
        parsedTime.hour,
        parsedTime.minute,
      );
    }

    final parsedDate = DateFormat('yyyy-MM-dd').parse(rawValue);
    final parsedTime = parseTimeOfDay(legacyTime ?? '');
    return DateTime(
      parsedDate.year,
      parsedDate.month,
      parsedDate.day,
      parsedTime.hour,
      parsedTime.minute,
    );
  }

  static DateTime? _tryParseDateTime(String? rawValue) {
    if (rawValue == null || rawValue.trim().isEmpty) return null;
    return DateTime.tryParse(rawValue)?.toLocal();
  }

  static bool _hasTimeComponent(String rawValue) {
    return rawValue.contains('T') || rawValue.contains(' ');
  }

  static TimeOfDayValue parseTimeOfDay(String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty) {
      return const TimeOfDayValue(hour: 9, minute: 0);
    }

    final segments = value.split(':');
    if (segments.length < 2) {
      return const TimeOfDayValue(hour: 9, minute: 0);
    }

    final hour = int.tryParse(segments[0]) ?? 9;
    final minute = int.tryParse(segments[1]) ?? 0;
    return TimeOfDayValue(hour: hour, minute: minute);
  }

  @override
  List<Object?> get props => [
    id,
    client,
    bookingDate,
    fullName,
    status,
    message,
    adminNote,
    creation,
  ];
}

class TimeOfDayValue {
  const TimeOfDayValue({required this.hour, required this.minute});

  final int hour;
  final int minute;
}
