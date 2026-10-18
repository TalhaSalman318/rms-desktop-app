import '../../../core/services/api_client.dart';

class ReportSummary {
  const ReportSummary({
    required this.orders,
    required this.sales,
    required this.expenses,
    this.totalOrders = 0,
    this.completedOrders = 0,
    this.pendingOrders = 0,
    this.cancelledOrders = 0,
    this.discount = 0,
  });
  final int orders;
  final double sales;
  final double expenses;
  final int totalOrders;
  final int completedOrders;
  final int pendingOrders;
  final int cancelledOrders;
  final double discount;
  double get profit => sales - expenses;
  double get averageOrderValue =>
      completedOrders == 0 ? 0 : sales / completedOrders;
}

class ReportData {
  const ReportData({
    required this.summary,
    required this.products,
    required this.payments,
    required this.categories,
    required this.expenseCategories,
    required this.trend,
  });

  final ReportSummary summary;
  final List<Map<String, Object?>> products;
  final List<Map<String, Object?>> payments;
  final List<Map<String, Object?>> categories;
  final List<Map<String, Object?>> expenseCategories;
  final List<Map<String, Object?>> trend;
}

class ReportRepository {
  ReportRepository(this.db);
  final ApiClient db;
  Future<ReportSummary> summary(DateTime from, DateTime to) async {
    final row = await db.analyticsMap('reports', {
      'from': from.toIso8601String(),
      'to': to.toIso8601String(),
    });
    final summary = Map<String, Object?>.from(row['summary'] as Map);
    return ReportSummary(
      orders: (summary['completed_orders'] as num?)?.toInt() ?? 0,
      sales: (summary['sales'] as num).toDouble(),
      expenses: (summary['expenses'] as num).toDouble(),
      totalOrders: (summary['total_orders'] as num).toInt(),
      completedOrders: (summary['completed_orders'] as num?)?.toInt() ?? 0,
      pendingOrders: (summary['pending_orders'] as num?)?.toInt() ?? 0,
      cancelledOrders: (summary['cancelled_orders'] as num?)?.toInt() ?? 0,
      discount: (summary['discount'] as num).toDouble(),
    );
  }

  Future<ReportData> load(DateTime from, DateTime to) async {
    final row = await db.analyticsMap('reports', {
      'from': from.toIso8601String(),
      'to': to.toIso8601String(),
    });
    List<Map<String, Object?>> values(String key) =>
        (row[key] as List? ?? const [])
            .cast<Map>()
            .map((e) => Map<String, Object?>.from(e))
            .toList();
    final summaryRow = Map<String, Object?>.from(row['summary'] as Map);
    return ReportData(
      summary: ReportSummary(
        orders: (summaryRow['completed_orders'] as num?)?.toInt() ?? 0,
        sales: (summaryRow['sales'] as num).toDouble(),
        expenses: (summaryRow['expenses'] as num).toDouble(),
        totalOrders: (summaryRow['total_orders'] as num).toInt(),
        completedOrders: (summaryRow['completed_orders'] as num?)?.toInt() ?? 0,
        pendingOrders: (summaryRow['pending_orders'] as num?)?.toInt() ?? 0,
        cancelledOrders: (summaryRow['cancelled_orders'] as num?)?.toInt() ?? 0,
        discount: (summaryRow['discount'] as num).toDouble(),
      ),
      products: values('products'),
      payments: values('payments'),
      categories: values('categories'),
      expenseCategories: values('expense_categories'),
      trend: values('trend'),
    );
  }

  Future<List<Map<String, Object?>>> products(
    DateTime from,
    DateTime to,
  ) async => _reportList(from, to, 'products');
  Future<List<Map<String, Object?>>> payments(
    DateTime from,
    DateTime to,
  ) async => _reportList(from, to, 'payments');
  Future<List<Map<String, Object?>>> categories(
    DateTime from,
    DateTime to,
  ) async => _reportList(from, to, 'categories');

  Future<List<Map<String, Object?>>> expensesByCategory(
    DateTime from,
    DateTime to,
  ) async => _reportList(from, to, 'expense_categories');
  Future<List<Map<String, Object?>>> trend(DateTime from, DateTime to) async =>
      _reportList(from, to, 'trend');

  Future<List<Map<String, Object?>>> _reportList(
    DateTime from,
    DateTime to,
    String key,
  ) async {
    final row = await db.analyticsMap('reports', {
      'from': from.toIso8601String(),
      'to': to.toIso8601String(),
    });
    return (row[key] as List? ?? const [])
        .cast<Map>()
        .map((item) => Map<String, Object?>.from(item))
        .toList();
  }
}
