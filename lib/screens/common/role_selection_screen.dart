import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class RoleSelectionScreen extends StatelessWidget {
  final String userId;

  const RoleSelectionScreen({
    super.key,
    required this.userId,
  });

  Future<void> _selectRole(BuildContext context, UserRole role) async {
    await context.read<AuthProvider>().setRoleForUser(userId: userId, role: role);
    if (!context.mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Role')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text('Choose your role to complete registration.'),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.person_search_outlined),
                    title: const Text('Renter'),
                    subtitle: const Text('Browse and request properties'),
                    onTap: () => _selectRole(context, UserRole.renter),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.storefront_outlined),
                    title: const Text('Property Owner'),
                    subtitle: const Text('Create and manage property listings'),
                    onTap: () => _selectRole(context, UserRole.owner),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
