import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/colors.dart';
import '../../models/booking.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/property_provider.dart';
import '../common/booking_record_detail_screen.dart';
import '../../utils/date_utils.dart';
import '../../utils/extensions.dart';
import 'payment_success_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  String _statusFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, PropertyProvider>(
      builder: (context, auth, propertyProvider, _) {
        final renterId = auth.currentUserId ?? '';
        var bookings = propertyProvider.renterBookings(renterId);

        if (_statusFilter != 'All') {
          bookings = bookings.where((b) => b.status == _statusFilter).toList();
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
                  ? const Center(child: Text('No bookings found'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: bookings.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, index) {
                        final booking = bookings[index];
                        final canCancel = booking.status == 'Pending';
                        final canPay = booking.status == 'Approved' && booking.paymentId.isEmpty;
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
                                  Text('Monthly Rent: ${booking.monthlyRent.toUsd()}'),
                                  Text('Lease Term: ${booking.leaseMonths} months'),
                                  Text(
                                    'Move-in: ${booking.moveInDate == null ? 'Not specified' : AppDateUtils.pretty(booking.moveInDate!)}',
                                  ),
                                  Text('Requested: ${AppDateUtils.pretty(booking.createdAt)}'),
                                  if (booking.note.isNotEmpty &&
                                      !['Pending', 'Approved']
                                          .contains(booking.status)) ...[
                                    const SizedBox(height: 6),
                                    Text('Message: ${booking.note}'),
                                  ],
                                  if (canCancel) ...[
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppColors.danger,
                                        ),
                                        onPressed: () => _showCancelConfirmDialog(
                                          context,
                                          booking,
                                          propertyProvider,
                                        ),
                                        icon: const Icon(Icons.cancel_outlined),
                                        label: const Text('Cancel Request'),
                                      ),
                                    ),
                                  ],
                                  if (canPay) ...[
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: FilledButton.icon(
                                        onPressed: () => _showPayNowDialog(
                                          context,
                                          booking,
                                          propertyProvider,
                                        ),
                                        icon: const Icon(Icons.payments_outlined),
                                        label: const Text('Pay Now'),
                                      ),
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

  void _showCancelConfirmDialog(
    BuildContext context,
    Booking booking,
    PropertyProvider propertyProvider,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Booking Request?'),
        content: const Text(
          'Are you sure you want to cancel this booking request?',
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
                status: 'Cancelled',
              );
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );
  }

  void _showPayNowDialog(
    BuildContext context,
    Booking booking,
    PropertyProvider propertyProvider,
  ) {
    String method = 'ABA Pay (Mock)';
    bool processing = false;
    final auth = context.read<AuthProvider>();
    final paymentProvider = context.read<PaymentProvider>();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Pay Approved Booking'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Property: ${booking.propertyTitle}'),
              Text('Amount: ${booking.monthlyRent.toUsd()}'),
              const SizedBox(height: 10),
              const Text('Payment Method'),
              const SizedBox(height: 6),
              ...const ['ABA Pay (Mock)', 'Wing (Mock)', 'Credit Card (Mock)']
                  .map(
                    (m) => RadioListTile<String>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: m,
                      groupValue: method,
                      onChanged: processing
                          ? null
                          : (value) => setDialogState(() => method = value!),
                      title: Text(m),
                    ),
                  ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: processing ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: processing
                  ? null
                  : () async {
                      setDialogState(() => processing = true);
                      final payment = await paymentProvider.processPayment(
                        propertyId: booking.propertyId,
                        userId: auth.currentUserId ?? booking.renterId,
                        amount: booking.monthlyRent,
                        method: method,
                      );

                      if (payment.status == 'Success') {
                        await propertyProvider.attachPaymentToBooking(
                          bookingId: booking.id,
                          paymentId: payment.id,
                        );
                      }

                      if (!context.mounted) return;
                      Navigator.pop(dialogContext);
                      if (payment.status == 'Success') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PaymentSuccessScreen(payment: payment),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Payment failed. Try again.')),
                        );
                      }
                    },
              child: const Text('Pay'),
            ),
          ],
        ),
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
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        status,
        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
