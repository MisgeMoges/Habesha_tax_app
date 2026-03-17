import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/constants/app_color.dart';
import '../../../core/utils/user_friendly_error.dart';
import '../../../data/model/booking.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../services/booking_service.dart';
import 'create_booking_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final BookingService _bookingService = BookingService();
  final DateFormat _dayHeaderFormat = DateFormat('EEEE, MMM d');
  final DateFormat _monthHeaderFormat = DateFormat('MMMM yyyy');

  bool _loading = false;
  String? _error;
  List<Booking> _bookings = const [];
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _focusedDay = DateTime(today.year, today.month, today.day);
    _selectedDay = _focusedDay;
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      setState(() {
        _error = 'Please log in to view bookings.';
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _bookingService.fetchBookings(
        userEmail: authState.user.email,
        fallbackFullName: authState.user.fullName,
      );
      if (!mounted) return;
      setState(() => _bookings = items);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error = UserFriendlyError.message(
          error,
          fallback: 'Unable to load your bookings right now.',
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Booking> _bookingsForDay(DateTime day) {
    return _bookings
        .where((booking) => isSameDay(booking.bookingDate, day))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  Future<void> _openCreateBooking([DateTime? initialDate]) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            CreateBookingScreen(initialDate: initialDate ?? _selectedDay),
      ),
    );
    if (created == true) {
      await _loadBookings();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Booking list updated.')));
    }
  }

  Future<void> _openEditBooking(Booking booking) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CreateBookingScreen(booking: booking)),
    );
    if (updated == true) {
      await _loadBookings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking updated successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedBookings = _bookingsForDay(_selectedDay);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('Bookings'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadBookings,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadBookings,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 16),
            _buildCalendarCard(),
            const SizedBox(height: 16),
            Text(
              _dayHeaderFormat.format(_selectedDay),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              _buildErrorCard()
            else if (selectedBookings.isEmpty)
              _buildEmptyDayState()
            else
              ...selectedBookings.map(_buildBookingCard),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateBooking(_selectedDay),
        backgroundColor: AppColor.appColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alert_outlined),
        label: const Text('Book Now'),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final upcoming =
        _bookings
            .where((booking) => !booking.bookingDate.isBefore(DateTime.now()))
            .toList()
          ..sort((a, b) => a.bookingDate.compareTo(b.bookingDate));
    final nextBooking = upcoming.isNotEmpty ? upcoming.first : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF17494D), Color(0xFF2A7B80)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Track your meetings',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            nextBooking == null
                ? 'No upcoming booking yet'
                : 'Next: ${nextBooking.displayDateTime}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            nextBooking?.message ??
                'Choose a date and send a message to request time with the admin or owner.',
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              _monthHeaderFormat.format(_focusedDay),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          TableCalendar<Booking>(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _bookingsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppColor.appColor.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppColor.appColor,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Color(0xFFE58E26),
                shape: BoxShape.circle,
              ),
            ),
            headerVisible: false,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = DateTime(
                  selectedDay.year,
                  selectedDay.month,
                  selectedDay.day,
                );
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() => _focusedDay = focusedDay);
            },
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: const [
              _LegendItem(color: Color(0xFFE58E26), label: 'Has booking'),
              _LegendItem(color: AppColor.appColor, label: 'Selected day'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final statusColor = _statusColor(booking.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  booking.status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 18,
                    color: AppColor.subColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    booking.displayTime,
                    style: const TextStyle(
                      color: AppColor.subColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _openEditBooking(booking),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: AppColor.appColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            booking.message,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                size: 18,
                color: AppColor.subColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  booking.fullName.isEmpty
                      ? 'Client booking'
                      : booking.fullName,
                  style: const TextStyle(color: AppColor.subColor),
                ),
              ),
            ],
          ),
          if (booking.adminNote.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FB),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Admin note',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColor.appColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    booking.adminNote,
                    style: const TextStyle(
                      color: AppColor.subColor,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyDayState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.event_available, size: 42, color: AppColor.subColor),
          const SizedBox(height: 12),
          const Text(
            'No booking on this day',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap Book Now to send a new request for this date.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColor.subColor),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _openCreateBooking(_selectedDay),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Create booking'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 42, color: AppColor.error),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Unable to load bookings.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColor.subColor),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _loadBookings,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return AppColor.success;
      case 'completed':
        return Colors.blue;
      case 'reschedule':
      case 'cancelled':
        return AppColor.error;
      default:
        return const Color(0xFFE58E26);
    }
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppColor.subColor)),
      ],
    );
  }
}
