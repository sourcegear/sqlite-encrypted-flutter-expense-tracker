import 'package:flutter/material.dart';

import 'expense.dart';
import 'expense_repository.dart';

const expenseCategories = <String>[
  'Food',
  'Transport',
  'Home',
  'Health',
  'Other',
];

class ExpenseHomePage extends StatefulWidget {
  const ExpenseHomePage({super.key, required this.repository});

  final ExpenseRepository repository;

  @override
  State<ExpenseHomePage> createState() => _ExpenseHomePageState();
}

class _ExpenseHomePageState extends State<ExpenseHomePage> {
  List<Expense> _expenses = const [];
  String? _selectedCategory;
  Object? _startupError;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    widget.repository.close();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      await widget.repository.initialize();
      await _reload();
    } catch (error) {
      if (mounted) {
        setState(() {
          _startupError = error;
          _loading = false;
        });
      }
    }
  }

  Future<void> _reload() async {
    final expenses = await widget.repository.listExpenses(
      category: _selectedCategory,
    );
    if (mounted) {
      setState(() {
        _expenses = expenses;
        _loading = false;
      });
    }
  }

  Future<void> _selectCategory(String? category) async {
    setState(() {
      _selectedCategory = category;
      _loading = true;
    });
    await _reload();
  }

  Future<void> _showAddExpense() async {
    final draft = await showModalBottomSheet<_ExpenseDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _AddExpenseSheet(),
    );
    if (draft == null) return;

    await widget.repository.addExpense(
      merchant: draft.merchant,
      category: draft.category,
      amountCents: draft.amountCents,
      spentAt: DateTime.now(),
    );
    await _reload();
  }

  Future<void> _deleteExpense(Expense expense) async {
    await widget.repository.deleteExpense(expense.id);
    await _reload();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Deleted ${expense.merchant}.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Encrypted Expense Tracker'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 18),
            child: Tooltip(
              message: 'Expenses are stored in an encrypted SQLite database',
              child: Icon(Icons.lock_outline),
            ),
          ),
        ],
      ),
      floatingActionButton: _startupError == null && !_loading
          ? FloatingActionButton.extended(
              onPressed: _showAddExpense,
              icon: const Icon(Icons.add),
              label: const Text('Add expense'),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
              child: _buildBody(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_startupError != null) {
      return _StartupError(error: _startupError!);
    }

    final total = _expenses.fold<int>(
      0,
      (sum, expense) => sum + expense.amountCents,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TotalCard(totalCents: total, expenseCount: _expenses.length),
        const SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _selectedCategory == null,
                onSelected: (_) => _selectCategory(null),
              ),
              for (final category in expenseCategories) ...[
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(category),
                  selected: _selectedCategory == category,
                  onSelected: (_) => _selectCategory(category),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: _expenses.isEmpty
              ? const _EmptyExpenses()
              : ListView.separated(
                  itemCount: _expenses.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final expense = _expenses[index];
                    return _ExpenseTile(
                      expense: expense,
                      onDelete: () => _deleteExpense(expense),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.totalCents, required this.expenseCount});

  final int totalCents;
  final int expenseCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              child: const Icon(Icons.shield_outlined),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatCurrency(totalCents),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '$expenseCount encrypted ${expenseCount == 1 ? 'expense' : 'expenses'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.expense, required this.onDelete});

  final Expense expense;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: CircleAvatar(child: Icon(_categoryIcon(expense.category))),
        title: Text(
          expense.merchant,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${expense.category} · ${formatExpenseDate(expense.spentAt.toLocal())}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatCurrency(expense.amountCents),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            PopupMenuButton<void>(
              tooltip: 'Expense actions',
              itemBuilder: (_) => [
                PopupMenuItem<void>(
                  onTap: onDelete,
                  child: const Row(
                    children: [
                      Icon(Icons.delete_outline),
                      SizedBox(width: 10),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyExpenses extends StatelessWidget {
  const _EmptyExpenses();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 54,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            'No expenses yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          const Text('Add one to write your first encrypted record.'),
        ],
      ),
    );
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final message = error.toString().replaceFirst('Bad state: ', '');
    return Center(
      child: Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 42),
              const SizedBox(height: 12),
              Text(
                'SQLite.Encrypted could not start',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              SelectableText(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddExpenseSheet extends StatefulWidget {
  const _AddExpenseSheet();

  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _merchantController = TextEditingController();
  final _amountController = TextEditingController();
  String _category = expenseCategories.first;

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        4,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add expense',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _merchantController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Merchant'),
              textInputAction: TextInputAction.next,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a merchant.'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                try {
                  parseAmountToCents(value ?? '');
                  return null;
                } on FormatException catch (error) {
                  return error.message;
                }
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: expenseCategories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) => setState(() => _category = value!),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.lock_outline),
              label: const Text('Save encrypted expense'),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      _ExpenseDraft(
        merchant: _merchantController.text.trim(),
        category: _category,
        amountCents: parseAmountToCents(_amountController.text),
      ),
    );
  }
}

class _ExpenseDraft {
  const _ExpenseDraft({
    required this.merchant,
    required this.category,
    required this.amountCents,
  });

  final String merchant;
  final String category;
  final int amountCents;
}

IconData _categoryIcon(String category) {
  return switch (category) {
    'Food' => Icons.restaurant_outlined,
    'Transport' => Icons.directions_car_outlined,
    'Home' => Icons.home_outlined,
    'Health' => Icons.health_and_safety_outlined,
    _ => Icons.receipt_outlined,
  };
}
