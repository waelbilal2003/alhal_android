class MaterialModel {
  final int? id;
  final String name;
  final String unit;
  final double defaultPrice;
  final String? createdAt;

  MaterialModel({
    this.id,
    required this.name,
    this.unit = 'كغ',
    this.defaultPrice = 0,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'unit': unit,
      'default_price': defaultPrice,
      'created_at': createdAt,
    };
  }

  factory MaterialModel.fromMap(Map<String, dynamic> map) {
    return MaterialModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      unit: map['unit'] as String? ?? 'كغ',
      defaultPrice: (map['default_price'] as num?)?.toDouble() ?? 0,
      createdAt: map['created_at'] as String?,
    );
  }

  MaterialModel copyWith({
    int? id,
    String? name,
    String? unit,
    double? defaultPrice,
    String? createdAt,
  }) {
    return MaterialModel(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      defaultPrice: defaultPrice ?? this.defaultPrice,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
