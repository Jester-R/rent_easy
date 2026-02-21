class Property {
  final String id;
  final String ownerId;
  final String title;
  final String location;
  final double pricePerMonth;
  final int bedrooms;
  final int bathrooms;
  final String description;

  const Property({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.location,
    required this.pricePerMonth,
    required this.bedrooms,
    required this.bathrooms,
    required this.description,
  });

  factory Property.fromMap(Map<String, dynamic> map) {
    return Property(
      id: map['id'] as String,
      ownerId: map['ownerId'] as String,
      title: map['title'] as String,
      location: map['location'] as String,
      pricePerMonth: (map['pricePerMonth'] as num).toDouble(),
      bedrooms: map['bedrooms'] as int,
      bathrooms: map['bathrooms'] as int,
      description: map['description'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'title': title,
      'location': location,
      'pricePerMonth': pricePerMonth,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'description': description,
    };
  }

  Property copyWith({
    String? title,
    String? location,
    double? pricePerMonth,
    int? bedrooms,
    int? bathrooms,
    String? description,
  }) {
    return Property(
      id: id,
      ownerId: ownerId,
      title: title ?? this.title,
      location: location ?? this.location,
      pricePerMonth: pricePerMonth ?? this.pricePerMonth,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      description: description ?? this.description,
    );
  }
}
