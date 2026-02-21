import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/property.dart';
import '../../providers/auth_provider.dart';
import '../../providers/property_provider.dart';
import '../../utils/extensions.dart';
import '../../widgets/custom_button.dart';

class FakePaymentScreen extends StatefulWidget {
  final Property property;

  const FakePaymentScreen({super.key, required this.property});

  @override
  State<FakePaymentScreen> createState() => _FakePaymentScreenState();
}

class _FakePaymentScreenState extends State<FakePaymentScreen> {
  DateTime? _moveInDate;
  int _leaseMonths = 12;
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitBookingRequest() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    final propertyProvider = context.read<PropertyProvider>();
    final renterId = auth.currentUserId ?? '';

    // Check if renter already has active booking for this property
    if (propertyProvider.hasActiveBookingForProperty(renterId, widget.property.id)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You already have a pending or approved booking for this property'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    await propertyProvider.createBooking(
      propertyId: widget.property.id,
      renterId: renterId,
      moveInDate: _moveInDate,
      leaseMonths: _leaseMonths,
      note: _noteController.text,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking request sent. Pay after owner approval.'),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Request')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Request ${widget.property.title} (${widget.property.pricePerMonth.toUsd()}/month)',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Preferred Move-in Date'),
                          subtitle: Text(
                            _moveInDate == null
                                ? 'Not selected'
                                : '${_moveInDate!.day}/${_moveInDate!.month}/${_moveInDate!.year}',
                          ),
                          trailing: TextButton(
                            onPressed: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: now.add(const Duration(days: 7)),
                                firstDate: now,
                                lastDate: now.add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setState(() => _moveInDate = picked);
                              }
                            },
                            child: const Text('Select'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('Lease Term (months)'),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          children: [6, 12, 18, 24]
                              .map(
                                (m) => ChoiceChip(
                                  label: Text('$m'),
                                  selected: _leaseMonths == m,
                                  onSelected: (_) => setState(() => _leaseMonths = m),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _noteController,
                          minLines: 2,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Message to owner (optional)',
                            hintText: 'Tell owner your move-in preferences...',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                CustomButton(
                  label: 'Send Booking Request',
                  onPressed: _submitBookingRequest,
                  isBusy: _isSubmitting,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
