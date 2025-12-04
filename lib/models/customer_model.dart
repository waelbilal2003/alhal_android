class CustomerModel {
  final int? id;
  final String name;
  final String? phone;
  final String? address;
  final double balance;
  final String? createdAt;

  CustomerModel({
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

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      balance: (map['balance'] as num?)?.toDouble() ?? 0,
      createdAt: map['created_at'] as String?,
    );
  }

  CustomerModel copyWith({
    int? id,
    String? name,
    String? phone,
    String? address,
    double? balance,
    String? createdAt,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
