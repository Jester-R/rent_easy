import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/colors.dart';
import '../../models/property.dart';
import '../../providers/auth_provider.dart';
import '../../providers/property_provider.dart';
import '../../utils/extensions.dart';
import '../../widgets/custom_button.dart';
import 'fake_payment_screen.dart';

class PropertyDetailScreen extends StatelessWidget {
  final Property property;

  const PropertyDetailScreen({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().currentUserId ?? '';
    final propertyProvider = context.watch<PropertyProvider>();
    final hasActiveBooking = propertyProvider.hasActiveBookingForProperty(userId, property.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Property Detail')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.home_work_outlined, size: 48),
                ),
                const SizedBox(height: 16),
                Text(
                  property.title,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(property.location),
                const SizedBox(height: 8),
                Text(
                  '${property.pricePerMonth.toUsd()}/month',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _featurePill(Icons.bed_outlined, '${property.bedrooms} Bedrooms'),
                    _featurePill(Icons.bathtub_outlined, '${property.bathrooms} Bathrooms'),
                    _featurePill(Icons.location_city_outlined, 'City Access'),
                    _featurePill(Icons.wifi_outlined, 'Wi-Fi Ready'),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Description',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(property.description),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context
                            .read<PropertyProvider>()
                            .toggleFavorite(userId, property.id),
                        icon: Icon(
                          context.watch<PropertyProvider>().isFavorite(userId, property.id)
                              ? Icons.favorite
                              : Icons.favorite_border,
                        ),
                        label: const Text('Favorite'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: hasActiveBooking
                          ? CustomButton(
                              label: 'Already Booked',
                              onPressed: null,
                            )
                          : CustomButton(
                              label: 'Request Booking',
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FakePaymentScreen(property: property),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _featurePill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Text(text),
        ],
      ),
    );
  }
}
