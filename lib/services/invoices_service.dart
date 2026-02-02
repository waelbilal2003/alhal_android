import '../models/sales_model.dart';
import '../models/invoice_model.dart';
import 'sales_storage_service.dart';

class InvoicesService {
  final SalesStorageService _salesStorageService = SalesStorageService();

  Future<List<InvoiceItem>> getInvoicesForCustomer(
      String date, String customerName) async {
    final SalesDocument? salesDocument =
        await _salesStorageService.loadSalesDocument(date);

    if (salesDocument == null || salesDocument.sales.isEmpty) {
      return [];
    }

    // تصفية المبيعات التي تخص الزبون المحدد وهي من نوع "دين"
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
}
