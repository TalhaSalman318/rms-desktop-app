import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import 'sidebar.dart';
import 'ui_components.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.pages, this.onLogout});

  static const String dashboardRoute = 'Dashboard';
  static const String settingsRoute = 'Settings';
  static const String categoriesRoute = 'Categories';
  static const String productsRoute = 'Products';
  static const String newOrderRoute = 'New Order';
  static const String ordersRoute = 'Orders';
  static const String expensesRoute = 'Expenses';
  static const String dealsRoute = 'Deals';
  static const String reportsRoute = 'Reports';
  static const String calendarRoute = 'Calendar';

  final Map<String, Widget> pages;
  final VoidCallback? onLogout;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  String _selectedRoute = AppShell.dashboardRoute;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 980;
    final page =
        widget.pages[_selectedRoute] ??
        SectionPlaceholder(title: '$_selectedRoute is coming soon');

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            Sidebar(
              selectedRoute: _selectedRoute,
              compact: isCompact,
              onLogout: widget.onLogout,
              onRouteSelected: (route) {
                setState(() => _selectedRoute = route);
              },
            ),
            Expanded(
              child: Column(
                children: [
                  _TopBar(compact: isCompact),
                  Expanded(child: page),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 20 : 32, 20, compact ? 20 : 32, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Good morning, Admin',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SearchField(width: 240),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () {},
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.accent,
            child: Text('A', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
