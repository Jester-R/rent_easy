import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../models/booking.dart';
import '../../utils/date_utils.dart';
import '../../utils/extensions.dart';

class BookingRecordDetailScreen extends StatelessWidget {
  final Booking booking;

  const BookingRecordDetailScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
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
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          _statusPill(booking.status),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _item('Booking ID', booking.id),
                      _item('Property ID', booking.propertyId),
                      _item('Renter ID', booking.renterId),
                      _item('Owner ID', booking.ownerId),
                      _item('Monthly Rent', '${booking.monthlyRent.toUsd()}/month'),
                      _item('Lease Duration', '${booking.leaseMonths} months'),
                      _item(
                        'Move-in Date',
                        booking.moveInDate == null
                            ? 'Not specified'
                            : AppDateUtils.pretty(booking.moveInDate!),
                      ),
                      _item('Requested At', AppDateUtils.pretty(booking.createdAt)),
                      if (booking.paymentId.isNotEmpty)
                        _item('Linked Payment', booking.paymentId),
                    ],
                  ),
                ),
              ),
              if (booking.note.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Renter Message',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(booking.note),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value)),
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
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        status,
        style: TextStyle(color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }
}
