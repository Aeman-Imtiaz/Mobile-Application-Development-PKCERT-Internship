import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/models/expense_model.dart';

void main() {
  group('Expense model', () {
    test('fromMap correctly parses a database row', () {
      final map = {
        'id': 1,
        'userId': 'abc123',
        'type': 'cash_out',
        'amount': 500.0,
        'description': 'Lunch',
        'category': 'Food',
        'paymentMode': 'Cash',
        'contactName': '',
        'date': '2026-07-15',
      };

      final expense = Expense.fromMap(map);

      expect(expense.amount, 500.0);
      expect(expense.description, 'Lunch');
      expect(expense.category, 'Food');
      expect(expense.isCashOut, true);
      expect(expense.isCashIn, false);
    });

    test('signedAmount is negative for Cash Out, positive for Cash In', () {
      final expense1 = Expense(
        userId: 'u1', type: 'cash_out', amount: 300,
        description: 'Fuel', category: 'Fuel', paymentMode: 'Cash', date: '2026-07-15',
      );
      final expense2 = Expense(
        userId: 'u1', type: 'cash_in', amount: 1000,
        description: 'Salary', category: 'Income', paymentMode: 'Bank', date: '2026-07-15',
      );

      expect(expense1.signedAmount, -300);
      expect(expense2.signedAmount, 1000);
    });

    test('toMap converts back correctly', () {
      final expense = Expense(
        id: 5, userId: 'u1', type: 'cash_in', amount: 250,
        description: 'Refund', category: 'Income', paymentMode: 'Online', date: '2026-07-16',
      );

      final map = expense.toMap();

      expect(map['id'], 5);
      expect(map['amount'], 250);
      expect(map['type'], 'cash_in');
    });
  });
}