import 'package:flutter/material.dart';
import 'package:market_ledger/models/invoice_item_model.dart';
import 'package:market_ledger/models/material_model.dart';
import 'package:market_ledger/services/database_helper.dart';

class MarketerSalesScreen extends StatefulWidget {
  const MarketerSalesScreen({super.key});

  @override
  State<MarketerSalesScreen> createState() => _MarketerSalesScreenState();
}

class _MarketerSalesScreenState extends State<MarketerSalesScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final List<InvoiceItemModel> _items = [];

  String _currentDate = DateTime.now().toIso8601String().split('T')[0];
  int _dailyNumber = 1;
  String _employeeName = 'المدير العام';
  double _totalSecondary = 0;

  List<MaterialModel> _materials = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final materialsData = await _db.getAllMaterials();
    _materials = materialsData.map((m) => MaterialModel.fromMap(m)).toList();

    final employees = await _db.getAllEmployees();
    if (employees.isNotEmpty) {
      _employeeName = employees.first['name'];
    }

    _dailyNumber = await _db.getNextDailyNumber(_currentDate);
    setState(() {});
  }

  void _calculateTotal() {
    _totalSecondary = 0;
    for (var item in _items) {
      _totalSecondary += item.total;
    }
    setState(() {});
  }

  Future<void> _addItem() async {
    if (_materials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد مواد متاحة')),
      );
      return;
    }

    MaterialModel? selectedMaterial = _materials.first;
    double quantity = 0;
    double netWeight = 0;
    double price = 0;
    double empties = 0;

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
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'العدد'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        quantity = double.tryParse(value) ?? 0,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'السيرة'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        netWeight = double.tryParse(value) ?? 0,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'السعر'),
                    keyboardType: TextInputType.number,
                    initialValue: price.toString(),
                    onChanged: (value) => price = double.tryParse(value) ?? 0,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'الفوارغ'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => empties = double.tryParse(value) ?? 0,
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

    try {
      final existingDaily = await _db.getDailyByDateAndNumber(
        _currentDate,
        _dailyNumber,
      );

      int dailyId;
      if (existingDaily == null) {
        dailyId = await _db.insertDaily({
          'daily_number': _dailyNumber,
          'date': _currentDate,
          'employee_id': 1,
          'total_cash': _totalSecondary,
          'total_debt': 0,
          'type': 'مسواق',
        });
      } else {
        dailyId = existingDaily['id'] as int;
      }

      final invoiceNumber =
          await _db.getNextInvoiceNumber(_currentDate, 'مسواق');
      final invoiceId = await _db.insertInvoice({
        'invoice_number': invoiceNumber,
        'date': _currentDate,
        'daily_id': dailyId,
        'employee_id': 1,
        'type': 'مسواق',
        'total_amount': _totalSecondary,
        'cash_amount': _totalSecondary,
        'net_amount': _totalSecondary,
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
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ الفاتورة بنجاح')),
        );
      }

      setState(() {
        _items.clear();
        _totalSecondary = 0;
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
          title: const Text('مبيعات المسواق'),
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
                        'مجموع الثانوي: ${_totalSecondary.toStringAsFixed(2)} ل.س',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'مبيعات يوم $_currentDate - يومية رقم $_dailyNumber - العامل $_employeeName',
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
                      child: SingleChildScrollView(
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
                            DataColumn(label: Text('تقدير/دين')),
                            DataColumn(label: Text('الفوارغ')),
                            DataColumn(label: Text('حذف')),
                          ],
                          rows: _items.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            return DataRow(
                              cells: [
                                DataCell(Text('${index + 1}')),
                                DataCell(Text(item.materialName ?? '')),
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
                                DataCell(Text('تقدير')),
                                DataCell(Text(item.empties.toStringAsFixed(2))),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        _items.removeAt(index);
                                      });
                                      _calculateTotal();
                                    },
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
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
                    onPressed: () {
                      // تعديل
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('تعديل'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _items.isEmpty
                        ? null
                        : () {
                            setState(() {
                              _items.clear();
                              _totalSecondary = 0;
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
