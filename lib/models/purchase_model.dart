class Purchase {
  final String serialNumber;
  final String material;
  final String affiliation;
  final String count;
  final String packaging;
  final String standing;
  final String net;
  final String price;
  final String total;
  final String cashOrDebt;
  final String empties;
  final String sellerName; // إضافة اسم البائع لكل سجل (صف)

  Purchase({
    required this.serialNumber,
    required this.material,
    required this.affiliation,
    required this.count,
    required this.packaging,
    required this.standing,
    required this.net,
    required this.price,
    required this.total,
    required this.cashOrDebt,
    required this.empties,
    required this.sellerName,
  });

  // تحويل من JSON إلى كائن
  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      serialNumber: json['serialNumber'] ?? '',
      material: json['material'] ?? '',
      affiliation: json['affiliation'] ?? '',
      count: json['count'] ?? '',
      packaging: json['packaging'] ?? '',
      standing: json['standing'] ?? '',
      net: json['net'] ?? '',
      price: json['price'] ?? '',
      total: json['total'] ?? '',
      cashOrDebt: json['cashOrDebt'] ?? '',
      empties: json['empties'] ?? '',
      sellerName: json['sellerName'] ?? '',
    );
  }

  // تحويل من كائن إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'serialNumber': serialNumber,
      'material': material,
      'affiliation': affiliation,
      'count': count,
      'packaging': packaging,
      'standing': standing,
      'net': net,
      'price': price,
      'total': total,
      'cashOrDebt': cashOrDebt,
      'empties': empties,
      'sellerName': sellerName,
    };
  }
}

class PurchaseDocument {
  final String recordNumber;
  final String date;
  final String sellerName;
  final String storeName;
  final String dayName;
  final List<Purchase> purchases;
  final Map<String, String> totals;

  PurchaseDocument({
    required this.recordNumber,
    required this.date,
    required this.sellerName,
    required this.storeName,
    required this.dayName,
    required this.purchases,
    required this.totals,
  });

  // تحويل من JSON إلى كائن
  factory PurchaseDocument.fromJson(Map<String, dynamic> json) {
    return PurchaseDocument(
      recordNumber: json['recordNumber'] ?? '',
      date: json['date'] ?? '',
      sellerName: json['sellerName'] ?? '',
      storeName: json['storeName'] ?? '',
      dayName: json['dayName'] ?? '',
      purchases: (json['purchases'] as List<dynamic>?)
              ?.map((item) => Purchase.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      totals: Map<String, String>.from(json['totals'] ?? {}),
    );
  }

  // تحويل من كائن إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'recordNumber': recordNumber,
      'date': date,
      'sellerName': sellerName,
      'storeName': storeName,
      'dayName': dayName,
      'purchases': purchases.map((p) => p.toJson()).toList(),
      'totals': totals,
    };
  }
}
