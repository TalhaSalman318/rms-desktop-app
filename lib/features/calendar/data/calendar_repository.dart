import '../../../core/database/database_service.dart';

class CalendarDay {
  const CalendarDay({
    required this.orders,
    required this.sales,
    required this.expenses,
  });
  final int orders;
  final double sales;
  final double expenses;
  double get profit => sales - expenses;
  bool get hasData => orders > 0 || expenses > 0;
}

class CalendarRepository {
  CalendarRepository(this.db);
  final DatabaseService db;
  Future<Map<DateTime, CalendarDay>> month(DateTime month) async {
    final start = DateTime(month.year, month.month),
        end = DateTime(month.year, month.month + 1);
    final rows = await db.open().then(
      (d) => d.rawQuery(
        "SELECT substr(order_date,1,10) AS day,COUNT(*) AS orders,COALESCE(SUM(total_amount),0) AS sales FROM orders WHERE status='Completed' AND order_date>=? AND order_date<? GROUP BY substr(order_date,1,10)",
        [start.toIso8601String(), end.toIso8601String()],
      ),
    );
    final expenses = await db.open().then(
      (d) => d.rawQuery(
        'SELECT substr(expense_date,1,10) AS day,COALESCE(SUM(amount),0) AS expenses FROM expenses WHERE expense_date>=? AND expense_date<? GROUP BY substr(expense_date,1,10)',
        [start.toIso8601String(), end.toIso8601String()],
      ),
    );
    final result = <DateTime, CalendarDay>{};
    for (final row in rows) {
      final date = DateTime.parse(row['day'] as String);
      result[date] = CalendarDay(
        orders: row['orders'] as int,
        sales: (row['sales'] as num).toDouble(),
        expenses: 0,
      );
    }
    for (final row in expenses) {
      final date = DateTime.parse(row['day'] as String);
      final old = result[date];
      result[date] = CalendarDay(
        orders: old?.orders ?? 0,
        sales: old?.sales ?? 0,
        expenses: (row['expenses'] as num).toDouble(),
      );
    }
    return result;
  }
}
