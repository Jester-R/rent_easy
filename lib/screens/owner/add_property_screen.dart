import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/property.dart';
import '../../providers/auth_provider.dart';
import '../../providers/property_provider.dart';
import '../../utils/validators.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _bedController = TextEditingController(text: '2');
  final _bathController = TextEditingController(text: '1');
  final _descController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _bedController.dispose();
    _bathController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final ownerId = context.read<AuthProvider>().currentUserId ?? 'owner';
    final property = Property(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      ownerId: ownerId,
      title: _titleController.text.trim(),
      location: _locationController.text.trim(),
      pricePerMonth: double.tryParse(_priceController.text.trim()) ?? 0,
      bedrooms: int.tryParse(_bedController.text.trim()) ?? 1,
      bathrooms: int.tryParse(_bathController.text.trim()) ?? 1,
      description: _descController.text.trim(),
    );

    await context.read<PropertyProvider>().addProperty(property);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Property')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) => Validators.requiredField(v, 'Title'),
                ),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                  validator: (v) => Validators.requiredField(v, 'Location'),
                ),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Price Per Month'),
                  validator: (v) => Validators.requiredField(v, 'Price Per Month'),
                ),
                TextFormField(
                  controller: _bedController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Bedrooms'),
                ),
                TextFormField(
                  controller: _bathController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Bathrooms'),
                ),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (v) => Validators.requiredField(v, 'Description'),
                ),
                const SizedBox(height: 16),
                FilledButton(onPressed: _save, child: const Text('Save Property')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
