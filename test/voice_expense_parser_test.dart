import 'package:finsify/services/voice_expense_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final parser = VoiceExpenseParser();

  test('parses a spoken amount and infers a common expense category', () {
    final parsed = parser.parse('I spent 250 rupees on lunch');

    expect(parsed?.amount, 250);
    expect(parsed?.title, 'lunch');
    expect(parsed?.category, 'Food');
  });

  test('does not create an expense without a positive amount', () {
    expect(parser.parse('I bought groceries'), isNull);
    expect(parser.parse('Spent zero rupees on lunch'), isNull);
  });
}
