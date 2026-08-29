import 'package:flutter_test/flutter_test.dart';
import 'package:imrpo/core/models/parsed_financial_entry.dart';
import 'package:imrpo/core/services/natural_language_transaction_parser.dart';

void main() {
  final now = DateTime(2026, 8, 29, 12);

  group('NaturalLanguageTransactionParser', () {
    test('parses coffee amount as food expense', () {
      final entries = NaturalLanguageTransactionParser.parse(
        'coffee 50',
        now: now,
      );
      expect(entries, hasLength(1));
      expect(entries.first.type, FinancialEntryType.expense);
      expect(entries.first.amount, 50);
      expect(entries.first.title?.toLowerCase(), contains('coffee'));
      expect(entries.first.expenseCategory, 'Food');
    });

    test('parses salary as income', () {
      final entries = NaturalLanguageTransactionParser.parse(
        'salary 8000',
        now: now,
      );
      expect(entries, hasLength(1));
      expect(entries.first.type, FinancialEntryType.income);
      expect(entries.first.amount, 8000);
      expect(entries.first.incomeSource, 'Salary');
    });

    test('parses Arabic coffee', () {
      final entries = NaturalLanguageTransactionParser.parse(
        'قهوة 45',
        now: now,
      );
      expect(entries, hasLength(1));
      expect(entries.first.amount, 45);
      expect(entries.first.type, FinancialEntryType.expense);
      expect(entries.first.expenseCategory, 'Food');
    });

    test('parses Arabic salary', () {
      final entries = NaturalLanguageTransactionParser.parse(
        'راتب 8000',
        now: now,
      );
      expect(entries, hasLength(1));
      expect(entries.first.type, FinancialEntryType.income);
      expect(entries.first.amount, 8000);
    });

    test('parses multiple amounts in one sentence', () {
      final entries = NaturalLanguageTransactionParser.parse(
        'coffee 50 uber 30',
        now: now,
      );
      expect(entries, hasLength(2));
      expect(entries[0].amount, 50);
      expect(entries[0].expenseCategory, 'Food');
      expect(entries[1].amount, 30);
      expect(entries[1].expenseCategory, 'Transport');
    });

    test('parses yesterday as previous day', () {
      final entries = NaturalLanguageTransactionParser.parse(
        'uber 30 yesterday',
        now: now,
      );
      expect(entries, hasLength(1));
      expect(entries.first.date, DateTime(2026, 8, 28));
      expect(entries.first.expenseCategory, 'Transport');
    });

    test('detects visa as paid from', () {
      final entries = NaturalLanguageTransactionParser.parse(
        'lunch 80 with visa',
        now: now,
      );
      expect(entries.first.paidFrom, 'Visa Card');
    });

    test('uses preferred type when amount has no keywords', () {
      final income = NaturalLanguageTransactionParser.parse(
        '500',
        now: now,
        preferredType: FinancialEntryType.income,
      );
      expect(income.first.type, FinancialEntryType.income);

      final expense = NaturalLanguageTransactionParser.parse(
        '500',
        now: now,
        preferredType: FinancialEntryType.expense,
      );
      expect(expense.first.type, FinancialEntryType.expense);
    });

    test('parses Arabic digits', () {
      final entries = NaturalLanguageTransactionParser.parse(
        'قهوة ٥٠',
        now: now,
      );
      expect(entries, hasLength(1));
      expect(entries.first.amount, 50);
    });

    test('returns empty when there is no amount', () {
      expect(
        NaturalLanguageTransactionParser.parse('just coffee', now: now),
        isEmpty,
      );
    });
  });
}
