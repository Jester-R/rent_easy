import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/colors.dart';
import '../../models/booking.dart';
import '../../providers/auth_provider.dart';
import '../../providers/property_provider.dart';
import '../common/booking_record_detail_screen.dart';
import '../../utils/date_utils.dart';
import '../../utils/extensions.dart';

class BookingRequestScreen extends StatefulWidget {
  const BookingRequestScreen({super.key});

  @override
  State<BookingRequestScreen> createState() => _BookingRequestScreenState();
}

class _BookingRequestScreenState extends State<BookingRequestScreen> {
  String _statusFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, PropertyProvider>(
      builder: (context, auth, propertyProvider, _) {
        final ownerId = auth.currentUserId ?? '';
        var bookings = propertyProvider.ownerBookings(ownerId);
        if (_statusFilter != 'All') {
          bookings = bookings.where((e) => e.status == _statusFilter).toList();
        }

        return Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: ['All', 'Pending', 'Approved', 'Rejected', 'Cancelled']
                    .map(
                      (status) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(status),
                          selected: _statusFilter == status,
                          onSelected: (_) => setState(() => _statusFilter = status),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            Expanded(
              child: bookings.isEmpty
                  ? const Center(child: Text('No booking requests yet'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: bookings.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, index) {
                        final booking = bookings[index];
                        final canDecide = booking.status == 'Pending';

                        return Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    BookingRecordDetailScreen(booking: booking),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          booking.propertyTitle,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      _statusPill(booking.status),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text('Renter: ${booking.renterId}'),
                                  Text('Requested: ${AppDateUtils.pretty(booking.createdAt)}'),
                                  Text('Move-in: ${booking.moveInDate == null ? 'Not set' : AppDateUtils.pretty(booking.moveInDate!)}'),
                                  Text('Lease: ${booking.leaseMonths} months'),
                                  Text('Rent: ${booking.monthlyRent.toUsd()}/month'),
                                  if (booking.note.isNotEmpty &&
                                      !['Pending', 'Approved']
                                          .contains(booking.status)) ...[
                                    const SizedBox(height: 6),
                                    Text('Message: ${booking.note}'),
                                  ],
                                  if (canDecide) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () =>
                                                _showRejectConfirmDialog(
                                              context,
                                              booking,
                                              propertyProvider,
                                            ),
                                            icon: const Icon(Icons.close),
                                            label: const Text('Reject'),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: FilledButton.icon(
                                            onPressed: () =>
                                                _showApproveConfirmDialog(
                                              context,
                                              booking,
                                              propertyProvider,
                                            ),
                                            icon: const Icon(Icons.check),
                                            label: const Text('Approve'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  void _showApproveConfirmDialog(
    BuildContext context,
    Booking booking,
    PropertyProvider propertyProvider,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Approve Booking Request?'),
        content: Text(
          'Approve booking from ${booking.renterId}?\n\n'
          'Property: ${booking.propertyTitle}\n'
          'Monthly Rent: \$${booking.monthlyRent.toStringAsFixed(2)}\n'
          'Lease Term: ${booking.leaseMonths} months',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              propertyProvider.updateBookingStatus(
                bookingId: booking.id,
                status: 'Approved',
              );
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.success),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectConfirmDialog(
    BuildContext context,
    Booking booking,
    PropertyProvider propertyProvider,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Booking Request?'),
        content: Text(
          'Reject booking from ${booking.renterId}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Request'),
          ),
          TextButton(
            onPressed: () {
              propertyProvider.updateBookingStatus(
                bookingId: booking.id,
                status: 'Rejected',
              );
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(String status) {
    Color fg = AppColors.textPrimary;
    Color bg = const Color(0xFFE5E7EB);

    if (status == 'Approved') {
      fg = AppColors.success;
      bg = const Color(0xFFD8EFE6);
    } else if (status == 'Rejected' || status == 'Cancelled') {
      fg = AppColors.danger;
      bg = const Color(0xFFFBE4E4);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(30)),
      child: Text(
        status,
        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
