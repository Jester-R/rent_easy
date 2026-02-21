import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/property.dart';
import '../../providers/property_provider.dart';

class EditPropertyScreen extends StatefulWidget {
  final Property property;

  const EditPropertyScreen({super.key, required this.property});

  @override
  State<EditPropertyScreen> createState() => _EditPropertyScreenState();
}

class _EditPropertyScreenState extends State<EditPropertyScreen> {
  late final TextEditingController _title;
  late final TextEditingController _location;
  late final TextEditingController _price;
  late final TextEditingController _bed;
  late final TextEditingController _bath;
  late final TextEditingController _desc;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.property.title);
    _location = TextEditingController(text: widget.property.location);
    _price = TextEditingController(text: widget.property.pricePerMonth.toString());
    _bed = TextEditingController(text: widget.property.bedrooms.toString());
    _bath = TextEditingController(text: widget.property.bathrooms.toString());
    _desc = TextEditingController(text: widget.property.description);
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _price.dispose();
    _bed.dispose();
    _bath.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final updated = widget.property.copyWith(
      title: _title.text.trim(),
      location: _location.text.trim(),
      pricePerMonth: double.tryParse(_price.text.trim()) ?? widget.property.pricePerMonth,
      bedrooms: int.tryParse(_bed.text.trim()) ?? widget.property.bedrooms,
      bathrooms: int.tryParse(_bath.text.trim()) ?? widget.property.bathrooms,
      description: _desc.text.trim(),
    );

    await context.read<PropertyProvider>().editProperty(updated);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Property')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: _location, decoration: const InputDecoration(labelText: 'Location')),
              TextField(
                controller: _price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price Per Month'),
              ),
              TextField(
                controller: _bed,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Bedrooms'),
              ),
              TextField(
                controller: _bath,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Bathrooms'),
              ),
              TextField(
                controller: _desc,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _save, child: const Text('Save Changes')),
            ],
          ),
        ),
      ),
    );
  }
}
