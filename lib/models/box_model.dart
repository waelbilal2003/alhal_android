class BoxTransaction {
  final String serialNumber;
  final String received;
  final String paid;
  final String accountType;
  final String accountName;
  final String notes;

  BoxTransaction({
    required this.serialNumber,
    required this.received,
    required this.paid,
    required this.accountType,
    required this.accountName,
    required this.notes,
  });

  // تحويل من JSON إلى كائن
  factory BoxTransaction.fromJson(Map<String, dynamic> json) {
    return BoxTransaction(
      serialNumber: json['serialNumber'] ?? '',
      received: json['received'] ?? '',
      paid: json['paid'] ?? '',
      accountType: json['accountType'] ?? '',
      accountName: json['accountName'] ?? '',
      notes: json['notes'] ?? '',
    );
  }

  // تحويل من كائن إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'serialNumber': serialNumber,
      'received': received,
      'paid': paid,
      'accountType': accountType,
      'accountName': accountName,
      'notes': notes,
    };
  }
}

class BoxDocument {
  final String recordNumber;
  final String date;
  final String sellerName;
  final String storeName;
  final String dayName;
  final List<BoxTransaction> transactions;
  final Map<String, String> totals;

  BoxDocument({
    required this.recordNumber,
    required this.date,
    required this.sellerName,
    required this.storeName,
    required this.dayName,
    required this.transactions,
    required this.totals,
  });

  // تحويل من JSON إلى كائن
  factory BoxDocument.fromJson(Map<String, dynamic> json) {
    return BoxDocument(
      recordNumber: json['recordNumber'] ?? '',
      date: json['date'] ?? '',
      sellerName: json['sellerName'] ?? '',
      storeName: json['storeName'] ?? '',
      dayName: json['dayName'] ?? '',
      transactions: (json['transactions'] as List<dynamic>?)
              ?.map((item) =>
                  BoxTransaction.fromJson(item as Map<String, dynamic>))
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
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'totals': totals,
    };
  }
}
