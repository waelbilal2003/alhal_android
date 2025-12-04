class InvoiceModel {
  final int? id;
  final int invoiceNumber;
  final String date;
  final int? dailyId;
  final int? customerId;
  final int? supplierId;
  final int? employeeId;
  final String type;
  final double totalAmount;
  final double cashAmount;
  final double debtAmount;
  final double downPayment;
  final double commissionFee;
  final double loadingFee;
  final double carRent;
  final double otherExpenses;
  final double netAmount;
  final String? notes;
  final String? createdAt;

  InvoiceModel({
    this.id,
    required this.invoiceNumber,
    required this.date,
    this.dailyId,
    this.customerId,
    this.supplierId,
    this.employeeId,
    required this.type,
    this.totalAmount = 0,
    this.cashAmount = 0,
    this.debtAmount = 0,
    this.downPayment = 0,
    this.commissionFee = 0,
    this.loadingFee = 0,
    this.carRent = 0,
    this.otherExpenses = 0,
    this.netAmount = 0,
    this.notes,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'date': date,
      'daily_id': dailyId,
      'customer_id': customerId,
      'supplier_id': supplierId,
      'employee_id': employeeId,
      'type': type,
      'total_amount': totalAmount,
      'cash_amount': cashAmount,
      'debt_amount': debtAmount,
      'down_payment': downPayment,
      'commission_fee': commissionFee,
      'loading_fee': loadingFee,
      'car_rent': carRent,
      'other_expenses': otherExpenses,
      'net_amount': netAmount,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    return InvoiceModel(
      id: map['id'] as int?,
      invoiceNumber: map['invoice_number'] as int,
      date: map['date'] as String,
      dailyId: map['daily_id'] as int?,
      customerId: map['customer_id'] as int?,
      supplierId: map['supplier_id'] as int?,
      employeeId: map['employee_id'] as int?,
      type: map['type'] as String,
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
      cashAmount: (map['cash_amount'] as num?)?.toDouble() ?? 0,
      debtAmount: (map['debt_amount'] as num?)?.toDouble() ?? 0,
      downPayment: (map['down_payment'] as num?)?.toDouble() ?? 0,
      commissionFee: (map['commission_fee'] as num?)?.toDouble() ?? 0,
      loadingFee: (map['loading_fee'] as num?)?.toDouble() ?? 0,
      carRent: (map['car_rent'] as num?)?.toDouble() ?? 0,
      otherExpenses: (map['other_expenses'] as num?)?.toDouble() ?? 0,
      netAmount: (map['net_amount'] as num?)?.toDouble() ?? 0,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }
}
