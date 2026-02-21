import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/colors.dart';
import '../models/booking.dart';
import '../models/payment.dart';
import '../models/property.dart';
import '../providers/auth_provider.dart';
import '../providers/payment_provider.dart';
import '../providers/property_provider.dart';
import '../services/storage_service.dart';
import '../utils/date_utils.dart';
import '../utils/extensions.dart';

class NotificationBell extends StatefulWidget {
  final String userId;
  final UserRole role;

  const NotificationBell({
    super.key,
    required this.userId,
    required this.role,
  });

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  DateTime _lastSeenAt = DateTime.fromMillisecondsSinceEpoch(0);

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

  String get _lastSeenKey => 'notification_last_seen_${widget.role.name}_${widget.userId}';

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
        result.add(
          _AppNotification(
            title: 'New booking request',
            message: '${booking.renterId} requested ${booking.propertyTitle}',
            time: booking.createdAt,
            icon: Icons.request_page_outlined,
          ),
        );
      }

      for (final payment in payments.where((p) => p.status == 'Success')) {
        final property = byProperty[payment.propertyId];
        if (property == null || property.ownerId != widget.userId) continue;
        result.add(
          _AppNotification(
            title: 'Payment received',
            message:
                '${payment.userId} paid ${payment.amount.toUsd()} for ${property.title}',
            time: payment.createdAt,
            icon: Icons.payments_outlined,
          ),
        );
      }
    } else {
      final renterBookings = bookings.where(
        (b) => b.renterId == widget.userId && b.status == 'Approved' && b.approvedAt != null,
      );
      for (final booking in renterBookings) {
        result.add(
          _AppNotification(
            title: 'Booking approved',
            message: 'Owner approved ${booking.propertyTitle}. You can now pay.',
            time: booking.approvedAt!,
            icon: Icons.verified_outlined,
          ),
        );
      }
    }

    result.sort((a, b) => b.time.compareTo(a.time));
    return result;
  }

  Future<void> _openNotificationSheet(List<_AppNotification> notifications) async {
    final now = DateTime.now();
    await StorageService.instance.prefs.setString(_lastSeenKey, now.toIso8601String());
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
                          itemBuilder: (_, index) {
                            final item = notifications[index];
                            return ListTile(
                              leading: Icon(item.icon, color: AppColors.primaryDark),
                              title: Text(item.title),
                              subtitle: Text(
                                '${item.message}\n${AppDateUtils.pretty(item.time)}',
                              ),
                              isThreeLine: true,
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
        final unreadCount =
            notifications.where((n) => n.time.isAfter(_lastSeenAt)).length;

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
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
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

  const _AppNotification({
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
  });
}
