import '../../../core/database/database_service.dart';

class ReportSummary {
  const ReportSummary({
    required this.orders,
    required this.sales,
    required this.expenses,
  });
  final int orders;
  final double sales;
  final double expenses;
  double get profit => sales - expenses;
}

class ReportRepository {
  ReportRepository(this.db);
  final DatabaseService db;
  Future<ReportSummary> summary(DateTime from, DateTime to) async {
    final o = await db.open().then(
      (d) => d.rawQuery(
        "SELECT COUNT(*) AS count, COALESCE(SUM(total_amount),0) AS sales FROM orders WHERE order_date >= ? AND order_date < ? AND status = 'Completed'",
        [from.toIso8601String(), to.toIso8601String()],
      ),
    );
    final e = await db.open().then(
      (d) => d.rawQuery(
        'SELECT COALESCE(SUM(amount),0) AS expenses FROM expenses WHERE expense_date >= ? AND expense_date < ?',
        [from.toIso8601String(), to.toIso8601String()],
      ),
    );
    return ReportSummary(
      orders: o.single['count'] as int,
      sales: (o.single['sales'] as num).toDouble(),
      expenses: (e.single['expenses'] as num).toDouble(),
    );
  }

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
    "SELECT c.name,SUM(oi.quantity) AS quantity,SUM(oi.subtotal) AS revenue FROM order_items oi JOIN products p ON p.id=oi.product_id JOIN categories c ON c.id=p.category_id JOIN orders o ON o.id=oi.order_id WHERE o.status='Completed' AND o.order_date >= ? AND o.order_date < ? GROUP BY c.id ORDER BY revenue DESC",
    [from.toIso8601String(), to.toIso8601String()],
  );
  Future<List<Map<String, Object?>>> trend(
    DateTime from,
    DateTime to,
  ) async => (await db.open()).rawQuery(
    "SELECT substr(order_date,1,10) AS day,COALESCE(SUM(total_amount),0) AS sales FROM orders WHERE status='Completed' AND order_date >= ? AND order_date < ? GROUP BY substr(order_date,1,10) ORDER BY day",
    [from.toIso8601String(), to.toIso8601String()],
  );
}
