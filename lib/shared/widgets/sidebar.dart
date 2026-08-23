import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.selectedRoute,
    required this.onRouteSelected,
    this.onLogout,
    this.compact = false,
  });

  final String selectedRoute;
  final ValueChanged<String> onRouteSelected;
  final VoidCallback? onLogout;
  final bool compact;

  static const _items = [
    _NavigationItem('Dashboard', Icons.grid_view_rounded),
    _NavigationItem('New Order', Icons.add_shopping_cart_rounded),
    _NavigationItem('Orders', Icons.receipt_long_rounded),
    _NavigationItem('Products', Icons.restaurant_menu_rounded),
    _NavigationItem('Categories', Icons.category_outlined),
    _NavigationItem('Deals', Icons.local_offer_outlined),
    _NavigationItem('Expenses', Icons.payments_outlined),
    _NavigationItem('Reports', Icons.bar_chart_rounded),
    _NavigationItem('Calendar', Icons.calendar_month_outlined),
    _NavigationItem('Settings', Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 84 : 240,
      color: AppTheme.surface,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 18,
        vertical: 22,
      ),
      child: Column(
        children: [
          _Brand(compact: compact),
          const SizedBox(height: 34),
          Expanded(
            child: ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, index) => index == 0
                  ? const SizedBox(height: 18)
                  : const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = _items[index];
                return NavigationItem(
                  label: item.label,
                  icon: item.icon,
                  selected: item.label == selectedRoute,
                  compact: compact,
                  onTap: () => onRouteSelected(item.label),
                );
              },
            ),
          ),
          NavigationItem(
            label: 'Logout',
            icon: Icons.logout_rounded,
            selected: false,
            compact: compact,
            onTap: onLogout ?? () {},
          ),
          const SizedBox(height: 12),
          if (!compact) const _AdminProfile(),
        ],
      ),
    );
  }
}

class NavigationItem extends StatelessWidget {
  const NavigationItem({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: compact ? label : '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 46,
          padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 14),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.accent.withAlpha(35)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: selected
                ? Border.all(color: AppTheme.accent.withAlpha(90))
                : null,
          ),
          child: Row(
            mainAxisAlignment: compact
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? AppTheme.accent : AppTheme.textSecondary,
              ),
              if (!compact) ...[
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: compact
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppTheme.accent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.restaurant_rounded, color: Colors.white),
        ),
        if (!compact) ...[
          const SizedBox(width: 12),
          const Text(
            'SAVOR',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

class _AdminProfile extends StatelessWidget {
  const _AdminProfile();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.accent,
            child: Text('A'),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Admin', style: TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  'Owner account',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationItem {
  const _NavigationItem(this.label, this.icon);

  final String label;
  final IconData icon;
}
