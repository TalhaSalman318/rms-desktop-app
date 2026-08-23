import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../app/app_theme.dart';
import '../../../shared/widgets/ui_components.dart';
import '../data/calendar_repository.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.repository});
  final CalendarRepository repository;
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime focused = DateTime.now();
  DateTime selected = DateTime.now();
  Map<DateTime, CalendarDay> days = {};
  bool loading = true;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    days = await widget.repository.month(focused);
    if (mounted) setState(() => loading = false);
  }

  CalendarDay get selectedData =>
      days[DateTime(selected.year, selected.month, selected.day)] ??
      const CalendarDay(orders: 0, sales: 0, expenses: 0);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(32, 20, 32, 32),
    child: Column(
      children: [
        const SectionHeader(
          title: 'Calendar',
          subtitle: 'Daily activity from orders and expenses.',
        ),
        const SizedBox(height: 20),
        Expanded(
          child: loading
              ? const Center(child: LoadingState(label: 'Loading calendar'))
              : Row(
                  children: [
                    Expanded(
                      child: AppCard(
                        child: TableCalendar<CalendarDay>(
                          firstDay: DateTime(2020),
                          lastDay: DateTime(2100),
                          focusedDay: focused,
                          selectedDayPredicate: (day) =>
                              isSameDay(day, selected),
                          onDaySelected: (day, focus) => setState(() {
                            selected = day;
                            focused = focus;
                          }),
                          onPageChanged: (day) {
                            focused = day;
                            load();
                          },
                          eventLoader: (day) {
                            final value =
                                days[DateTime(day.year, day.month, day.day)];
                            return value?.hasData == true ? [value!] : [];
                          },
                          calendarStyle: const CalendarStyle(
                            markerDecoration: BoxDecoration(
                              color: AppTheme.accent,
                              shape: BoxShape.circle,
                            ),
                            selectedDecoration: BoxDecoration(
                              color: AppTheme.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    SizedBox(width: 300, child: _details()),
                  ],
                ),
        ),
      ],
    ),
  );
  Widget _details() => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${selected.day}/${selected.month}/${selected.year}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 24),
        Text('Orders: ${selectedData.orders}'),
        Text('Sales: Rs. ${selectedData.sales.toStringAsFixed(2)}'),
        Text('Expenses: Rs. ${selectedData.expenses.toStringAsFixed(2)}'),
        const Divider(height: 28),
        Text(
          'Profit: Rs. ${selectedData.profit.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}
