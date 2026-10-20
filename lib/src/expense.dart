class Expense {
  const Expense({
    required this.id,
    required this.merchant,
    required this.category,
    required this.amountCents,
    required this.spentAt,
  });

  final int id;
  final String merchant;
  final String category;
  final int amountCents;
  final DateTime spentAt;

  factory Expense.fromRow(Map<String, Object?> row) {
    return Expense(
      id: row['id']! as int,
      merchant: row['merchant']! as String,
      category: row['category']! as String,
      amountCents: row['amount_cents']! as int,
      spentAt: DateTime.parse(row['spent_at']! as String),
    );
  }
}

String formatCurrency(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';

String formatExpenseDate(DateTime date) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

int parseAmountToCents(String value) {
  final amount = double.tryParse(value.trim());
  if (amount == null || !amount.isFinite || amount <= 0) {
    throw const FormatException('Enter an amount greater than zero.');
  }
  return (amount * 100).round();
}
