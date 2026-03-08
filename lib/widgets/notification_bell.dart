import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/colors.dart';
import '../models/booking.dart';
import '../models/payment.dart';
import '../models/property.dart';
import '../providers/auth_provider.dart';
import '../providers/payment_provider.dart';
import '../providers/property_provider.dart';
import '../screens/renter/payment_success_screen.dart';
import '../services/storage_service.dart';
import '../utils/date_utils.dart';
import '../utils/extensions.dart';

class NotificationBell extends StatefulWidget {
  final String userId;
  final UserRole role;
  final ValueChanged<String?>? onNavigateToBookings;
  final ValueChanged<String?>? onNavigateToPayments;

  const NotificationBell({
    super.key,
    required this.userId,
    required this.role,
    this.onNavigateToBookings,
    this.onNavigateToPayments,
  });

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  DateTime _lastSeenAt = DateTime.fromMillisecondsSinceEpoch(0);
  final Set<String> _busyBookingIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadLastSeen();
  }

  @override
  void didUpdateWidget(covariant NotificationBell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId || oldWidget.role != widget.role) {
      _loadLastSeen();
    }
  }

  Future<void> _loadLastSeen() async {
    final raw = StorageService.instance.prefs.getString(_lastSeenKey);
    setState(() {
      _lastSeenAt = raw == null
          ? DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
    });
  }

  String get _lastSeenKey =>
      'notification_last_seen_${widget.role.name}_${widget.userId}';

  List<_AppNotification> _buildNotifications({
    required List<Booking> bookings,
    required List<Payment> payments,
    required List<Property> properties,
  }) {
    final byProperty = <String, Property>{
      for (final property in properties) property.id: property,
    };
    final result = <_AppNotification>[];

    if (widget.role == UserRole.owner) {
      final ownerBookings = bookings.where((b) => b.ownerId == widget.userId);
      for (final booking in ownerBookings) {
        final isPending = booking.status == 'Pending';
        result.add(
          _AppNotification(
            title: isPending ? 'New booking request' : 'Booking update',
            message: isPending
                ? '${booking.renterId} requested ${booking.propertyTitle}'
                : '${booking.renterId} booking is ${booking.status}',
            time: booking.createdAt,
            icon: isPending
                ? Icons.request_page_outlined
                : Icons.event_note_outlined,
            bookingId: booking.id,
            action: isPending ? _NotificationAction.ownerDecision : null,
          ),
        );
      }

      final bookingByPaymentId = <String, Booking>{
        for (final b in bookings)
          if (b.paymentId.isNotEmpty) b.paymentId: b,
      };
      for (final payment in payments.where((p) => p.status == 'Success')) {
        final property = byProperty[payment.propertyId];
        if (property == null || property.ownerId != widget.userId) continue;
        final relatedBooking = bookingByPaymentId[payment.id];
        result.add(
          _AppNotification(
            title: 'Payment received',
            message:
                '${payment.userId} paid ${payment.amount.toUsd()} for ${property.title}',
            time: payment.createdAt,
            icon: Icons.payments_outlined,
            bookingId: relatedBooking?.id,
            paymentId: payment.id,
          ),
        );
      }
    } else {
      final renterBookings = bookings.where(
        (b) =>
            b.renterId == widget.userId &&
            b.status == 'Approved' &&
            b.approvedAt != null,
      );
      for (final booking in renterBookings) {
        final canPay = booking.paymentId.isEmpty;
        result.add(
          _AppNotification(
            title: 'Booking approved',
            message: canPay
                ? 'Owner approved ${booking.propertyTitle}. Pay now to confirm.'
                : 'Owner approved ${booking.propertyTitle}. Payment received.',
            time: booking.approvedAt!,
            icon: Icons.verified_outlined,
            bookingId: booking.id,
            paymentId: booking.paymentId.isEmpty ? null : booking.paymentId,
            action: canPay ? _NotificationAction.renterPayNow : null,
          ),
        );
      }
    }

    result.sort((a, b) => b.time.compareTo(a.time));
    return result;
  }

  Future<void> _openNotificationSheet(
    List<_AppNotification> notifications,
  ) async {
    final now = DateTime.now();
    await StorageService.instance.prefs.setString(
      _lastSeenKey,
      now.toIso8601String(),
    );
    if (mounted) {
      setState(() => _lastSeenAt = now);
    }

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                const ListTile(
                  title: Text(
                    'Notifications',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: notifications.isEmpty
                      ? const Center(child: Text('No notifications yet'))
                      : ListView.separated(
                          itemCount: notifications.length,
                          separatorBuilder: (_, index) =>
                              const Divider(height: 1),
                          itemBuilder: (sheetContext, index) {
                            final item = notifications[index];
                            final isBusy =
                                item.bookingId != null &&
                                _busyBookingIds.contains(item.bookingId!);
                            return InkWell(
                              onTap:
                                  item.bookingId == null &&
                                      item.paymentId == null
                                  ? null
                                  : () => _handleNotificationTap(
                                      sheetContext,
                                      item,
                                    ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Card(
                                  margin: EdgeInsets.zero,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE3F4EE),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Icon(
                                                item.icon,
                                                color: AppColors.primaryDark,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                item.title,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              AppDateUtils.pretty(item.time),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(item.message),
                                        if (item.action != null) ...[
                                          const SizedBox(height: 10),
                                          _buildActionRow(
                                            sheetContext: sheetContext,
                                            item: item,
                                            isBusy: isBusy,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionRow({
    required BuildContext sheetContext,
    required _AppNotification item,
    required bool isBusy,
  }) {
    if (item.bookingId == null) return const SizedBox.shrink();

    if (item.action == _NotificationAction.ownerDecision) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isBusy
                  ? null
                  : () => _handleOwnerDecision(
                      sheetContext: sheetContext,
                      bookingId: item.bookingId!,
                      status: 'Rejected',
                    ),
              icon: const Icon(Icons.close),
              label: const Text('Reject'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton.icon(
              onPressed: isBusy
                  ? null
                  : () => _handleOwnerDecision(
                      sheetContext: sheetContext,
                      bookingId: item.bookingId!,
                      status: 'Approved',
                    ),
              icon: const Icon(Icons.check),
              label: const Text('Approve'),
            ),
          ),
        ],
      );
    }

    if (item.action == _NotificationAction.renterPayNow) {
      return Align(
        alignment: Alignment.centerRight,
        child: FilledButton.icon(
          onPressed: isBusy
              ? null
              : () => _handlePayNow(
                  sheetContext: sheetContext,
                  bookingId: item.bookingId!,
                ),
          icon: const Icon(Icons.payments_outlined),
          label: const Text('Pay Now'),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _handleNotificationTap(
    BuildContext sheetContext,
    _AppNotification item,
  ) {
    Navigator.pop(sheetContext);
    if (widget.role == UserRole.renter && item.paymentId != null) {
      widget.onNavigateToPayments?.call(item.paymentId);
      return;
    }
    if (item.bookingId != null) {
      widget.onNavigateToBookings?.call(item.bookingId);
      return;
    }
    if (item.paymentId != null) {
      widget.onNavigateToPayments?.call(item.paymentId);
    }
  }

  Booking? _findBooking(String bookingId) {
    final propertyProvider = context.read<PropertyProvider>();
    for (final booking in propertyProvider.bookings) {
      if (booking.id == bookingId) return booking;
    }
    return null;
  }

  Future<void> _handleOwnerDecision({
    required BuildContext sheetContext,
    required String bookingId,
    required String status,
  }) async {
    final booking = _findBooking(bookingId);
    if (booking == null || booking.status != 'Pending') return;

    setState(() => _busyBookingIds.add(bookingId));
    await context.read<PropertyProvider>().updateBookingStatus(
      bookingId: bookingId,
      status: status,
    );
    if (!mounted) return;
    setState(() => _busyBookingIds.remove(bookingId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          status == 'Approved'
              ? 'Booking approved. Renter can pay now.'
              : 'Booking rejected.',
        ),
      ),
    );
  }

  Future<void> _handlePayNow({
    required BuildContext sheetContext,
    required String bookingId,
  }) async {
    final booking = _findBooking(bookingId);
    if (booking == null ||
        booking.status != 'Approved' ||
        booking.paymentId.isNotEmpty) {
      return;
    }

    Navigator.pop(sheetContext);
    widget.onNavigateToBookings?.call(bookingId);

    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    _showPayNowDialog(bookingId);
  }

  void _showPayNowDialog(String bookingId) {
    final booking = _findBooking(bookingId);
    if (booking == null ||
        booking.status != 'Approved' ||
        booking.paymentId.isNotEmpty) {
      return;
    }

    String method = 'ABA Pay (Mock)';
    bool processing = false;
    final auth = context.read<AuthProvider>();
    final paymentProvider = context.read<PaymentProvider>();
    final propertyProvider = context.read<PropertyProvider>();

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
              DropdownButtonFormField<String>(
                initialValue: method,
                items:
                    const [
                          'ABA Pay (Mock)',
                          'Wing (Mock)',
                          'Credit Card (Mock)',
                        ]
                        .map(
                          (m) => DropdownMenuItem<String>(
                            value: m,
                            child: Text(m),
                          ),
                        )
                        .toList(),
                onChanged: processing
                    ? null
                    : (value) => setDialogState(() => method = value ?? method),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
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

                      if (!mounted || !dialogContext.mounted) return;
                      Navigator.of(dialogContext).pop();
                      if (payment.status == 'Success') {
                        widget.onNavigateToPayments?.call(payment.id);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PaymentSuccessScreen(payment: payment),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Payment failed. Try again.'),
                          ),
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

  @override
  Widget build(BuildContext context) {
    if (widget.userId.isEmpty) return const SizedBox.shrink();

    return Consumer2<PropertyProvider, PaymentProvider>(
      builder: (context, propertyProvider, paymentProvider, _) {
        final notifications = _buildNotifications(
          bookings: propertyProvider.bookings,
          payments: paymentProvider.payments,
          properties: propertyProvider.properties,
        );
        final unreadCount = notifications
            .where((n) => n.time.isAfter(_lastSeenAt))
            .length;

        return IconButton(
          onPressed: () => _openNotificationSheet(notifications),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_outlined),
              if (unreadCount > 0)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AppNotification {
  final String title;
  final String message;
  final DateTime time;
  final IconData icon;
  final String? bookingId;
  final String? paymentId;
  final _NotificationAction? action;

  const _AppNotification({
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    this.bookingId,
    this.paymentId,
    this.action,
  });
}

enum _NotificationAction { ownerDecision, renterPayNow }
