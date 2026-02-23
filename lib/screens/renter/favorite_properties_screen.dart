import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/property_provider.dart';
import '../../widgets/property_card.dart';
import 'property_detail_screen.dart';

class FavoritePropertiesScreen extends StatelessWidget {
  const FavoritePropertiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, PropertyProvider>(
      builder: (context, auth, propertyProvider, _) {
        final userId = auth.currentUserId ?? '';
        final favorites = propertyProvider.favoriteProperties(userId);

        if (favorites.isEmpty) {
          return const Center(child: Text('No favorite properties yet'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: favorites.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, index) {
            final property = favorites[index];
            return PropertyCard(
              property: property,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PropertyDetailScreen(property: property),
                ),
              ),
              trailing: IconButton(
                onPressed: () => propertyProvider.toggleFavorite(userId, property.id),
                icon: const Icon(Icons.favorite, color: AppColors.primary),
              ),
            );
          },
        );
      },
    );
  }
}
