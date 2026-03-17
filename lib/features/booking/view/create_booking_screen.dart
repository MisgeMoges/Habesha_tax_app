import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_color.dart';
import '../../../core/utils/user_friendly_error.dart';
import '../../../data/model/booking.dart';
import '../../../features/auth/bloc/auth_bloc.dart';
import '../../../features/auth/bloc/auth_state.dart';
import '../services/booking_service.dart';

class CreateBookingScreen extends StatefulWidget {
  const CreateBookingScreen({super.key, this.initialDate, this.booking});

  final DateTime? initialDate;
  final Booking? booking;

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  final BookingService _bookingService = BookingService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _messageController = TextEditingController();
  final DateFormat _dateTimeFormatter = DateFormat('EEE, MMM d, yyyy • h:mm a');

  late DateTime _selectedDateTime;
  bool _submitting = false;

  bool get _isEditMode => widget.booking != null;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final initialDate =
        widget.booking?.bookingDate ??
        widget.initialDate ??
        now.add(const Duration(hours: 1));
    _selectedDateTime = DateTime(
      initialDate.year,
      initialDate.month,
      initialDate.day,
      initialDate.hour,
      initialDate.minute,
    );
    _messageController.text = widget.booking?.message ?? '';
    if (_selectedDateTime.isBefore(now)) {
      _selectedDateTime = DateTime(now.year, now.month, now.day, now.hour + 1);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime.isBefore(now) ? now : _selectedDateTime,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    setState(() {
      _selectedDateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _selectedDateTime.hour,
        _selectedDateTime.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _selectedDateTime.hour,
        minute: _selectedDateTime.minute,
      ),
    );
    if (picked == null) return;
    setState(() {
      _selectedDateTime = DateTime(
        _selectedDateTime.year,
        _selectedDateTime.month,
        _selectedDateTime.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in again to create a booking.'),
        ),
      );
      return;
    }

    if (_selectedDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a future date and time.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      if (_isEditMode) {
        await _bookingService.updateBooking(
          booking: widget.booking!,
          bookingDateTime: _selectedDateTime,
          message: _messageController.text,
        );
      } else {
        await _bookingService.createBooking(
          userEmail: authState.user.email,
          fallbackFullName: authState.user.fullName,
          bookingDateTime: _selectedDateTime,
          message: _messageController.text,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Booking updated and marked as Reschedule.'
                : 'Booking request sent successfully.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            UserFriendlyError.message(
              error,
              fallback: _isEditMode
                  ? 'Unable to update your booking right now.'
                  : 'Unable to create your booking right now.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final fullName = authState is Authenticated ? authState.user.fullName : '';

    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? 'Edit Booking' : 'New Booking')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _InfoCard(
                title: 'Booked by',
                child: Text(
                  fullName.isEmpty ? 'Current user' : fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _InfoCard(
                title: 'Schedule',
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.event_outlined,
                        color: AppColor.appColor,
                      ),
                      title: Text(_dateTimeFormatter.format(_selectedDateTime)),
                      subtitle: const Text('Booking date and time'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.calendar_month),
                            label: const Text('Change date'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickTime,
                            icon: const Icon(Icons.access_time),
                            label: const Text('Change time'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _InfoCard(
                title: 'Message',
                child: TextFormField(
                  controller: _messageController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText:
                        'Tell the accountant or owner what you want to discuss.',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a message.';
                    }
                    if (value.trim().length < 5) {
                      return 'Please add a little more detail.';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: FilledButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_circle_outline),
          label: Text(
            _submitting
                ? 'Submitting...'
                : _isEditMode
                ? 'Update Booking'
                : 'Confirm Booking',
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColor.appColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColor.subColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
