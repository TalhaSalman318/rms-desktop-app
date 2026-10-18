import 'package:flutter/material.dart';
import '../../../app/app_theme.dart';
import '../../../data/models/database_models.dart';
import '../../../shared/widgets/ui_components.dart';
import '../data/expense_repository.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key, required this.repository});
  final ExpenseRepository repository;
  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final search = TextEditingController();
  List<Expense> rows = [];
  List<ExpenseCategory> cats = [];
  int? categoryId;
  DateTime? from;
  DateTime? to;
  bool loading = true;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      cats = await widget.repository.categories();
      rows = await widget.repository.expenses(
        search: search.text,
        categoryId: categoryId,
        from: from,
        to: to,
      );
      error = null;
    } catch (_) {
      error = 'Unable to load expenses.';
    }
    if (mounted) setState(() => loading = false);
  }

  Future<double> _total(DateTime a, DateTime b) =>
      widget.repository.total(from: a, to: b);
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        responsivePageInset(context),
        20,
        responsivePageInset(context),
        32,
      ),
      child: Column(
        children: [
          SectionHeader(
            title: 'Expenses',
            subtitle: 'Track operating costs from MongoDB Atlas.',
            action: Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                SecondaryButton(
                  label: 'Categories',
                  icon: Icons.category_outlined,
                  onPressed: _categoryDialog,
                ),
                PrimaryButton(
                  label: 'Add expense',
                  icon: Icons.add,
                  onPressed: () => _expenseDialog(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FutureBuilder(
            future: Future.wait([
              _total(day, day.add(const Duration(days: 1))),
              _total(
                DateTime(now.year, now.month),
                DateTime(now.year, now.month + 1),
              ),
              _total(DateTime(now.year), DateTime(now.year + 1)),
            ]),
            builder: (context, snapshot) => ResponsiveStatGrid(
              desktopColumns: 3,
              children: [
                StatCard(
                  label: "Today's expenses",
                  value: 'Rs. ${snapshot.data?[0].toStringAsFixed(2) ?? '--'}',
                  icon: Icons.today,
                ),
                StatCard(
                  label: 'Monthly expenses',
                  value: 'Rs. ${snapshot.data?[1].toStringAsFixed(2) ?? '--'}',
                  icon: Icons.calendar_month,
                ),
                StatCard(
                  label: 'Yearly expenses',
                  value: 'Rs. ${snapshot.data?[2].toStringAsFixed(2) ?? '--'}',
                  icon: Icons.auto_graph,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 700;
              final categoryIds = cats
                  .map((category) => category.id)
                  .whereType<int>()
                  .toList();
              final filters = [
                SearchField(
                  controller: search,
                  hint: 'Search description',
                  onChanged: (_) => load(),
                ),
                SizedBox(
                  width: narrow ? double.infinity : 210,
                  child: DropdownButtonFormField<int>(
                    initialValue: dropdownValueOrNull(categoryId, categoryIds),
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: [
                      const DropdownMenuItem<int>(
                        child: Text('All categories'),
                      ),
                      ...cats.map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      ),
                    ],
                    onChanged: (v) {
                      categoryId = v;
                      load();
                    },
                  ),
                ),
                SecondaryButton(
                  label: from == null ? 'Date' : '${from!.month}/${from!.day}',
                  icon: Icons.date_range,
                  onPressed: _dateFilter,
                ),
              ];
              return narrow
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        filters[0],
                        const SizedBox(height: 12),
                        filters[1],
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: filters[2],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: filters[0]),
                        const SizedBox(width: 12),
                        filters[1],
                        const SizedBox(width: 12),
                        filters[2],
                      ],
                    );
            },
          ),
          const SizedBox(height: 18),
          Expanded(child: SingleChildScrollView(child: _body())),
        ],
      ),
    );
  }

  Widget _body() {
    if (loading) {
      return const Center(child: LoadingState(label: 'Loading expenses'));
    }
    if (error != null) {
      return Center(
        child: EmptyState(
          title: 'Unable to load expenses',
          message: error!,
          icon: Icons.error_outline,
        ),
      );
    }
    if (rows.isEmpty) {
      return const AppCard(
        child: EmptyState(
          title: 'No expenses found',
          message: 'Add an expense or adjust your filters.',
          icon: Icons.payments_outlined,
        ),
      );
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: rows.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, color: AppTheme.border),
        itemBuilder: (context, i) {
          final e = rows[i];
          return ListTile(
            title: Text(
              'Rs. ${e.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              '${e.expenseDate.split('T').first}  •  ${e.description}',
            ),
            trailing: MediaQuery.sizeOf(context).width < 600
                ? PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') _expenseDialog(e);
                      if (value == 'delete') _delete(e);
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit expense')),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete expense'),
                      ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Edit expense',
                        onPressed: () => _expenseDialog(e),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Delete expense',
                        onPressed: () => _delete(e),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Future<void> _dateFilter() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: from ?? DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      from = DateTime(picked.year, picked.month, picked.day);
      to = from!.add(const Duration(days: 1));
    });
    load();
  }

  Future<void> _categoryDialog() async {
    final name = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Expense categories'),
        content: SizedBox(
          width: responsiveDialogWidth(context, 380),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...cats.map(
                  (c) => ListTile(
                    title: Text(c.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await _editCategory(c);
                          },
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          onPressed: () async {
                            if (await showConfirmationDialog(
                              context,
                              title: 'Delete ${c.name}?',
                              message:
                                  'This category can only be deleted if unused.',
                            )) {
                              try {
                                await widget.repository.deleteCategory(c);
                                if (ctx.mounted) Navigator.pop(ctx);
                                await load();
                              } on ExpenseCategoryInUseException {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'This category is used by an expense.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                ),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'New category'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          SecondaryButton(label: 'Close', onPressed: () => Navigator.pop(ctx)),
          PrimaryButton(
            label: 'Add',
            onPressed: () async {
              try {
                await widget.repository.saveCategory(name.text);
                if (ctx.mounted) Navigator.pop(ctx);
              } on ExpenseDuplicateException {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'A category with this name already exists.',
                      ),
                    ),
                  );
                }
              } on ExpenseValidationException catch (error) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(
                    ctx,
                  ).showSnackBar(SnackBar(content: Text(error.message)));
                }
              }
            },
          ),
        ],
      ),
    );
    name.dispose();
    load();
  }

  Future<void> _editCategory(ExpenseCategory category) async {
    final controller = TextEditingController(text: category.name);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit expense category'),
        content: TextField(controller: controller),
        actions: [
          SecondaryButton(
            label: 'Cancel',
            onPressed: () => Navigator.pop(dialogContext),
          ),
          PrimaryButton(
            label: 'Save',
            onPressed: () => Navigator.pop(dialogContext, controller.text),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    try {
      await widget.repository.saveCategory(value, existing: category);
      await load();
    } on ExpenseDuplicateException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A category with this name already exists.'),
          ),
        );
      }
    } on ExpenseValidationException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _expenseDialog([Expense? existing]) async {
    if (cats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create an expense category first.')),
      );
      return;
    }
    final amount = TextEditingController(text: existing?.amount.toString());
    final desc = TextEditingController(text: existing?.description);
    final categoryIds = cats
        .map((category) => category.id)
        .whereType<int>()
        .toList();
    var selected =
        dropdownValueOrNull(existing?.expenseCategoryId, categoryIds) ??
        categoryIds.first;
    final date = TextEditingController(
      text:
          existing?.expenseDate.split('T').first ??
          DateTime.now().toIso8601String().split('T').first,
    );
    final form = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(existing == null ? 'Add expense' : 'Edit expense'),
          content: Form(
            key: form,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: dropdownValueOrNull(selected, categoryIds),
                    items: cats
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => set(() => selected = v!),
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                  TextFormField(
                    controller: amount,
                    decoration: const InputDecoration(labelText: 'Amount'),
                    validator: (v) =>
                        double.tryParse(v ?? '') == null ||
                            double.parse(v ?? '') <= 0
                        ? 'Enter a valid amount.'
                        : null,
                  ),
                  TextField(
                    controller: desc,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  TextFormField(
                    controller: date,
                    decoration: const InputDecoration(
                      labelText: 'Date (YYYY-MM-DD)',
                    ),
                    validator: (value) => DateTime.tryParse(value ?? '') == null
                        ? 'Enter a valid date.'
                        : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            SecondaryButton(
              label: 'Cancel',
              onPressed: () => Navigator.pop(ctx, false),
            ),
            PrimaryButton(
              label: 'Save',
              onPressed: () async {
                if (!form.currentState!.validate()) return;
                try {
                  await widget.repository.save(
                    existing: existing,
                    categoryId: selected,
                    amount: double.parse(amount.text),
                    description: desc.text,
                    date: date.text,
                  );
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } on ExpenseValidationException catch (error) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(
                      ctx,
                    ).showSnackBar(SnackBar(content: Text(error.message)));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
    amount.dispose();
    desc.dispose();
    date.dispose();
    if (saved == true) {
      await load();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Expense saved.')));
      }
    }
  }

  Future<void> _delete(Expense e) async {
    if (await showConfirmationDialog(
      context,
      title: 'Delete expense?',
      message: 'Are you sure you want to delete this expense?',
    )) {
      await widget.repository.delete(e);
      await load();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Expense deleted.')));
      }
    }
  }
}
