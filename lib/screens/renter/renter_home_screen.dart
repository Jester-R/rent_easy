import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/notification_bell.dart';
import 'favorite_properties_screen.dart';
import 'my_bookings_screen.dart';
import 'payment_history_screen.dart';
import 'profile_screen.dart';
import 'property_list_screen.dart';

class RenterHomeScreen extends StatefulWidget {
  const RenterHomeScreen({super.key});

  @override
  State<RenterHomeScreen> createState() => _RenterHomeScreenState();
}

class _RenterHomeScreenState extends State<RenterHomeScreen> {
  int _index = 0;
  String? _selectedBookingIdFromNotification;
  String? _selectedPaymentIdFromNotification;

  List<Widget> _buildScreens() {
    return [
      const PropertyListScreen(),
      const FavoritePropertiesScreen(),
      MyBookingsScreen(
        selectedBookingId: _selectedBookingIdFromNotification,
        onSelectionConsumed: () {
          if (!mounted || _selectedBookingIdFromNotification == null) return;
          setState(() => _selectedBookingIdFromNotification = null);
        },
      ),
      PaymentHistoryScreen(
        selectedPaymentId: _selectedPaymentIdFromNotification,
        onSelectionConsumed: () {
          if (!mounted || _selectedPaymentIdFromNotification == null) return;
          setState(() => _selectedPaymentIdFromNotification = null);
        },
      ),
      const RenterProfileScreen(),
    ];
  }

  final _titles = const [
    'Properties',
    'Favorites',
    'My Bookings',
    'Payments',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1000;
    final auth = context.watch<AuthProvider>();
    final renterId = auth.currentUserId ?? '';
    final screens = _buildScreens();
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          NotificationBell(
            userId: renterId,
            role: UserRole.renter,
            onNavigateToBookings: (bookingId) => setState(() {
              _index = 2;
              _selectedBookingIdFromNotification = bookingId;
              _selectedPaymentIdFromNotification = null;
            }),
            onNavigateToPayments: (paymentId) => setState(() {
              _index = 3;
              _selectedPaymentIdFromNotification = paymentId;
            }),
          ),
        ],
      ),
      body: isWide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (value) =>
                      setState(() => _index = value),
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.home_work_outlined),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.favorite_border),
                      label: Text('Favorites'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.payments_outlined),
                      label: Text('Bookings'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.receipt_long_outlined),
                      label: Text('Payments'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person_outline),
                      label: Text('Profile'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: screens[_index]),
              ],
            )
          : screens[_index],
      bottomNavigationBar: isWide
          ? null
          : AppBottomNavBar(
              currentIndex: _index,
              onTap: (value) => setState(() => _index = value),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_work_outlined),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.favorite_border),
                  label: 'Favorites',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.payments_outlined),
                  label: 'Bookings',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long_outlined),
                  label: 'Payments',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  label: 'Profile',
                ),
              ],
            ),
    );
  }
}
