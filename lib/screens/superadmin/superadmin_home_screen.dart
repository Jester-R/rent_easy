import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/colors.dart';
import '../../models/booking.dart';
import '../../models/payment.dart';
import '../../models/property.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/property_provider.dart';
import '../../services/storage_service.dart';
import '../../utils/date_utils.dart';
import '../../utils/extensions.dart';
import '../../widgets/bottom_nav_bar.dart';

class SuperAdminHomeScreen extends StatefulWidget {
  const SuperAdminHomeScreen({super.key});

  @override
  State<SuperAdminHomeScreen> createState() => _SuperAdminHomeScreenState();
}

class _SuperAdminHomeScreenState extends State<SuperAdminHomeScreen> {
  int _index = 0;
  int _moreTabIndex = 0;
  final Set<String> _selectedUsers = <String>{};
  final Set<String> _selectedProperties = <String>{};
  final Set<String> _selectedBookings = <String>{};
  final Set<String> _selectedPayments = <String>{};

  final _titles = const ['Superadmin Dashboard', 'Users', 'More', 'Profile'];

  Future<void> _refreshData() async {
    final propertyProvider = context.read<PropertyProvider>();
    final paymentProvider = context.read<PaymentProvider>();
    await propertyProvider.initialize();
    await paymentProvider.initialize();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1000;
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: _buildAppBarActions(),
      ),
      body: Consumer2<PropertyProvider, PaymentProvider>(
        builder: (context, propertyProvider, paymentProvider, _) {
          final properties = propertyProvider.properties;
          final bookings = propertyProvider.bookings;
          final payments = paymentProvider.payments;
          final users = _collectUsers();
          final currentPage = _buildCurrentPage(
            users: users,
            properties: properties,
            bookings: bookings,
            payments: payments,
          );

          if (isWide) {
            return Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (value) =>
                      setState(() => _index = value),
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.admin_panel_settings_outlined),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.group_outlined),
                      label: Text('Users'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.grid_view_outlined),
                      label: Text('More'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person_outline),
                      label: Text('Profile'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: currentPage),
              ],
            );
          }

          return currentPage;
        },
      ),
      bottomNavigationBar: isWide
          ? null
          : AppBottomNavBar(
              currentIndex: _index,
              onTap: (value) => setState(() => _index = value),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.admin_panel_settings_outlined),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.group_outlined),
                  label: 'Users',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.grid_view_outlined),
                  label: 'More',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  label: 'Profile',
                ),
              ],
            ),
    );
  }

  List<Widget> _buildAppBarActions() {
    switch (_index) {
      case 1:
        return [
          if (_selectedUsers.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteSelectedUsers,
            ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: _createUser,
          ),
        ];
      case 2:
        return _buildMoreActions();
      default:
        return const [];
    }
  }

  List<Widget> _buildMoreActions() {
    switch (_moreTabIndex) {
      case 0:
        return [
          if (_selectedProperties.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteSelectedProperties,
            ),
          IconButton(
            icon: const Icon(Icons.add_home_outlined),
            onPressed: _createProperty,
          ),
        ];
      case 1:
        return [
          if (_selectedBookings.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteSelectedBookings,
            ),
          IconButton(
            icon: const Icon(Icons.playlist_add_outlined),
            onPressed: _createBooking,
          ),
        ];
      default:
        return [
          if (_selectedPayments.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteSelectedPayments,
            ),
          IconButton(
            icon: const Icon(Icons.post_add_outlined),
            onPressed: _createPayment,
          ),
        ];
    }
  }

  Widget _buildCurrentPage({
    required List<_AdminUser> users,
    required List<Property> properties,
    required List<Booking> bookings,
    required List<Payment> payments,
  }) {
    switch (_index) {
      case 0:
        return _AdminDashboard(
          usersCount: users.length,
          properties: properties,
          bookings: bookings,
          payments: payments,
        );
      case 1:
        return _UsersPage(
          users: users,
          selected: _selectedUsers,
          onToggle: (id, value) => _toggle(_selectedUsers, id, value),
          onToggleAll: (value) =>
              _toggleAll(_selectedUsers, users.map((e) => e.userId), value),
        );
      case 2:
        return _SuperAdminMorePage(
          initialTab: _moreTabIndex,
          onTabChanged: (value) {
            if (_moreTabIndex == value) return;
            setState(() => _moreTabIndex = value);
          },
          properties: properties,
          selectedProperties: _selectedProperties,
          onToggleProperty: (id, value) =>
              _toggle(_selectedProperties, id, value),
          onToggleAllProperties: (value) => _toggleAll(
            _selectedProperties,
            properties.map((e) => e.id),
            value,
          ),
          bookings: bookings,
          selectedBookings: _selectedBookings,
          onToggleBooking: (id, value) => _toggle(_selectedBookings, id, value),
          onToggleAllBookings: (value) =>
              _toggleAll(_selectedBookings, bookings.map((e) => e.id), value),
          payments: payments,
          selectedPayments: _selectedPayments,
          onTogglePayment: (id, value) => _toggle(_selectedPayments, id, value),
          onToggleAllPayments: (value) =>
              _toggleAll(_selectedPayments, payments.map((e) => e.id), value),
        );
      default:
        return const _SuperAdminProfilePage();
    }
  }

  void _toggle(Set<String> set, String id, bool value) {
    setState(() {
      if (value) {
        set.add(id);
      } else {
        set.remove(id);
      }
    });
  }

  void _toggleAll(Set<String> set, Iterable<String> ids, bool value) {
    setState(() {
      if (value) {
        set
          ..clear()
          ..addAll(ids);
      } else {
        set.clear();
      }
    });
  }

  List<_AdminUser> _collectUsers() {
    final prefs = StorageService.instance.prefs;
    final keys = prefs.getKeys();
    final users = <_AdminUser>[];
    final seen = <String>{};

    for (final key in keys) {
      if (!key.startsWith('user_identity_')) continue;
      final identity = key.substring('user_identity_'.length);
      if (!identity.contains('@')) continue;
      final userId = prefs.getString(key);
      if (userId == null || seen.contains(userId)) continue;
      final username = prefs.getString('user_username_$userId') ?? '';
      final fullName = prefs.getString('user_name_$userId') ?? '';
      final role = prefs.getString('user_role_$userId') ?? 'renter';
      users.add(
        _AdminUser(
          userId: userId,
          username: username,
          fullName: fullName,
          role: role,
        ),
      );
      seen.add(userId);
    }

    users.sort((a, b) => a.userId.compareTo(b.userId));
    return users;
  }

  Future<void> _createUser() async {
    final name = TextEditingController();
    final username = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    String role = 'renter';

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: username,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: email,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: password,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                const SizedBox(height: 8),
                DropdownMenu<String>(
                  key: ValueKey('create-user-role-$role'),
                  label: const Text('Role'),
                  initialSelection: role,
                  enableSearch: true,
                  enableFilter: true,
                  requestFocusOnTap: true,
                  keyboardType: TextInputType.text,
                  expandedInsets: EdgeInsets.zero,
                  onSelected: (v) => setDialogState(() => role = v ?? 'renter'),
                  dropdownMenuEntries: const [
                    DropdownMenuEntry(value: 'renter', label: 'renter'),
                    DropdownMenuEntry(value: 'owner', label: 'owner'),
                    DropdownMenuEntry(value: 'superadmin', label: 'superadmin'),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (created != true) return;
    final normalizedEmail = email.text.trim().toLowerCase();
    final normalizedUsername = username.text.trim().toLowerCase();
    if (normalizedEmail.isEmpty ||
        normalizedUsername.isEmpty ||
        password.text.trim().isEmpty) {
      return;
    }

    final prefs = StorageService.instance.prefs;
    await prefs.setString('user_identity_$normalizedEmail', normalizedEmail);
    await prefs.setString('user_identity_$normalizedUsername', normalizedEmail);
    await prefs.setString('user_username_$normalizedEmail', normalizedUsername);
    await prefs.setString('user_name_$normalizedEmail', name.text.trim());
    await prefs.setString(
      'user_password_$normalizedEmail',
      password.text.trim(),
    );
    await prefs.setString('user_role_$normalizedEmail', role);

    if (mounted) setState(() {});
  }

  Future<void> _editUser(_AdminUser user) async {
    final name = TextEditingController(text: user.fullName);
    final username = TextEditingController(text: user.username);
    final password = TextEditingController();
    String role = user.role;

    final save = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.userId,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: username,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: password,
                  decoration: const InputDecoration(
                    labelText: 'Password (leave blank to keep)',
                  ),
                ),
                const SizedBox(height: 8),
                DropdownMenu<String>(
                  key: ValueKey('edit-user-role-$role'),
                  label: const Text('Role'),
                  initialSelection: role,
                  enableSearch: true,
                  enableFilter: true,
                  requestFocusOnTap: true,
                  keyboardType: TextInputType.text,
                  expandedInsets: EdgeInsets.zero,
                  onSelected: (v) =>
                      setDialogState(() => role = v ?? user.role),
                  dropdownMenuEntries: const [
                    DropdownMenuEntry(value: 'renter', label: 'renter'),
                    DropdownMenuEntry(value: 'owner', label: 'owner'),
                    DropdownMenuEntry(value: 'superadmin', label: 'superadmin'),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (save != true) return;
    final prefs = StorageService.instance.prefs;
    final oldUsername =
        prefs.getString('user_username_${user.userId}') ?? user.username;
    final newUsername = username.text.trim().toLowerCase();

    await prefs.setString('user_name_${user.userId}', name.text.trim());
    await prefs.setString('user_role_${user.userId}', role);
    if (password.text.trim().isNotEmpty) {
      await prefs.setString(
        'user_password_${user.userId}',
        password.text.trim(),
      );
    }
    if (newUsername.isNotEmpty && newUsername != oldUsername) {
      await prefs.remove('user_identity_$oldUsername');
      await prefs.setString('user_identity_$newUsername', user.userId);
      await prefs.setString('user_username_${user.userId}', newUsername);
    }

    if (mounted) setState(() {});
  }

  Future<void> _deleteSelectedUsers() async {
    final prefs = StorageService.instance.prefs;
    final keys = prefs.getKeys().toList();
    for (final userId in _selectedUsers) {
      for (final key in keys) {
        if (key.startsWith('user_identity_') &&
            prefs.getString(key) == userId) {
          await prefs.remove(key);
        }
      }
      await prefs.remove('user_username_$userId');
      await prefs.remove('user_name_$userId');
      await prefs.remove('user_password_$userId');
      await prefs.remove('user_role_$userId');
    }
    setState(() => _selectedUsers.clear());
  }

  Future<void> _showUserDetails(_AdminUser user) async {
    await _showRecordDetails(
      title: 'User Details',
      fields: {
        'User ID': user.userId,
        'Full Name': user.fullName.isEmpty ? '-' : user.fullName,
        'Username': user.username.isEmpty ? '-' : '@${user.username}',
        'Role': user.role,
      },
    );
  }

  Future<void> _createProperty() async {
    final title = TextEditingController();
    final location = TextEditingController();
    final price = TextEditingController();
    final bedrooms = TextEditingController(text: '1');
    final bathrooms = TextEditingController(text: '1');
    final description = TextEditingController();
    final owners = _collectUsers().where((u) => u.role == 'owner').toList();
    if (owners.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No owner accounts found. Create an owner user first.',
            ),
          ),
        );
      }
      return;
    }
    String? selectedOwnerId;
    final ownerOptions = owners
        .map(
          (owner) =>
              _PickerOption(value: owner.userId, label: _userLabel(owner)),
        )
        .toList();

    final create = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Property'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _searchableIdDropdown(
                  key: ValueKey('create-property-owner-$selectedOwnerId'),
                  label: 'Owner',
                  hintText: 'Select Owner',
                  value: selectedOwnerId,
                  options: ownerOptions,
                  onChanged: (v) => setDialogState(() => selectedOwnerId = v),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: location,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: price,
                  decoration: const InputDecoration(labelText: 'Price/Month'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: bedrooms,
                  decoration: const InputDecoration(labelText: 'Bedrooms'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: bathrooms,
                  decoration: const InputDecoration(labelText: 'Bathrooms'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: description,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
    if (create != true) return;
    if (selectedOwnerId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an owner.')),
        );
      }
      return;
    }

    final property = Property(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      ownerId: selectedOwnerId!,
      title: title.text.trim(),
      location: location.text.trim(),
      pricePerMonth: double.tryParse(price.text.trim()) ?? 0,
      bedrooms: int.tryParse(bedrooms.text.trim()) ?? 1,
      bathrooms: int.tryParse(bathrooms.text.trim()) ?? 1,
      description: description.text.trim(),
    );

    await StorageService.instance.propertyStore.put(
      property.id,
      property.toMap(),
    );
    await _refreshData();
  }

  Future<void> _editProperty(Property property) async {
    final title = TextEditingController(text: property.title);
    final location = TextEditingController(text: property.location);
    final price = TextEditingController(
      text: property.pricePerMonth.toString(),
    );
    final bedrooms = TextEditingController(text: property.bedrooms.toString());
    final bathrooms = TextEditingController(
      text: property.bathrooms.toString(),
    );
    final description = TextEditingController(text: property.description);
    final owners = _collectUsers().where((u) => u.role == 'owner').toList();
    var selectedOwnerId = property.ownerId;
    if (!owners.any((u) => u.userId == selectedOwnerId)) {
      owners.insert(
        0,
        _AdminUser(
          userId: selectedOwnerId,
          username: '',
          fullName: 'Current owner',
          role: 'owner',
        ),
      );
    }
    final ownerOptions = owners
        .map(
          (owner) =>
              _PickerOption(value: owner.userId, label: _userLabel(owner)),
        )
        .toList();

    final save = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Property'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _searchableIdDropdown(
                  key: ValueKey('edit-property-owner-$selectedOwnerId'),
                  label: 'Owner',
                  hintText: 'Select Owner',
                  value: selectedOwnerId,
                  options: ownerOptions,
                  onChanged: (v) => setDialogState(
                    () => selectedOwnerId = v ?? selectedOwnerId,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: location,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: price,
                  decoration: const InputDecoration(labelText: 'Price/Month'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: bedrooms,
                  decoration: const InputDecoration(labelText: 'Bedrooms'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: bathrooms,
                  decoration: const InputDecoration(labelText: 'Bathrooms'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: description,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (save != true) return;

    final updated = Property(
      id: property.id,
      ownerId: selectedOwnerId,
      title: title.text.trim(),
      location: location.text.trim(),
      pricePerMonth: double.tryParse(price.text.trim()) ?? 0,
      bedrooms: int.tryParse(bedrooms.text.trim()) ?? 1,
      bathrooms: int.tryParse(bathrooms.text.trim()) ?? 1,
      description: description.text.trim(),
    );
    await StorageService.instance.propertyStore.put(
      updated.id,
      updated.toMap(),
    );
    await _refreshData();
  }

  Future<void> _deleteSelectedProperties() async {
    final box = StorageService.instance.propertyStore;
    for (final id in _selectedProperties) {
      await box.delete(id);
    }
    setState(() => _selectedProperties.clear());
    await _refreshData();
  }

  Future<void> _showPropertyDetails(Property property) async {
    await _showRecordDetails(
      title: 'Property Details',
      fields: {
        'Property ID': property.id,
        'Owner ID': property.ownerId,
        'Title': property.title,
        'Location': property.location,
        'Price/Month': property.pricePerMonth.toUsd(),
        'Bedrooms': '${property.bedrooms}',
        'Bathrooms': '${property.bathrooms}',
        'Description': property.description.isEmpty
            ? '-'
            : property.description,
      },
    );
  }

  Future<void> _createBooking() async {
    final status = TextEditingController(text: 'Pending');
    final monthlyRent = TextEditingController(text: '0');
    final leaseMonths = TextEditingController(text: '12');
    final note = TextEditingController();
    final users = _collectUsers();
    final properties = context.read<PropertyProvider>().properties;
    final renters = users.where((u) => u.role == 'renter').toList();
    final owners = users.where((u) => u.role == 'owner').toList();
    String? selectedPropertyId;
    String selectedPropertyTitle = '';
    String? selectedRenterId;
    String? selectedOwnerId;
    List<_PickerOption> ownerOptions = owners
        .map((u) => _PickerOption(value: u.userId, label: _userLabel(u)))
        .toList();
    final propertyOptions = properties
        .map((p) => _PickerOption(value: p.id, label: '${p.title} (${p.id})'))
        .toList();
    final renterOptions = renters
        .map((u) => _PickerOption(value: u.userId, label: _userLabel(u)))
        .toList();

    final create = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Booking'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _searchableIdDropdown(
                  key: ValueKey('create-booking-property-$selectedPropertyId'),
                  label: 'Property',
                  hintText: 'Select Property',
                  value: selectedPropertyId,
                  options: propertyOptions,
                  onChanged: (v) {
                    Property? selectedProperty;
                    for (final item in properties) {
                      if (item.id == v) {
                        selectedProperty = item;
                        break;
                      }
                    }
                    setDialogState(() {
                      selectedPropertyId = v;
                      selectedPropertyTitle = selectedProperty?.title ?? '';
                      selectedOwnerId = selectedProperty?.ownerId;
                      if (selectedOwnerId != null &&
                          !ownerOptions.any(
                            (option) => option.value == selectedOwnerId,
                          )) {
                        ownerOptions = [
                          _PickerOption(
                            value: selectedOwnerId!,
                            label: selectedOwnerId!,
                          ),
                          ...ownerOptions,
                        ];
                      }
                    });
                  },
                ),
                const SizedBox(height: 8),
                _searchableIdDropdown(
                  key: ValueKey('create-booking-renter-$selectedRenterId'),
                  label: 'Renter',
                  hintText: 'Select Renter',
                  value: selectedRenterId,
                  options: renterOptions,
                  onChanged: (v) => setDialogState(() => selectedRenterId = v),
                ),
                const SizedBox(height: 8),
                _searchableIdDropdown(
                  key: ValueKey('create-booking-owner-$selectedOwnerId'),
                  label: 'Owner',
                  hintText: 'Select Owner',
                  value: selectedOwnerId,
                  options: ownerOptions,
                  onChanged: (v) => setDialogState(() => selectedOwnerId = v),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: monthlyRent,
                  decoration: const InputDecoration(labelText: 'Monthly Rent'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: leaseMonths,
                  decoration: const InputDecoration(labelText: 'Lease Months'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: note,
                  decoration: const InputDecoration(labelText: 'Note'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
    if (create != true) return;
    if (selectedPropertyId == null ||
        selectedRenterId == null ||
        selectedOwnerId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select Property, Renter and Owner.'),
          ),
        );
      }
      return;
    }

    final booking = Booking(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      propertyId: selectedPropertyId!,
      propertyTitle: selectedPropertyTitle,
      renterId: selectedRenterId!,
      ownerId: selectedOwnerId!,
      status: status.text.trim(),
      monthlyRent: double.tryParse(monthlyRent.text.trim()) ?? 0,
      moveInDate: null,
      leaseMonths: int.tryParse(leaseMonths.text.trim()) ?? 12,
      note: note.text.trim(),
      paymentId: '',
      createdAt: DateTime.now(),
    );

    await StorageService.instance.bookingStore.put(booking.id, booking.toMap());
    await _refreshData();
  }

  Future<void> _editBooking(Booking booking) async {
    final status = TextEditingController(text: booking.status);
    final monthlyRent = TextEditingController(
      text: booking.monthlyRent.toString(),
    );
    final leaseMonths = TextEditingController(
      text: booking.leaseMonths.toString(),
    );
    final note = TextEditingController(text: booking.note);

    final save = await _showSimpleFormDialog('Edit Booking', [
      _FormFieldSpec('Status', status),
      _FormFieldSpec('Monthly Rent', monthlyRent),
      _FormFieldSpec('Lease Months', leaseMonths),
      _FormFieldSpec('Note', note),
    ]);
    if (!save) return;

    final map = booking.toMap();
    map['status'] = status.text.trim();
    map['monthlyRent'] =
        double.tryParse(monthlyRent.text.trim()) ?? booking.monthlyRent;
    map['leaseMonths'] =
        int.tryParse(leaseMonths.text.trim()) ?? booking.leaseMonths;
    map['note'] = note.text.trim();

    await StorageService.instance.bookingStore.put(booking.id, map);
    await _refreshData();
  }

  Future<void> _deleteSelectedBookings() async {
    final box = StorageService.instance.bookingStore;
    for (final id in _selectedBookings) {
      await box.delete(id);
    }
    setState(() => _selectedBookings.clear());
    await _refreshData();
  }

  Future<void> _showBookingDetails(Booking booking) async {
    await _showRecordDetails(
      title: 'Booking Details',
      fields: {
        'Booking ID': booking.id,
        'Property ID': booking.propertyId,
        'Property Title': booking.propertyTitle,
        'Renter ID': booking.renterId,
        'Owner ID': booking.ownerId,
        'Status': booking.status,
        'Monthly Rent': booking.monthlyRent.toUsd(),
        'Lease Months': '${booking.leaseMonths}',
        'Move In Date': booking.moveInDate == null
            ? '-'
            : AppDateUtils.pretty(booking.moveInDate!),
        'Payment ID': booking.paymentId.isEmpty ? '-' : booking.paymentId,
        'Note': booking.note.isEmpty ? '-' : booking.note,
        'Created At': AppDateUtils.pretty(booking.createdAt),
      },
    );
  }

  Future<void> _createPayment() async {
    final amount = TextEditingController(text: '0');
    final method = TextEditingController(text: 'ABA Pay (Mock)');
    final status = TextEditingController(text: 'Success');
    final users = _collectUsers();
    final properties = context.read<PropertyProvider>().properties;
    String? selectedPropertyId;
    String? selectedUserId;
    final propertyOptions = properties
        .map((p) => _PickerOption(value: p.id, label: '${p.title} (${p.id})'))
        .toList();
    final userOptions = users
        .map((u) => _PickerOption(value: u.userId, label: _userLabel(u)))
        .toList();

    final create = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _searchableIdDropdown(
                  key: ValueKey('create-payment-property-$selectedPropertyId'),
                  label: 'Property',
                  hintText: 'Select Property',
                  value: selectedPropertyId,
                  options: propertyOptions,
                  onChanged: (v) =>
                      setDialogState(() => selectedPropertyId = v),
                ),
                const SizedBox(height: 8),
                _searchableIdDropdown(
                  key: ValueKey('create-payment-user-$selectedUserId'),
                  label: 'User',
                  hintText: 'Select User',
                  value: selectedUserId,
                  options: userOptions,
                  onChanged: (v) => setDialogState(() => selectedUserId = v),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: amount,
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: method,
                  decoration: const InputDecoration(labelText: 'Method'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
    if (create != true) return;
    if (selectedPropertyId == null || selectedUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select Property and User.')),
        );
      }
      return;
    }

    final payment = Payment(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      propertyId: selectedPropertyId!,
      userId: selectedUserId!,
      amount: double.tryParse(amount.text.trim()) ?? 0,
      method: method.text.trim(),
      status: status.text.trim(),
      createdAt: DateTime.now(),
    );

    await StorageService.instance.paymentStore.put(payment.id, payment.toMap());
    await _refreshData();
  }

  Future<void> _editPayment(Payment payment) async {
    final amount = TextEditingController(text: payment.amount.toString());
    final method = TextEditingController(text: payment.method);
    final status = TextEditingController(text: payment.status);

    final save = await _showSimpleFormDialog('Edit Payment', [
      _FormFieldSpec('Amount', amount),
      _FormFieldSpec('Method', method),
      _FormFieldSpec('Status', status),
    ]);
    if (!save) return;

    final map = payment.toMap();
    map['amount'] = double.tryParse(amount.text.trim()) ?? payment.amount;
    map['method'] = method.text.trim();
    map['status'] = status.text.trim();

    await StorageService.instance.paymentStore.put(payment.id, map);
    await _refreshData();
  }

  Future<void> _deleteSelectedPayments() async {
    final box = StorageService.instance.paymentStore;
    for (final id in _selectedPayments) {
      await box.delete(id);
    }
    setState(() => _selectedPayments.clear());
    await _refreshData();
  }

  Future<void> _showPaymentDetails(Payment payment) async {
    await _showRecordDetails(
      title: 'Payment Details',
      fields: {
        'Payment ID': payment.id,
        'Property ID': payment.propertyId,
        'User ID': payment.userId,
        'Amount': payment.amount.toUsd(),
        'Method': payment.method,
        'Status': payment.status,
        'Created At': AppDateUtils.pretty(payment.createdAt),
      },
    );
  }

  String _userLabel(_AdminUser user) {
    if (user.fullName.isNotEmpty && user.username.isNotEmpty) {
      return '${user.fullName} (@${user.username})';
    }
    if (user.fullName.isNotEmpty) return '${user.fullName} (${user.userId})';
    if (user.username.isNotEmpty) return '${user.userId} (@${user.username})';
    return user.userId;
  }

  Widget _searchableIdDropdown({
    required Key key,
    required String label,
    required String hintText,
    required String? value,
    required List<_PickerOption> options,
    required ValueChanged<String?> onChanged,
  }) {
    final hasValue =
        value != null && options.any((option) => option.value == value);
    final searchable = options.isNotEmpty;
    return DropdownMenu<String>(
      key: key,
      label: Text(label),
      hintText: hintText,
      initialSelection: hasValue ? value : null,
      enableSearch: searchable,
      enableFilter: searchable,
      requestFocusOnTap: searchable,
      keyboardType: TextInputType.text,
      expandedInsets: EdgeInsets.zero,
      onSelected: onChanged,
      dropdownMenuEntries: options
          .map(
            (option) =>
                DropdownMenuEntry(value: option.value, label: option.label),
          )
          .toList(),
    );
  }

  Future<void> _showRecordDetails({
    required String title,
    required Map<String, String> fields,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final entry in fields.entries) ...[
                  Text(
                    entry.key,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(entry.value),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showSimpleFormDialog(
    String title,
    List<_FormFieldSpec> fields,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...fields.map(
                (field) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: field.controller,
                    decoration: InputDecoration(labelText: field.label),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _AdminDashboard extends StatelessWidget {
  final int usersCount;
  final List<Property> properties;
  final List<Booking> bookings;
  final List<Payment> payments;

  const _AdminDashboard({
    required this.usersCount,
    required this.properties,
    required this.bookings,
    required this.payments,
  });

  @override
  Widget build(BuildContext context) {
    final successPayments = payments
        .where((p) => p.status == 'Success')
        .toList();
    final revenue = successPayments.fold<double>(0, (sum, p) => sum + p.amount);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 700;
            if (compact) {
              return Column(
                children: [
                  _statCard('Users', '$usersCount', Icons.group_outlined),
                  const SizedBox(height: 10),
                  _statCard(
                    'Properties',
                    '${properties.length}',
                    Icons.apartment_outlined,
                  ),
                  const SizedBox(height: 10),
                  _statCard(
                    'Bookings',
                    '${bookings.length}',
                    Icons.request_page_outlined,
                  ),
                  const SizedBox(height: 10),
                  _statCard(
                    'Payments',
                    '${payments.length}',
                    Icons.receipt_long_outlined,
                  ),
                  const SizedBox(height: 10),
                  _statCard(
                    'Revenue',
                    revenue.toUsd(),
                    Icons.attach_money_outlined,
                  ),
                ],
              );
            }

            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _statCard(
                  'Users',
                  '$usersCount',
                  Icons.group_outlined,
                  width: 250,
                ),
                _statCard(
                  'Properties',
                  '${properties.length}',
                  Icons.apartment_outlined,
                  width: 250,
                ),
                _statCard(
                  'Bookings',
                  '${bookings.length}',
                  Icons.request_page_outlined,
                  width: 250,
                ),
                _statCard(
                  'Payments',
                  '${payments.length}',
                  Icons.receipt_long_outlined,
                  width: 250,
                ),
                _statCard(
                  'Revenue',
                  revenue.toUsd(),
                  Icons.attach_money_outlined,
                  width: 250,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, {double? width}) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primaryDark),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
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
}

class _SuperAdminMorePage extends StatefulWidget {
  final int initialTab;
  final ValueChanged<int> onTabChanged;
  final List<Property> properties;
  final List<Booking> bookings;
  final List<Payment> payments;
  final Set<String> selectedProperties;
  final Set<String> selectedBookings;
  final Set<String> selectedPayments;
  final void Function(String id, bool value) onToggleProperty;
  final void Function(String id, bool value) onToggleBooking;
  final void Function(String id, bool value) onTogglePayment;
  final ValueChanged<bool> onToggleAllProperties;
  final ValueChanged<bool> onToggleAllBookings;
  final ValueChanged<bool> onToggleAllPayments;

  const _SuperAdminMorePage({
    required this.initialTab,
    required this.onTabChanged,
    required this.properties,
    required this.bookings,
    required this.payments,
    required this.selectedProperties,
    required this.selectedBookings,
    required this.selectedPayments,
    required this.onToggleProperty,
    required this.onToggleBooking,
    required this.onTogglePayment,
    required this.onToggleAllProperties,
    required this.onToggleAllBookings,
    required this.onToggleAllPayments,
  });

  @override
  State<_SuperAdminMorePage> createState() => _SuperAdminMorePageState();
}

class _SuperAdminMorePageState extends State<_SuperAdminMorePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _tabController.addListener(_onTabChanged);
  }

  @override
  void didUpdateWidget(covariant _SuperAdminMorePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != _tabController.index) {
      _tabController.animateTo(widget.initialTab);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    widget.onTabChanged(_tabController.index);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 4),
        TabBar(
          controller: _tabController,
          isScrollable: false,
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Properties'),
            Tab(text: 'Bookings'),
            Tab(text: 'Payments'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _PropertiesPage(
                properties: widget.properties,
                selected: widget.selectedProperties,
                onToggle: widget.onToggleProperty,
                onToggleAll: widget.onToggleAllProperties,
              ),
              _BookingsPage(
                bookings: widget.bookings,
                selected: widget.selectedBookings,
                onToggle: widget.onToggleBooking,
                onToggleAll: widget.onToggleAllBookings,
              ),
              _PaymentsPage(
                payments: widget.payments,
                selected: widget.selectedPayments,
                onToggle: widget.onTogglePayment,
                onToggleAll: widget.onToggleAllPayments,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UsersPage extends StatelessWidget {
  final List<_AdminUser> users;
  final Set<String> selected;
  final void Function(String id, bool value) onToggle;
  final ValueChanged<bool> onToggleAll;

  const _UsersPage({
    required this.users,
    required this.selected,
    required this.onToggle,
    required this.onToggleAll,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) return const Center(child: Text('No users found'));
    final allSelected = selected.isNotEmpty && selected.length == users.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CheckboxListTile(
          value: allSelected,
          onChanged: (v) => onToggleAll(v ?? false),
          title: const Text('Select all'),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 8),
        ...users.map(
          (user) => _UserRow(
            user: user,
            checked: selected.contains(user.userId),
            onChanged: (v) => onToggle(user.userId, v ?? false),
          ),
        ),
      ],
    );
  }
}

class _UserRow extends StatefulWidget {
  final _AdminUser user;
  final bool checked;
  final ValueChanged<bool?> onChanged;

  const _UserRow({
    required this.user,
    required this.checked,
    required this.onChanged,
  });

  @override
  State<_UserRow> createState() => _UserRowState();
}

class _UserRowState extends State<_UserRow> {
  @override
  Widget build(BuildContext context) {
    final parent = context
        .findAncestorStateOfType<_SuperAdminHomeScreenState>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          onTap: parent == null
              ? null
              : () => parent._showUserDetails(widget.user),
          leading: Checkbox(value: widget.checked, onChanged: widget.onChanged),
          title: Text(
            widget.user.fullName.isEmpty
                ? widget.user.userId
                : widget.user.fullName,
          ),
          subtitle: Text('${widget.user.userId}\n@${widget.user.username}'),
          isThreeLine: true,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.user.role,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: parent == null
                    ? null
                    : () => parent._editUser(widget.user),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PropertiesPage extends StatelessWidget {
  final List<Property> properties;
  final Set<String> selected;
  final void Function(String id, bool value) onToggle;
  final ValueChanged<bool> onToggleAll;

  const _PropertiesPage({
    required this.properties,
    required this.selected,
    required this.onToggle,
    required this.onToggleAll,
  });

  @override
  Widget build(BuildContext context) {
    if (properties.isEmpty) {
      return const Center(child: Text('No properties yet'));
    }
    final allSelected =
        selected.isNotEmpty && selected.length == properties.length;
    final parent = context
        .findAncestorStateOfType<_SuperAdminHomeScreenState>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CheckboxListTile(
          value: allSelected,
          onChanged: (v) => onToggleAll(v ?? false),
          title: const Text('Select all'),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 8),
        ...properties.map(
          (property) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: ListTile(
                onTap: parent == null
                    ? null
                    : () => parent._showPropertyDetails(property),
                leading: Checkbox(
                  value: selected.contains(property.id),
                  onChanged: (v) => onToggle(property.id, v ?? false),
                ),
                title: Text(property.title),
                subtitle: Text(
                  '${property.location} • ${property.pricePerMonth.toUsd()}/month',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: parent == null
                      ? null
                      : () => parent._editProperty(property),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BookingsPage extends StatelessWidget {
  final List<Booking> bookings;
  final Set<String> selected;
  final void Function(String id, bool value) onToggle;
  final ValueChanged<bool> onToggleAll;

  const _BookingsPage({
    required this.bookings,
    required this.selected,
    required this.onToggle,
    required this.onToggleAll,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) return const Center(child: Text('No bookings yet'));
    final allSelected =
        selected.isNotEmpty && selected.length == bookings.length;
    final parent = context
        .findAncestorStateOfType<_SuperAdminHomeScreenState>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CheckboxListTile(
          value: allSelected,
          onChanged: (v) => onToggleAll(v ?? false),
          title: const Text('Select all'),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 8),
        ...bookings.map(
          (booking) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: ListTile(
                onTap: parent == null
                    ? null
                    : () => parent._showBookingDetails(booking),
                leading: Checkbox(
                  value: selected.contains(booking.id),
                  onChanged: (v) => onToggle(booking.id, v ?? false),
                ),
                title: Text(booking.propertyTitle),
                subtitle: Text(
                  '${booking.renterId} -> ${booking.ownerId}\n${AppDateUtils.pretty(booking.createdAt)}',
                ),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: parent == null
                      ? null
                      : () => parent._editBooking(booking),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PaymentsPage extends StatelessWidget {
  final List<Payment> payments;
  final Set<String> selected;
  final void Function(String id, bool value) onToggle;
  final ValueChanged<bool> onToggleAll;

  const _PaymentsPage({
    required this.payments,
    required this.selected,
    required this.onToggle,
    required this.onToggleAll,
  });

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) return const Center(child: Text('No payments yet'));
    final allSelected =
        selected.isNotEmpty && selected.length == payments.length;
    final parent = context
        .findAncestorStateOfType<_SuperAdminHomeScreenState>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CheckboxListTile(
          value: allSelected,
          onChanged: (v) => onToggleAll(v ?? false),
          title: const Text('Select all'),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 8),
        ...payments.map(
          (payment) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: ListTile(
                onTap: parent == null
                    ? null
                    : () => parent._showPaymentDetails(payment),
                leading: Checkbox(
                  value: selected.contains(payment.id),
                  onChanged: (v) => onToggle(payment.id, v ?? false),
                ),
                title: Text(payment.amount.toUsd()),
                subtitle: Text(
                  '${payment.userId} • ${payment.method}\n${AppDateUtils.pretty(payment.createdAt)}',
                ),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: parent == null
                      ? null
                      : () => parent._editPayment(payment),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SuperAdminProfilePage extends StatelessWidget {
  const _SuperAdminProfilePage();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final userId = auth.currentUserId ?? 'Unknown superadmin';
        final fullName = auth.currentFullName == 'Unknown'
            ? 'Super Admin'
            : auth.currentFullName;
        final username = auth.currentUsername;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F4EE),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings,
                        size: 40,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      fullName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      auth.currentRoleLabel,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Divider(height: 1),
                    const SizedBox(height: 18),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ProfileInfoRow(
                          label: 'Full Name',
                          value: fullName,
                          icon: Icons.badge_outlined,
                        ),
                        _ProfileInfoRow(
                          label: 'Username',
                          value: '@$username',
                          icon: Icons.alternate_email,
                        ),
                        _ProfileInfoRow(
                          label: 'Email / User ID',
                          value: userId,
                          icon: Icons.mail_outline,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => context.read<AuthProvider>().logout(),
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout'),
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
}

class _ProfileInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ProfileInfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminUser {
  final String userId;
  final String username;
  final String fullName;
  final String role;

  const _AdminUser({
    required this.userId,
    required this.username,
    required this.fullName,
    required this.role,
  });
}

class _FormFieldSpec {
  final String label;
  final TextEditingController controller;

  const _FormFieldSpec(this.label, this.controller);
}

class _PickerOption {
  final String value;
  final String label;

  const _PickerOption({required this.value, required this.label});
}
