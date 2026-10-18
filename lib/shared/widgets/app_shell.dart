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
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedRoute = AppShell.dashboardRoute;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 600;
    final isDesktop = width > 1100;
    final isCompact = !isDesktop;
    final page =
        widget.pages[_selectedRoute] ??
        SectionPlaceholder(title: '$_selectedRoute is coming soon');

    final content = Row(
      children: [
        if (!isMobile)
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
              _TopBar(
                compact: isCompact,
                mobile: isMobile,
                onMenu: isMobile
                    ? () => _scaffoldKey.currentState?.openDrawer()
                    : null,
              ),
              Expanded(child: page),
            ],
          ),
        ),
      ],
    );

    return Scaffold(
      key: _scaffoldKey,
      drawer: isMobile
          ? Drawer(
              child: SafeArea(
                child: Sidebar(
                  selectedRoute: _selectedRoute,
                  onLogout: widget.onLogout,
                  onRouteSelected: (route) {
                    setState(() => _selectedRoute = route);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            )
          : null,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppTheme.appGradient),
        child: SafeArea(child: content),
      ),
      bottomNavigationBar: isMobile
          ? _MobileNavigation(
              selectedRoute: _selectedRoute,
              onRouteSelected: (route) {
                if (route == 'More') {
                  _scaffoldKey.currentState?.openDrawer();
                } else {
                  setState(() => _selectedRoute = route);
                }
              },
            )
          : null,
    );
  }
}

class _MobileNavigation extends StatelessWidget {
  const _MobileNavigation({
    required this.selectedRoute,
    required this.onRouteSelected,
  });

  final String selectedRoute;
  final ValueChanged<String> onRouteSelected;

  static const _items = [
    ('Dashboard', Icons.grid_view_rounded),
    ('New Order', Icons.add_shopping_cart_rounded),
    ('Orders', Icons.receipt_long_rounded),
    ('Products', Icons.restaurant_menu_rounded),
    ('More', Icons.menu_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _items.indexWhere((item) => item.$1 == selectedRoute);
    return NavigationBar(
      selectedIndex: selectedIndex < 0 ? _items.length - 1 : selectedIndex,
      onDestinationSelected: (index) => onRouteSelected(_items[index].$1),
      destinations: [
        for (final item in _items)
          NavigationDestination(icon: Icon(item.$2), label: item.$1),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.compact, required this.mobile, this.onMenu});

  final bool compact;
  final bool mobile;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 20 : 32, 16, compact ? 20 : 32, 8),
      child: Row(
        children: [
          if (mobile) ...[
            IconButton(
              onPressed: onMenu,
              tooltip: 'Open navigation',
              icon: const Icon(Icons.menu_rounded),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                'Good morning, Admin',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          if (!mobile && !compact) const SearchField(width: 240),
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
