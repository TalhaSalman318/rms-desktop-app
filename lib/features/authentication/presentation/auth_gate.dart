import 'package:flutter/material.dart';

import '../../../data/database/sqlite_database_service.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/ui_components.dart';
import '../data/authentication_service.dart';
import '../../categories/data/category_repository.dart';
import '../../categories/presentation/category_controller.dart';
import '../../categories/presentation/category_screen.dart';
import '../../products/data/product_repository.dart';
import '../../products/presentation/product_controller.dart';
import '../../products/presentation/product_screen.dart';
import '../../orders/data/order_repository.dart';
import '../../orders/presentation/orders_screen.dart';
import '../../orders/presentation/pos_controller.dart';
import '../../orders/presentation/pos_screen.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../../expenses/data/expense_repository.dart';
import '../../expenses/presentation/expense_screen.dart';
import '../../deals/data/deal_repository.dart';
import '../../deals/presentation/deal_screen.dart';
import '../../reports/data/report_repository.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../calendar/data/calendar_repository.dart';
import '../../calendar/presentation/calendar_screen.dart';
import 'authentication_controller.dart';
import 'change_password_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, this.databaseService});

  final SqliteDatabaseService? databaseService;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthenticationController _controller;
  late final CategoryController _categoryController;
  late final ProductController _productController;
  late final OrderRepository _orderRepository;
  late final PosController _posController;
  late final DashboardRepository _dashboardRepository;
  late final ExpenseRepository _expenseRepository;
  late final DealRepository _dealRepository;
  late final ReportRepository _reportRepository;
  late final CalendarRepository _calendarRepository;

  @override
  void initState() {
    super.initState();
    final database = widget.databaseService ?? SqliteDatabaseService.instance;
    _controller = AuthenticationController(AuthenticationService(database));
    _categoryController = CategoryController(CategoryRepository(database));
    _productController = ProductController(ProductRepository(database));
    _orderRepository = OrderRepository(database);
    _posController = PosController(
      ProductRepository(database),
      _orderRepository,
      DealRepository(database),
    );
    _dashboardRepository = DashboardRepository(database);
    _expenseRepository = ExpenseRepository(database);
    _dealRepository = DealRepository(database);
    _reportRepository = ReportRepository(database);
    _calendarRepository = CalendarRepository(database);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    _categoryController.dispose();
    _productController.dispose();
    _posController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.isInitializing) {
          return const Scaffold(
            body: Center(child: LoadingState(label: 'Preparing workspace')),
          );
        }
        if (!_controller.isAuthenticated) {
          return LoginScreen(controller: _controller);
        }
        return AppShell(
          onLogout: _logout,
          pages: {
            AppShell.dashboardRoute: DashboardScreen(
              repository: _dashboardRepository,
            ),
            AppShell.settingsRoute: ChangePasswordScreen(
              controller: _controller,
            ),
            AppShell.categoriesRoute: CategoryScreen(
              controller: _categoryController,
            ),
            AppShell.productsRoute: ProductScreen(
              controller: _productController,
            ),
            AppShell.newOrderRoute: PosScreen(controller: _posController),
            AppShell.ordersRoute: OrdersScreen(repository: _orderRepository),
            AppShell.expensesRoute: ExpenseScreen(
              repository: _expenseRepository,
            ),
            AppShell.dealsRoute: DealScreen(
              repository: _dealRepository,
              products: ProductRepository(
                widget.databaseService ?? SqliteDatabaseService.instance,
              ),
            ),
            AppShell.reportsRoute: ReportsScreen(repository: _reportRepository),
            AppShell.calendarRoute: CalendarScreen(
              repository: _calendarRepository,
            ),
          },
        );
      },
    );
  }

  Future<void> _logout() async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Log out of SAVOR?',
      message: 'Your local data will remain safely stored on this device.',
    );
    if (confirmed) _controller.logout();
  }
}
