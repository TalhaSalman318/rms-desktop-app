import '../../../core/database/database_service.dart';

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
  final DatabaseService db;
  Future<ReportSummary> summary(DateTime from, DateTime to) async {
    final database = await db.open();
    final o = await database.rawQuery(
      "SELECT COUNT(*) AS total_orders, SUM(CASE WHEN status='Completed' THEN 1 ELSE 0 END) AS completed_orders, SUM(CASE WHEN status='Pending' THEN 1 ELSE 0 END) AS pending_orders, SUM(CASE WHEN status='Cancelled' THEN 1 ELSE 0 END) AS cancelled_orders, COALESCE(SUM(CASE WHEN status='Completed' THEN total_amount ELSE 0 END),0) AS sales, COALESCE(SUM(CASE WHEN status='Completed' THEN discount ELSE 0 END),0) AS discount FROM orders WHERE order_date >= ? AND order_date < ?",
      [from.toIso8601String(), to.toIso8601String()],
    );
    final e = await database.rawQuery(
      'SELECT COALESCE(SUM(amount),0) AS expenses FROM expenses WHERE expense_date >= ? AND expense_date < ?',
      [from.toIso8601String(), to.toIso8601String()],
    );
    final row = o.single;
    return ReportSummary(
      orders: (row['completed_orders'] as num?)?.toInt() ?? 0,
      sales: (row['sales'] as num).toDouble(),
      expenses: (e.single['expenses'] as num).toDouble(),
      totalOrders: (row['total_orders'] as num).toInt(),
      completedOrders: (row['completed_orders'] as num?)?.toInt() ?? 0,
      pendingOrders: (row['pending_orders'] as num?)?.toInt() ?? 0,
      cancelledOrders: (row['cancelled_orders'] as num?)?.toInt() ?? 0,
      discount: (row['discount'] as num).toDouble(),
    );
  }

  Future<ReportData> load(DateTime from, DateTime to) async => ReportData(
    summary: await summary(from, to),
    products: await products(from, to),
    payments: await payments(from, to),
    categories: await categories(from, to),
    expenseCategories: await expensesByCategory(from, to),
    trend: await trend(from, to),
  );

  Future<List<Map<String, Object?>>> products(
    DateTime from,
    DateTime to,
  ) async => (await db.open()).rawQuery(
    "SELECT COALESCE(oi.deal_name,p.name) AS name,SUM(oi.quantity) AS quantity,SUM(oi.subtotal) AS revenue FROM order_items oi LEFT JOIN products p ON p.id=oi.product_id JOIN orders o ON o.id=oi.order_id WHERE o.status='Completed' AND o.order_date >= ? AND o.order_date < ? GROUP BY COALESCE(oi.deal_name,p.name) ORDER BY revenue DESC",
    [from.toIso8601String(), to.toIso8601String()],
  );
  Future<List<Map<String, Object?>>> payments(
    DateTime from,
    DateTime to,
  ) async => (await db.open()).rawQuery(
    "SELECT payment_method,COUNT(*) AS orders,COALESCE(SUM(total_amount),0) AS revenue FROM orders WHERE status='Completed' AND order_date >= ? AND order_date < ? GROUP BY payment_method",
    [from.toIso8601String(), to.toIso8601String()],
  );
  Future<List<Map<String, Object?>>> categories(
    DateTime from,
    DateTime to,
  ) async => (await db.open()).rawQuery(
    "SELECT c.name,COALESCE(SUM(CASE WHEN o.id IS NOT NULL THEN oi.quantity ELSE 0 END),0) AS quantity,COALESCE(SUM(CASE WHEN o.id IS NOT NULL THEN oi.subtotal ELSE 0 END),0) AS revenue FROM categories c LEFT JOIN products p ON p.category_id=c.id LEFT JOIN order_items oi ON oi.product_id=p.id LEFT JOIN orders o ON o.id=oi.order_id AND o.status='Completed' AND o.order_date >= ? AND o.order_date < ? GROUP BY c.id ORDER BY revenue DESC,c.name COLLATE NOCASE",
    [from.toIso8601String(), to.toIso8601String()],
  );

  Future<List<Map<String, Object?>>> expensesByCategory(
    DateTime from,
    DateTime to,
  ) async => (await db.open()).rawQuery(
    'SELECT ec.name,COUNT(*) AS count,COALESCE(SUM(e.amount),0) AS amount FROM expenses e JOIN expense_categories ec ON ec.id=e.expense_category_id WHERE e.expense_date >= ? AND e.expense_date < ? GROUP BY ec.id ORDER BY amount DESC',
    [from.toIso8601String(), to.toIso8601String()],
  );
  Future<List<Map<String, Object?>>> trend(
    DateTime from,
    DateTime to,
  ) async => (await db.open()).rawQuery(
    "WITH days AS (SELECT substr(order_date,1,10) AS day FROM orders WHERE status='Completed' AND order_date >= ? AND order_date < ? UNION SELECT substr(expense_date,1,10) AS day FROM expenses WHERE expense_date >= ? AND expense_date < ?), sales AS (SELECT substr(order_date,1,10) AS day,COALESCE(SUM(total_amount),0) AS sales FROM orders WHERE status='Completed' AND order_date >= ? AND order_date < ? GROUP BY substr(order_date,1,10)), costs AS (SELECT substr(expense_date,1,10) AS day,COALESCE(SUM(amount),0) AS expenses FROM expenses WHERE expense_date >= ? AND expense_date < ? GROUP BY substr(expense_date,1,10)) SELECT days.day,COALESCE(sales.sales,0) AS sales,COALESCE(costs.expenses,0) AS expenses,COALESCE(sales.sales,0)-COALESCE(costs.expenses,0) AS profit FROM days LEFT JOIN sales ON sales.day=days.day LEFT JOIN costs ON costs.day=days.day ORDER BY days.day",
    [
      from.toIso8601String(),
      to.toIso8601String(),
      from.toIso8601String(),
      to.toIso8601String(),
      from.toIso8601String(),
      to.toIso8601String(),
      from.toIso8601String(),
      to.toIso8601String(),
    ],
  );
}
