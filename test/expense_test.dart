import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite_encrypted_expense_tracker/src/expense.dart';

void main() {
  test('parses currency amounts as cents', () {
    expect(parseAmountToCents('12.34'), 1234);
    expect(parseAmountToCents(' 9 '), 900);
  });

  test('rejects invalid expense amounts', () {
    expect(() => parseAmountToCents(''), throwsFormatException);
    expect(() => parseAmountToCents('-1'), throwsFormatException);
  });

  test('formats cents as currency', () {
    expect(formatCurrency(1234), r'$12.34');
  });
}
