class SupplierModel {
  final int? id;
  final String name;
  final String? phone;
  final String? address;
  final double balance;
  final String? createdAt;

  SupplierModel({
    this.id,
    required this.name,
    this.phone,
    this.address,
    this.balance = 0,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'balance': balance,
      'created_at': createdAt,
    };
  }

  factory SupplierModel.fromMap(Map<String, dynamic> map) {
    return SupplierModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      balance: (map['balance'] as num?)?.toDouble() ?? 0,
      createdAt: map['created_at'] as String?,
    );
  }

  SupplierModel copyWith({
    int? id,
    String? name,
    String? phone,
    String? address,
    double? balance,
    String? createdAt,
  }) {
    return SupplierModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
