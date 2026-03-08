import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/property_provider.dart';
import '../../utils/date_utils.dart';
import '../../utils/extensions.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/notification_bell.dart';
import 'booking_request_screen.dart';
import 'owner_property_list_screen.dart';
import 'profile_screen.dart';

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  int _index = 0;
  String? _selectedBookingIdFromNotification;

  List<Widget> _buildScreens() {
    return [
      const OwnerDashboardBody(),
      const OwnerPropertyListScreen(),
      BookingRequestScreen(
        selectedBookingId: _selectedBookingIdFromNotification,
        onSelectionConsumed: () {
          if (!mounted || _selectedBookingIdFromNotification == null) return;
          setState(() => _selectedBookingIdFromNotification = null);
        },
      ),
      const OwnerProfileScreen(),
    ];
  }

  final _titles = const ['Dashboard', 'My Properties', 'Bookings', 'Profile'];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1000;
    final screens = _buildScreens();
    final auth = context.watch<AuthProvider>();
    final ownerId = auth.currentUserId ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          NotificationBell(
            userId: ownerId,
            role: UserRole.owner,
            onNavigateToBookings: (bookingId) => setState(() {
              _index = 2;
              _selectedBookingIdFromNotification = bookingId;
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
                      icon: Icon(Icons.dashboard_outlined),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.list_alt_outlined),
                      label: Text('Properties'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.request_page_outlined),
                      label: Text('Bookings'),
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
                  icon: Icon(Icons.dashboard_outlined),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.list_alt_outlined),
                  label: 'Properties',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.request_page_outlined),
                  label: 'Bookings',
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

class OwnerDashboardBody extends StatelessWidget {
  const OwnerDashboardBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, PropertyProvider>(
      builder: (context, auth, propertyProvider, _) {
        final ownerId = auth.currentUserId ?? '';
        final properties = propertyProvider.ownerProperties(ownerId);
        final bookings = propertyProvider.ownerBookings(ownerId);
        final pendingBookings = bookings
            .where((b) => b.status == 'Pending')
            .length;
        final approvedBookings = bookings
            .where((b) => b.status == 'Approved')
            .length;
        final monthlyPotential = properties.fold<double>(
          0,
          (sum, item) => sum + item.pricePerMonth,
        );

        final recent = List.of(bookings)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _heroCard(
              ownerEmail: auth.currentUserId ?? 'owner@renteasy.app',
              pendingBookings: pendingBookings,
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 700;
                if (compact) {
                  return Column(
                    children: [
                      _statCard(
                        title: 'Active Listings',
                        value: '${properties.length}',
                        icon: Icons.apartment_outlined,
                      ),
                      const SizedBox(height: 10),
                      _statCard(
                        title: 'Pending Requests',
                        value: '$pendingBookings',
                        icon: Icons.request_page_outlined,
                      ),
                      const SizedBox(height: 10),
                      _statCard(
                        title: 'Approved Deals',
                        value: '$approvedBookings',
                        icon: Icons.verified_outlined,
                      ),
                      const SizedBox(height: 10),
                      _statCard(
                        title: 'Monthly Potential',
                        value: '${monthlyPotential.toUsd()}/mo',
                        icon: Icons.trending_up,
                      ),
                    ],
                  );
                }

                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _statCard(
                      title: 'Active Listings',
                      value: '${properties.length}',
                      icon: Icons.apartment_outlined,
                      width: 250,
                    ),
                    _statCard(
                      title: 'Pending Requests',
                      value: '$pendingBookings',
                      icon: Icons.request_page_outlined,
                      width: 250,
                    ),
                    _statCard(
                      title: 'Approved Deals',
                      value: '$approvedBookings',
                      icon: Icons.verified_outlined,
                      width: 250,
                    ),
                    _statCard(
                      title: 'Monthly Potential',
                      value: '${monthlyPotential.toUsd()}/mo',
                      icon: Icons.trending_up,
                      width: 250,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Booking Activity',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (recent.isEmpty)
                      const Text('No booking activity yet.')
                    else
                      ...recent
                          .take(4)
                          .map(
                            (booking) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          booking.propertyTitle,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${booking.renterId} • ${AppDateUtils.pretty(booking.createdAt)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _statusPill(booking.status),
                                ],
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _heroCard({required String ownerEmail, required int pendingBookings}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Owner Workspace',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(ownerEmail, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          Text(
            pendingBookings > 0
                ? 'You have $pendingBookings request(s) waiting for action.'
                : 'No pending requests right now. Keep listings updated.',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    double? width,
  }) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8EFE6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primaryDark, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
