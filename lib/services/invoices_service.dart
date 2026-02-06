import '../models/sales_model.dart';
import '../models/invoice_model.dart';
import '../models/receipt_model.dart';
import '../models/purchase_model.dart';
import 'sales_storage_service.dart';
import 'receipt_storage_service.dart';
import 'purchase_storage_service.dart';

// نموذج بسيط لبيانات المقارنة
class SupplierMovementSummary {
  final String material;
  double receiptCount;
  double salesCount;

  SupplierMovementSummary({
    required this.material,
    this.receiptCount = 0.0,
    this.salesCount = 0.0,
  });

  double get balance => receiptCount - salesCount;
}

// نموذج يحتوي على كل البيانات المطلوبة لشاشة المورد
class SupplierReportData {
  final List<InvoiceItem> sales;
  final List<Receipt> receipts;
  final List<SupplierMovementSummary> summary;

  SupplierReportData({
    required this.sales,
    required this.receipts,
    required this.summary,
  });
}

class InvoicesService {
  final SalesStorageService _salesStorageService = SalesStorageService();
  final ReceiptStorageService _receiptStorageService = ReceiptStorageService();
  final PurchaseStorageService _purchaseStorageService =
      PurchaseStorageService();

  // 1. دالة جلب فواتير الزبائن (الكود القديم)
  Future<List<InvoiceItem>> getInvoicesForCustomer(
      String date, String customerName) async {
    final SalesDocument? salesDocument =
        await _salesStorageService.loadSalesDocument(date);

    if (salesDocument == null || salesDocument.sales.isEmpty) {
      return [];
    }

    final List<InvoiceItem> customerInvoices = salesDocument.sales
        .where((sale) =>
            sale.customerName?.trim() == customerName.trim() &&
            sale.cashOrDebt == 'دين')
        .map((sale) => InvoiceItem(
              serialNumber: sale.serialNumber,
              material: sale.material,
              affiliation: sale.affiliation,
              count: sale.count,
              packaging: sale.packaging,
              standing: sale.standing,
              net: sale.net,
              price: sale.price,
              total: sale.total,
              empties: sale.empties,
              customerName: sale.customerName,
              sellerName: sale.sellerName,
            ))
        .toList();

    return customerInvoices;
  }

  // 2. دالة جديدة لجلب تقرير المورد الشامل (مبيعات + استلام + ملخص)
  Future<SupplierReportData> getSupplierReport(
      String date, String supplierName) async {
    final cleanSupplierName = supplierName.trim();
    List<InvoiceItem> supplierSales = [];
    List<Receipt> supplierReceipts = [];
    Map<String, SupplierMovementSummary> summaryMap = {};

    // أ) جلب المبيعات الخاصة بالمورد (حسب العائدية affiliation)
    final SalesDocument? salesDocument =
        await _salesStorageService.loadSalesDocument(date);

    if (salesDocument != null) {
      for (var sale in salesDocument.sales) {
        // التحقق من العائدية
        if (sale.affiliation.trim() == cleanSupplierName) {
          // إضافة للقائمة
          supplierSales.add(InvoiceItem(
            serialNumber: sale.serialNumber,
            material: sale.material,
            affiliation: sale.affiliation,
            count: sale.count,
            packaging: sale.packaging,
            standing: sale.standing,
            net: sale.net,
            price: sale.price,
            total: sale.total,
            empties: sale.empties,
            customerName: sale.customerName,
            sellerName: sale.sellerName,
          ));

          // تحديث الملخص (المبيعات)
          final material = sale.material.trim();
          if (material.isNotEmpty) {
            summaryMap.putIfAbsent(
                material, () => SupplierMovementSummary(material: material));
            summaryMap[material]!.salesCount +=
                double.tryParse(sale.count) ?? 0.0;
          }
        }
      }
    }

    // ب) جلب الاستلام الخاص بالمورد (حسب العائدية affiliation)
    final ReceiptDocument? receiptDocument =
        await _receiptStorageService.loadReceiptDocumentForDate(date);

    if (receiptDocument != null) {
      for (var receipt in receiptDocument.receipts) {
        // التحقق من العائدية
        if (receipt.affiliation.trim() == cleanSupplierName) {
          // إضافة للقائمة
          supplierReceipts.add(receipt);

          // تحديث الملخص (الاستلام)
          final material = receipt.material.trim();
          if (material.isNotEmpty) {
            summaryMap.putIfAbsent(
                material, () => SupplierMovementSummary(material: material));
            summaryMap[material]!.receiptCount +=
                double.tryParse(receipt.count) ?? 0.0;
          }
        }
      }
    }

    // ج) تحضير قائمة الملخص
    final summaryList = summaryMap.values.toList();
    summaryList.sort((a, b) => a.material.compareTo(b.material));

    return SupplierReportData(
      sales: supplierSales,
      receipts: supplierReceipts,
      summary: summaryList,
    );
  }

  // 3. دالة جديدة لجلب مشتريات مورد معين
  Future<List<Purchase>> getPurchasesForSupplier(
      String date, String supplierName) async {
    final PurchaseDocument? purchaseDocument =
        await _purchaseStorageService.loadPurchaseDocument(date);

    if (purchaseDocument == null || purchaseDocument.purchases.isEmpty) {
      return [];
    }

    // البحث في حقل العائدية (affiliation) - التصحيح
    final List<Purchase> supplierPurchases =
        purchaseDocument.purchases.where((purchase) {
      final purchaseAffiliation = purchase.affiliation.trim();
      final targetSupplierName = supplierName.trim();

      // إضافة طباعة للتشخيص
      if (purchaseAffiliation.isNotEmpty) {
        print('🔍 البحث في صف ${purchase.serialNumber}:');
        print('   العائدية في الملف: $purchaseAffiliation');
        print('   المورد المطلوب: $targetSupplierName');
        print('   المطابقة: ${purchaseAffiliation == targetSupplierName}');
      }

      // مقارنة مباشرة (دون حساسية لحالة الأحرف)
      return purchaseAffiliation.toLowerCase() ==
          targetSupplierName.toLowerCase();
    }).toList();

    // طباعة عدد النتائج للتشخيص
    print('📊 عدد مشتريات المورد $supplierName: ${supplierPurchases.length}');

    return supplierPurchases;
  }
}
