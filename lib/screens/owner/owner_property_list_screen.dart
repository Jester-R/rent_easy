import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/property_provider.dart';
import '../../widgets/property_card.dart';
import 'add_property_screen.dart';
import 'edit_property_screen.dart';

class OwnerPropertyListScreen extends StatelessWidget {
  const OwnerPropertyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, PropertyProvider>(
      builder: (context, auth, propertyProvider, _) {
        final ownerId = auth.currentUserId ?? '';
        final properties = propertyProvider.ownerProperties(ownerId);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddPropertyScreen()),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add Property'),
              ),
            ),
            const SizedBox(height: 12),
            if (properties.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                  child: Text('No properties yet. Add your first listing.'),
                ),
              )
            else
              ...List.generate(properties.length, (index) {
                final property = properties[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: index == properties.length - 1 ? 0 : 10),
                  child: PropertyCard(
                    property: property,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditPropertyScreen(property: property),
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => propertyProvider.deleteProperty(property.id),
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}
