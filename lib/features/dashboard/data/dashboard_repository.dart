import '../../../core/database/database_service.dart';

class DashboardStats {
  const DashboardStats({
    required this.todaySales,
    required this.todayOrders,
    required this.monthSales,
    required this.monthExpenses,
    required this.yearSales,
  });
  final double todaySales;
  final int todayOrders;
  final double monthSales;
  final double monthExpenses;
  final double yearSales;
  double get monthProfit => monthSales - monthExpenses;
}

class DashboardRepository {
  DashboardRepository(this._database);
  final DatabaseService _database;
  Future<DashboardStats> stats() async {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final month = DateTime(now.year, now.month);
    final year = DateTime(now.year);
    final rows = await _database.open().then(
      (db) => db.rawQuery(
        'SELECT COALESCE(SUM(CASE WHEN order_date >= ? AND order_date < ? AND status = ? THEN total_amount ELSE 0 END),0) AS today_sales, COALESCE(SUM(CASE WHEN order_date >= ? AND order_date < ? AND status = ? THEN 1 ELSE 0 END),0) AS today_orders, COALESCE(SUM(CASE WHEN order_date >= ? AND order_date < ? AND status = ? THEN total_amount ELSE 0 END),0) AS month_sales, COALESCE(SUM(CASE WHEN order_date >= ? AND order_date < ? AND status = ? THEN total_amount ELSE 0 END),0) AS year_sales FROM orders',
        [
          day.toIso8601String(),
          day.add(const Duration(days: 1)).toIso8601String(),
          'Completed',
          day.toIso8601String(),
          day.add(const Duration(days: 1)).toIso8601String(),
          'Completed',
          month.toIso8601String(),
          DateTime(now.year, now.month + 1).toIso8601String(),
          'Completed',
          year.toIso8601String(),
          DateTime(now.year + 1).toIso8601String(),
          'Completed',
        ],
      ),
    );
    final expense = await _database.open().then(
      (db) => db.rawQuery(
        'SELECT COALESCE(SUM(amount),0) AS total FROM expenses WHERE expense_date >= ? AND expense_date < ?',
        [
          month.toIso8601String(),
          DateTime(now.year, now.month + 1).toIso8601String(),
        ],
      ),
    );
    final row = rows.single;
    return DashboardStats(
      todaySales: (row['today_sales'] as num).toDouble(),
      todayOrders: row['today_orders'] as int,
      monthSales: (row['month_sales'] as num).toDouble(),
      monthExpenses: (expense.single['total'] as num).toDouble(),
      yearSales: (row['year_sales'] as num).toDouble(),
    );
  }

  Future<List<Map<String, Object?>>>
  recentOrders() async => (await _database.open()).rawQuery(
    "SELECT order_number, order_date, total_amount, payment_method, status FROM orders WHERE status != 'Cancelled' ORDER BY order_date DESC LIMIT 5",
  );

  Future<List<Map<String, Object?>>>
  topProducts() async => (await _database.open()).rawQuery(
    "SELECT COALESCE(oi.deal_name, p.name) AS name, SUM(oi.quantity) AS quantity, SUM(oi.subtotal) AS revenue FROM order_items oi LEFT JOIN products p ON p.id = oi.product_id JOIN orders o ON o.id = oi.order_id WHERE o.status = 'Completed' GROUP BY COALESCE(oi.deal_name, p.name) ORDER BY quantity DESC LIMIT 5",
  );
}
