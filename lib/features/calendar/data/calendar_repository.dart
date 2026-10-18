import '../../../core/services/api_client.dart';

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

class CalendarDetails {
  const CalendarDetails({required this.orders, required this.expenses});
  final List<Map<String, Object?>> orders;
  final List<Map<String, Object?>> expenses;
}

class CalendarRepository {
  CalendarRepository(this.db);
  final ApiClient db;
  Future<Map<DateTime, CalendarDay>> month(DateTime month) async {
    final start = DateTime(month.year, month.month),
        end = DateTime(month.year, month.month + 1);
    final data = await db.analyticsMap('calendar', {
      'from': start.toIso8601String(),
      'to': end.toIso8601String(),
    });
    final rows = (data['orders'] as List? ?? const []).cast<Map>();
    final expenses = (data['expenses'] as List? ?? const []).cast<Map>();
    final result = <DateTime, CalendarDay>{};
    for (final row in rows) {
      final date = DateTime.parse(
        (row['order_date'] as String).substring(0, 10),
      );
      result[date] = CalendarDay(
        orders: 1,
        sales: (row['total_amount'] as num).toDouble(),
        expenses: 0,
      );
    }
    for (final row in expenses) {
      final date = DateTime.parse(
        (row['expense_date'] as String).substring(0, 10),
      );
      final old = result[date];
      result[date] = CalendarDay(
        orders: old?.orders ?? 0,
        sales: old?.sales ?? 0,
        expenses: (row['amount'] as num).toDouble(),
      );
    }
    return result;
  }

  Future<CalendarDetails> details(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final data = await db.analyticsMap('calendar', {
      'from': start.toIso8601String(),
      'to': end.toIso8601String(),
    });
    final orders = (data['orders'] as List? ?? const [])
        .cast<Map>()
        .map((e) => Map<String, Object?>.from(e))
        .toList();
    final expenses = (data['expenses'] as List? ?? const [])
        .cast<Map>()
        .map((e) => Map<String, Object?>.from(e))
        .toList();
    return CalendarDetails(orders: orders, expenses: expenses);
  }
}
