class InvoiceItemModel {
  final int? id;
  final int invoiceId;
  final int materialId;
  final String? relation;
  final double quantity;
  final double grossWeight;
  final double netWeight;
  final double price;
  final double total;
  final double empties;
  final double collateral;
  final String? createdAt;
  
  // Additional fields from JOIN
  final String? materialName;
  final String? materialUnit;

  InvoiceItemModel({
    this.id,
    required this.invoiceId,
    required this.materialId,
    this.relation,
    required this.quantity,
    this.grossWeight = 0,
    this.netWeight = 0,
    required this.price,
    required this.total,
    this.empties = 0,
    this.collateral = 0,
    this.createdAt,
    this.materialName,
    this.materialUnit,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'material_id': materialId,
      'relation': relation,
      'quantity': quantity,
      'gross_weight': grossWeight,
      'net_weight': netWeight,
      'price': price,
      'total': total,
      'empties': empties,
      'collateral': collateral,
      'created_at': createdAt,
    };
  }

  factory InvoiceItemModel.fromMap(Map<String, dynamic> map) {
    return InvoiceItemModel(
      id: map['id'] as int?,
      invoiceId: map['invoice_id'] as int,
      materialId: map['material_id'] as int,
      relation: map['relation'] as String?,
      quantity: (map['quantity'] as num).toDouble(),
      grossWeight: (map['gross_weight'] as num?)?.toDouble() ?? 0,
      netWeight: (map['net_weight'] as num?)?.toDouble() ?? 0,
      price: (map['price'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      empties: (map['empties'] as num?)?.toDouble() ?? 0,
      collateral: (map['collateral'] as num?)?.toDouble() ?? 0,
      createdAt: map['created_at'] as String?,
      materialName: map['material_name'] as String?,
      materialUnit: map['material_unit'] as String?,
    );
  }

  InvoiceItemModel copyWith({
    int? id,
    int? invoiceId,
    int? materialId,
    String? relation,
    double? quantity,
    double? grossWeight,
    double? netWeight,
    double? price,
    double? total,
    double? empties,
    double? collateral,
    String? createdAt,
    String? materialName,
    String? materialUnit,
  }) {
    return InvoiceItemModel(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      materialId: materialId ?? this.materialId,
      relation: relation ?? this.relation,
      quantity: quantity ?? this.quantity,
      grossWeight: grossWeight ?? this.grossWeight,
      netWeight: netWeight ?? this.netWeight,
      price: price ?? this.price,
      total: total ?? this.total,
      empties: empties ?? this.empties,
      collateral: collateral ?? this.collateral,
      createdAt: createdAt ?? this.createdAt,
      materialName: materialName ?? this.materialName,
      materialUnit: materialUnit ?? this.materialUnit,
    );
  }
}
