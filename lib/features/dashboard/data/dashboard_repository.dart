import '../../../core/services/api_client.dart';

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
  DashboardRepository(this._api);
  final ApiClient _api;
  Future<DashboardStats> stats() async {
    final row = await _api.analyticsMap('dashboard', {});
    return DashboardStats(
      todaySales: (row['today_sales'] as num).toDouble(),
      todayOrders: (row['today_orders'] as num).toInt(),
      monthSales: (row['month_sales'] as num).toDouble(),
      monthExpenses: (row['month_expenses'] as num).toDouble(),
      yearSales: (row['year_sales'] as num).toDouble(),
    );
  }

  Future<List<Map<String, Object?>>> recentOrders() async {
    final row = await _api.analyticsMap('dashboard', {});
    return (row['recent_orders'] as List? ?? const [])
        .cast<Map>()
        .map((item) => Map<String, Object?>.from(item))
        .toList();
  }

  Future<List<Map<String, Object?>>> topProducts() async {
    final row = await _api.analyticsMap('dashboard', {});
    return (row['top_products'] as List? ?? const [])
        .cast<Map>()
        .map((item) => Map<String, Object?>.from(item))
        .toList();
  }
}
