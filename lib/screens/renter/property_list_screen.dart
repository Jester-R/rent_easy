import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/property_provider.dart';
import '../../utils/extensions.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/property_card.dart';
import 'property_detail_screen.dart';

class PropertyListScreen extends StatefulWidget {
  const PropertyListScreen({super.key});

  @override
  State<PropertyListScreen> createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen> {
  final _searchController = TextEditingController();
  String _selectedLocation = 'All Locations';
  String _sortBy = 'Recommended';
  int _minBedrooms = 0;
  double _maxPrice = 5000;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, PropertyProvider>(
      builder: (context, auth, provider, _) {
        if (provider.isLoading) return const LoadingIndicator();

        final renterId = auth.currentUserId ?? '';

        final locations = <String>{
          'All Locations',
          ...provider.properties.map((p) => p.location),
        }.toList()
          ..sort();

        var visible = provider.searchProperties(_searchController.text).where((p) {
          final inLocation =
              _selectedLocation == 'All Locations' || p.location == _selectedLocation;
          final inPrice = p.pricePerMonth <= _maxPrice;
          final inBedrooms = p.bedrooms >= _minBedrooms;
          final noActiveBooking = !provider.hasActiveBookingForProperty(renterId, p.id);
          return inLocation && inPrice && inBedrooms && noActiveBooking;
        }).toList();

        switch (_sortBy) {
          case 'Price: Low to High':
            visible.sort((a, b) => a.pricePerMonth.compareTo(b.pricePerMonth));
            break;
          case 'Price: High to Low':
            visible.sort((a, b) => b.pricePerMonth.compareTo(a.pricePerMonth));
            break;
          case 'Bedrooms':
            visible.sort((a, b) => b.bedrooms.compareTo(a.bedrooms));
            break;
          default:
            visible.sort((a, b) => a.title.compareTo(b.title));
        }

        final avgPrice =
            visible.isEmpty ? 0 : visible.map((e) => e.pricePerMonth).reduce((a, b) => a + b) / visible.length;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const CircleAvatar(child: Icon(Icons.apartment_outlined)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${visible.length} properties found',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            Text('Average price ${avgPrice.toUsd()}/month'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        hintText: 'Search by title, area, or neighborhood',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 118,
                    child: OutlinedButton.icon(
                      onPressed: () => _openFilterModal(locations),
                      icon: const Icon(Icons.tune),
                      label: Text(
                        _activeFilterCount() > 0 ? 'Filter (${_activeFilterCount()})' : 'Filter',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _ActiveFiltersRow(
                location: _selectedLocation,
                sortBy: _sortBy,
                minBedrooms: _minBedrooms,
                maxPrice: _maxPrice,
                onClearAll: _resetFilters,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: visible.isEmpty
                    ? const Center(
                        child: Text(
                          'No properties match these filters.\nTry widening your search.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        itemCount: visible.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, index) {
                          final property = visible[index];
                          return PropertyCard(
                            property: property,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PropertyDetailScreen(property: property),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  int _activeFilterCount() {
    var count = 0;
    if (_selectedLocation != 'All Locations') count++;
    if (_sortBy != 'Recommended') count++;
    if (_minBedrooms > 0) count++;
    if (_maxPrice < 5000) count++;
    return count;
  }

  void _resetFilters() {
    setState(() {
      _selectedLocation = 'All Locations';
      _sortBy = 'Recommended';
      _minBedrooms = 0;
      _maxPrice = 5000;
    });
  }

  Future<void> _openFilterModal(List<String> locations) async {
    String draftLocation = _selectedLocation;
    String draftSortBy = _sortBy;
    int draftMinBedrooms = _minBedrooms;
    double draftMaxPrice = _maxPrice;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.65,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filter Properties',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownMenu<String>(
                                key: ValueKey('filter-location-$draftLocation'),
                                label: const Text('Location'),
                                hintText: 'Select location',
                                leadingIcon: const Icon(Icons.place_outlined),
                                initialSelection: draftLocation,
                                enableSearch: true,
                                enableFilter: true,
                                requestFocusOnTap: true,
                                keyboardType: TextInputType.text,
                                expandedInsets: EdgeInsets.zero,
                                dropdownMenuEntries: locations
                                    .map(
                                      (item) => DropdownMenuEntry(
                                        value: item,
                                        label: item,
                                      ),
                                    )
                                    .toList(),
                                onSelected: (value) {
                                  setModalState(
                                    () => draftLocation = value ?? locations.first,
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              DropdownMenu<String>(
                                key: ValueKey('filter-sort-$draftSortBy'),
                                label: const Text('Sort by'),
                                hintText: 'Select sort option',
                                leadingIcon: const Icon(Icons.sort),
                                initialSelection: draftSortBy,
                                enableSearch: true,
                                enableFilter: true,
                                requestFocusOnTap: true,
                                keyboardType: TextInputType.text,
                                expandedInsets: EdgeInsets.zero,
                                dropdownMenuEntries: const [
                                  DropdownMenuEntry(value: 'Recommended', label: 'Recommended'),
                                  DropdownMenuEntry(
                                    value: 'Price: Low to High',
                                    label: 'Price: Low to High',
                                  ),
                                  DropdownMenuEntry(
                                    value: 'Price: High to Low',
                                    label: 'Price: High to Low',
                                  ),
                                  DropdownMenuEntry(value: 'Bedrooms', label: 'Bedrooms'),
                                ],
                                onSelected: (value) {
                                  setModalState(() => draftSortBy = value ?? draftSortBy);
                                },
                              ),
                              const SizedBox(height: 14),
                              const Text('Bedrooms'),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: [
                                  ChoiceChip(
                                    label: const Text('Any'),
                                    selected: draftMinBedrooms == 0,
                                    onSelected: (_) =>
                                        setModalState(() => draftMinBedrooms = 0),
                                  ),
                                  ChoiceChip(
                                    label: const Text('1+'),
                                    selected: draftMinBedrooms == 1,
                                    onSelected: (_) =>
                                        setModalState(() => draftMinBedrooms = 1),
                                  ),
                                  ChoiceChip(
                                    label: const Text('2+'),
                                    selected: draftMinBedrooms == 2,
                                    onSelected: (_) =>
                                        setModalState(() => draftMinBedrooms = 2),
                                  ),
                                  ChoiceChip(
                                    label: const Text('3+'),
                                    selected: draftMinBedrooms == 3,
                                    onSelected: (_) =>
                                        setModalState(() => draftMinBedrooms = 3),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  const Text('Max price:'),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () async {
                                      final value = await _openPriceInputDialog(
                                        context,
                                        draftMaxPrice,
                                      );
                                      if (value == null) return;
                                      setModalState(() => draftMaxPrice = value);
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: AppColors.border),
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.white,
                                      ),
                                      child: Text(
                                        draftMaxPrice.round().toUsd(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Slider(
                                activeColor: AppColors.primary,
                                min: 300,
                                max: 5000,
                                divisions: 47,
                                value: draftMaxPrice,
                                onChanged: (v) => setModalState(() => draftMaxPrice = v),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final compactActions = constraints.maxWidth < 430;
                          if (compactActions) {
                            return Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedLocation = draftLocation;
                                        _sortBy = draftSortBy;
                                        _minBedrooms = draftMinBedrooms;
                                        _maxPrice = draftMaxPrice;
                                      });
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Apply Filters'),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      setModalState(() {
                                        draftLocation = 'All Locations';
                                        draftSortBy = 'Recommended';
                                        draftMinBedrooms = 0;
                                        draftMaxPrice = 5000;
                                      });
                                    },
                                    child: const Text('Reset'),
                                  ),
                                ),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    setModalState(() {
                                      draftLocation = 'All Locations';
                                      draftSortBy = 'Recommended';
                                      draftMinBedrooms = 0;
                                      draftMaxPrice = 5000;
                                    });
                                  },
                                  child: const Text('Reset'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedLocation = draftLocation;
                                      _sortBy = draftSortBy;
                                      _minBedrooms = draftMinBedrooms;
                                      _maxPrice = draftMaxPrice;
                                    });
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Apply Filters'),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<double?> _openPriceInputDialog(
    BuildContext context,
    double currentPrice,
  ) async {
    final controller =
        TextEditingController(text: currentPrice.round().toString());

    return showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Max Price'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Price',
            hintText: '300 - 5000',
            prefixText: '\$',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text.trim());
              if (parsed == null) return;
              final clamped = parsed.clamp(300, 5000).toDouble();
              Navigator.pop(context, clamped);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

class _ActiveFiltersRow extends StatelessWidget {
  final String location;
  final String sortBy;
  final int minBedrooms;
  final double maxPrice;
  final VoidCallback onClearAll;

  const _ActiveFiltersRow({
    required this.location,
    required this.sortBy,
    required this.minBedrooms,
    required this.maxPrice,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (location != 'All Locations') {
      chips.add(_chip('Location: $location'));
    }
    if (sortBy != 'Recommended') {
      chips.add(_chip(sortBy));
    }
    if (minBedrooms > 0) {
      chips.add(_chip('${minBedrooms}+ Bedrooms'));
    }
    if (maxPrice < 5000) {
      chips.add(_chip('Max ${maxPrice.round().toUsd()}'));
    }

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...chips,
        TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: AppColors.primaryDark),
          onPressed: onClearAll,
          icon: const Icon(Icons.restart_alt),
          label: const Text('Clear all'),
        ),
      ],
    );
  }

  Widget _chip(String text) {
    return Chip(
      label: Text(text),
      visualDensity: VisualDensity.compact,
      side: const BorderSide(color: AppColors.border),
      backgroundColor: Colors.white,
    );
  }
}
