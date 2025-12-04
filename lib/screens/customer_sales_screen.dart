import 'package:flutter/material.dart';
import 'package:market_ledger/models/customer_model.dart';
import 'package:market_ledger/models/invoice_item_model.dart';
import 'package:market_ledger/models/material_model.dart';
import 'package:market_ledger/services/database_helper.dart';

class CustomerSalesScreen extends StatefulWidget {
  const CustomerSalesScreen({super.key});

  @override
  State<CustomerSalesScreen> createState() => _CustomerSalesScreenState();
}

class _CustomerSalesScreenState extends State<CustomerSalesScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final List<InvoiceItemModel> _items = [];

  String _currentDate = DateTime.now().toIso8601String().split('T')[0];
  int _invoiceNumber = 1;
  String _employeeName = 'المدير العام';
  double _totalEstimate = 0;
  double _commissionFee = 0;
  double _loadingFee = 0;
  double _carRent = 0;
  double _otherExpenses = 0;
  double _downPayment = 0;
  double _netInvoice = 0;

  List<MaterialModel> _materials = [];
  List<CustomerModel> _customers = [];
  CustomerModel? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final materialsData = await _db.getAllMaterials();
    _materials = materialsData.map((m) => MaterialModel.fromMap(m)).toList();

    final customersData = await _db.getAllCustomers();
    _customers = customersData.map((c) => CustomerModel.fromMap(c)).toList();

    if (_customers.isNotEmpty) {
      _selectedCustomer = _customers.first;
    }

    final employees = await _db.getAllEmployees();
    if (employees.isNotEmpty) {
      _employeeName = employees.first['name'];
    }

    _invoiceNumber = await _db.getNextInvoiceNumber(_currentDate, 'زبون');
    setState(() {});
  }

  void _calculateTotal() {
    _totalEstimate = 0;
    for (var item in _items) {
      _totalEstimate += item.total;
    }
    _netInvoice = _totalEstimate +
        _commissionFee +
        _loadingFee +
        _carRent +
        _otherExpenses -
        _downPayment;
    setState(() {});
  }

  Future<void> _selectCustomer() async {
    if (_customers.isEmpty) {
      await _showAddCustomerDialog();
      return;
    }

    final result = await showDialog<CustomerModel>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('اختر الزبون'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _customers.map((customer) {
              return ListTile(
                title: Text(customer.name),
                subtitle: customer.phone != null ? Text(customer.phone!) : null,
                onTap: () => Navigator.pop(context, customer),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _showAddCustomerDialog();
              },
              child: const Text('إضافة زبون جديد'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedCustomer = result;
      });
    }
  }

  Future<void> _showAddCustomerDialog() async {
    String name = '';
    String phone = '';
    String address = '';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة زبون جديد'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'اسم الزبون'),
                onChanged: (value) => name = value,
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                onChanged: (value) => phone = value,
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(labelText: 'العنوان'),
                onChanged: (value) => address = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );

    if (result == true && name.isNotEmpty) {
      final customerId = await _db.insertCustomer({
        'name': name,
        'phone': phone.isEmpty ? null : phone,
        'address': address.isEmpty ? null : address,
      });

      final newCustomer = CustomerModel(
        id: customerId,
        name: name,
        phone: phone.isEmpty ? null : phone,
        address: address.isEmpty ? null : address,
      );

      setState(() {
        _customers.add(newCustomer);
        _selectedCustomer = newCustomer;
      });
    }
  }

  Future<void> _addItem() async {
    if (_materials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد مواد متاحة')),
      );
      return;
    }

    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار الزبون أولاً')),
      );
      return;
    }

    MaterialModel? selectedMaterial = _materials.first;
    double quantity = 0;
    double netWeight = 0;
    double price = 0;
    double empties = 0;
    double collateral = 0;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إضافة عنصر جديد'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<MaterialModel>(
                    value: selectedMaterial,
                    decoration: const InputDecoration(labelText: 'المادة'),
                    items: _materials.map((material) {
                      return DropdownMenuItem(
                        value: material,
                        child: Text(material.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedMaterial = value;
                        price = value?.defaultPrice ?? 0;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(labelText: 'العدد'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        quantity = double.tryParse(value) ?? 0,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(labelText: 'السيرة'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        netWeight = double.tryParse(value) ?? 0,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(labelText: 'السعر'),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: price.toString()),
                    onChanged: (value) => price = double.tryParse(value) ?? 0,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(labelText: 'الفوارغ'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => empties = double.tryParse(value) ?? 0,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(labelText: 'الرهن'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        collateral = double.tryParse(value) ?? 0,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (selectedMaterial != null && quantity > 0 && price > 0) {
                    Navigator.pop(context, {
                      'material': selectedMaterial,
                      'quantity': quantity,
                      'netWeight': netWeight,
                      'price': price,
                      'empties': empties,
                      'collateral': collateral,
                    });
                  }
                },
                child: const Text('إضافة'),
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null) {
      final material = result['material'] as MaterialModel;
      final double qty = result['quantity'];
      final double prc = result['price'];
      final double total = qty * prc;

      final newItem = InvoiceItemModel(
        invoiceId: 0,
        materialId: material.id!,
        quantity: qty,
        netWeight: result['netWeight'],
        price: prc,
        total: total,
        empties: result['empties'],
        collateral: result['collateral'],
        materialName: material.name,
        materialUnit: material.unit,
      );

      setState(() {
        _items.add(newItem);
      });
      _calculateTotal();
    }
  }

  Future<void> _saveInvoice() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إضافة عناصر للفاتورة')),
      );
      return;
    }

    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار الزبون')),
      );
      return;
    }

    try {
      final invoiceId = await _db.insertInvoice({
        'invoice_number': _invoiceNumber,
        'date': _currentDate,
        'customer_id': _selectedCustomer!.id,
        'employee_id': 1,
        'type': 'زبون',
        'total_amount': _totalEstimate,
        'cash_amount': _downPayment,
        'debt_amount': _netInvoice - _downPayment,
        'down_payment': _downPayment,
        'commission_fee': _commissionFee,
        'loading_fee': _loadingFee,
        'car_rent': _carRent,
        'other_expenses': _otherExpenses,
        'net_amount': _netInvoice,
      });

      for (var item in _items) {
        await _db.insertInvoiceItem({
          'invoice_id': invoiceId,
          'material_id': item.materialId,
          'quantity': item.quantity,
          'net_weight': item.netWeight,
          'price': item.price,
          'total': item.total,
          'empties': item.empties,
          'collateral': item.collateral,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ الفاتورة بنجاح')),
        );
      }

      setState(() {
        _items.clear();
        _totalEstimate = 0;
        _commissionFee = 0;
        _loadingFee = 0;
        _carRent = 0;
        _otherExpenses = 0;
        _downPayment = 0;
        _netInvoice = 0;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في حفظ الفاتورة: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المبيعات حسب زبون'),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'مجموع التقدير: ${_totalEstimate.toStringAsFixed(2)} ل.س',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _selectCustomer,
                        icon: const Icon(Icons.person),
                        label: Text(_selectedCustomer?.name ?? 'اختر الزبون'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'مبيعات يوم $_currentDate للسيد ${_selectedCustomer?.name ?? "..."} المحترم - فاتورة رقم $_invoiceNumber - العامل $_employeeName',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // جدول العناصر
                    _items.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text('لا توجد عناصر'),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('مسلسل')),
                                DataColumn(label: Text('المادة')),
                                DataColumn(label: Text('العائدية')),
                                DataColumn(label: Text('س')),
                                DataColumn(label: Text('العدد')),
                                DataColumn(label: Text('السيرة')),
                                DataColumn(label: Text('القائم')),
                                DataColumn(label: Text('الصافي')),
                                DataColumn(label: Text('السعر')),
                                DataColumn(label: Text('الإجمالي')),
                                DataColumn(label: Text('الفوارغ')),
                                DataColumn(label: Text('الرهن')),
                                DataColumn(label: Text('حذف')),
                              ],
                              rows: _items.asMap().entries.map((entry) {
                                final index = entry.key;
                                final item = entry.value;
                                return DataRow(cells: [
                                  DataCell(Text('${index + 1}')),
                                  DataCell(Text(item.materialName ?? '')),
                                  DataCell(Text('')),
                                  DataCell(Text('')),
                                  DataCell(
                                      Text(item.quantity.toStringAsFixed(2))),
                                  DataCell(
                                      Text(item.netWeight.toStringAsFixed(2))),
                                  DataCell(
                                      Text(item.netWeight.toStringAsFixed(2))),
                                  DataCell(
                                      Text(item.netWeight.toStringAsFixed(2))),
                                  DataCell(Text(item.price.toStringAsFixed(2))),
                                  DataCell(Text(item.total.toStringAsFixed(2))),
                                  DataCell(
                                      Text(item.empties.toStringAsFixed(2))),
                                  DataCell(
                                      Text(item.collateral.toStringAsFixed(2))),
                                  DataCell(IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () {
                                      setState(() => _items.removeAt(index));
                                      _calculateTotal();
                                    },
                                  )),
                                ]);
                              }).toList(),
                            ),
                          ),

                    // مصاريف إضافية
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إضافة مصاريف على الفاتورة',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration: const InputDecoration(
                                    labelText: 'عائلة',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) {
                                    _commissionFee = double.tryParse(v) ?? 0;
                                    _calculateTotal();
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  decoration: const InputDecoration(
                                    labelText: 'تحديلة',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) {
                                    _loadingFee = double.tryParse(v) ?? 0;
                                    _calculateTotal();
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration: const InputDecoration(
                                    labelText: 'إجرة سيارة',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) {
                                    _carRent = double.tryParse(v) ?? 0;
                                    _calculateTotal();
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  decoration: const InputDecoration(
                                    labelText: 'مصاريف أخرى',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) {
                                    _otherExpenses = double.tryParse(v) ?? 0;
                                    _calculateTotal();
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'صافي الفاتورة: ${_netInvoice.toStringAsFixed(2)} ل.س',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'دفعة أولى (تخصم من الصافي)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (v) {
                              _downPayment = double.tryParse(v) ?? 0;
                              _calculateTotal();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: _selectCustomer,
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('زبون آخر'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit),
                    label: const Text('تعديل'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _items.isEmpty
                        ? null
                        : () {
                            setState(() {
                              _items.clear();
                              _totalEstimate = 0;
                              _commissionFee = 0;
                              _loadingFee = 0;
                              _carRent = 0;
                              _otherExpenses = 0;
                              _downPayment = 0;
                              _netInvoice = 0;
                            });
                          },
                    icon: const Icon(Icons.delete),
                    label: const Text('حذف'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _saveInvoice,
                    icon: const Icon(Icons.save),
                    label: const Text('حفظ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.print),
                    label: const Text('طباعة'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text('خروج'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
