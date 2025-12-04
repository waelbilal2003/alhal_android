import 'package:flutter/material.dart';
import 'package:market_ledger/models/invoice_item_model.dart';
import 'package:market_ledger/models/material_model.dart';
import 'package:market_ledger/models/supplier_model.dart';
import 'package:market_ledger/services/database_helper.dart';

class CommissionSalesScreen extends StatefulWidget {
  const CommissionSalesScreen({super.key});

  @override
  State<CommissionSalesScreen> createState() => _CommissionSalesScreenState();
}

class _CommissionSalesScreenState extends State<CommissionSalesScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final List<InvoiceItemModel> _items = [];

  String _currentDate = DateTime.now().toIso8601String().split('T')[0];
  int _invoiceNumber = 1;
  String _employeeName = 'المدير العام';
  double _totalCash = 0;

  List<MaterialModel> _materials = [];
  List<SupplierModel> _suppliers = [];
  SupplierModel? _selectedSupplier;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final materialsData = await _db.getAllMaterials();
    _materials = materialsData.map((m) => MaterialModel.fromMap(m)).toList();

    final suppliersData = await _db.getAllSuppliers();
    _suppliers = suppliersData.map((s) => SupplierModel.fromMap(s)).toList();

    if (_suppliers.isNotEmpty) {
      _selectedSupplier = _suppliers.first;
    }

    final employees = await _db.getAllEmployees();
    if (employees.isNotEmpty) {
      _employeeName = employees.first['name'];
    }

    _invoiceNumber = await _db.getNextInvoiceNumber(_currentDate, 'كمسيون');
    setState(() {});
  }

  void _calculateTotal() {
    _totalCash = 0;
    for (var item in _items) {
      _totalCash += item.total;
    }
    setState(() {});
  }

  Future<void> _selectSupplier() async {
    final result = await showDialog<SupplierModel>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('اختر المورد'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _suppliers.map((supplier) {
              return ListTile(
                title: Text(supplier.name),
                onTap: () => Navigator.pop(context, supplier),
              );
            }).toList(),
          ),
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedSupplier = result;
      });
    }
  }

  Future<void> _addItem() async {
    if (_materials.isEmpty || _selectedSupplier == null) return;

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
            title: const Text('إضافة عنصر'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<MaterialModel>(
                    value: selectedMaterial,
                    decoration: const InputDecoration(labelText: 'المادة'),
                    items: _materials
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(m.name),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedMaterial = value;
                        price = value?.defaultPrice ?? 0;
                      });
                    },
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'العدد'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => quantity = double.tryParse(v) ?? 0,
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'السيرة'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => netWeight = double.tryParse(v) ?? 0,
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'السعر'),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: price.toString()),
                    onChanged: (v) => price = double.tryParse(v) ?? 0,
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'الفوارغ'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => empties = double.tryParse(v) ?? 0,
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'الرهن'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => collateral = double.tryParse(v) ?? 0,
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
      final newItem = InvoiceItemModel(
        invoiceId: 0,
        materialId: material.id!,
        quantity: result['quantity'],
        netWeight: result['netWeight'],
        price: result['price'],
        total: result['quantity'] * result['price'],
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
    if (_items.isEmpty || _selectedSupplier == null) return;

    try {
      final invoiceId = await _db.insertInvoice({
        'invoice_number': _invoiceNumber,
        'date': _currentDate,
        'supplier_id': _selectedSupplier!.id,
        'employee_id': 1,
        'type': 'كمسيون',
        'total_amount': _totalCash,
        'cash_amount': _totalCash,
        'net_amount': _totalCash,
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
        _totalCash = 0;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
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
          title: const Text('مبيعات الكمسيون (عمولة)'),
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
                        'مجموع النقدي: ${_totalCash.toStringAsFixed(2)} ل.س',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _selectSupplier,
                        icon: const Icon(Icons.person),
                        label: Text(_selectedSupplier?.name ?? 'اختر المورد'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'مبيعات يوم $_currentDate - فاتورة رقم $_invoiceNumber - المورد ${_selectedSupplier?.name ?? ""} - العامل $_employeeName',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _items.isEmpty
                  ? const Center(child: Text('لا توجد عناصر'))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('مسلسل')),
                          DataColumn(label: Text('المادة')),
                          DataColumn(label: Text('العدد')),
                          DataColumn(label: Text('السيرة')),
                          DataColumn(label: Text('القائم')),
                          DataColumn(label: Text('الصافي')),
                          DataColumn(label: Text('السعر')),
                          DataColumn(label: Text('الإجمالي')),
                          DataColumn(label: Text('نقدي/دين')),
                          DataColumn(label: Text('الفوارغ')),
                          DataColumn(label: Text('الرهن')),
                          DataColumn(label: Text('حذف')),
                        ],
                        rows: _items.asMap().entries.map((e) {
                          final item = e.value;
                          return DataRow(cells: [
                            DataCell(Text('${e.key + 1}')),
                            DataCell(Text(item.materialName ?? '')),
                            DataCell(Text(item.quantity.toStringAsFixed(2))),
                            DataCell(Text(item.netWeight.toStringAsFixed(2))),
                            DataCell(Text(item.netWeight.toStringAsFixed(2))),
                            DataCell(Text(item.netWeight.toStringAsFixed(2))),
                            DataCell(Text(item.price.toStringAsFixed(2))),
                            DataCell(Text(item.total.toStringAsFixed(2))),
                            DataCell(Text('نقدي')),
                            DataCell(Text(item.empties.toStringAsFixed(2))),
                            DataCell(Text(item.collateral.toStringAsFixed(2))),
                            DataCell(IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() => _items.removeAt(e.key));
                                _calculateTotal();
                              },
                            )),
                          ]);
                        }).toList(),
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
                    onPressed: _selectSupplier,
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('مورد آخر'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _saveInvoice,
                    icon: const Icon(Icons.save),
                    label: const Text('إنشاء'),
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
                              _totalCash = 0;
                            });
                          },
                    icon: const Icon(Icons.delete),
                    label: const Text('حذف'),
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
