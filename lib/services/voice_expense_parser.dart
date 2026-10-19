import '../models/expense.dart';

class ParsedVoiceExpense {
  const ParsedVoiceExpense({
    required this.title,
    required this.amount,
    required this.category,
  });

  final String title;
  final double amount;
  final String category;
}

class VoiceExpenseParser {
  ParsedVoiceExpense? parse(String transcript) {
    final normalized = transcript.replaceAll(',', '');
    final amountMatch = RegExp(
      r'(?:₹|rs\.?|rupees?)?\s*([0-9]+(?:\.[0-9]{1,2})?)',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (amountMatch == null) return null;
    final amount = double.tryParse(amountMatch.group(1)!);
    if (amount == null || amount <= 0) return null;

    final lower = normalized.toLowerCase();
    final category =
        lower.contains(RegExp(r'\b(food|lunch|dinner|coffee|grocery)\b'))
        ? 'Food'
        : lower.contains(RegExp(r'\b(taxi|cab|bus|train|fuel|petrol)\b'))
        ? 'Transport'
        : lower.contains(RegExp(r'\b(movie|music|game|concert)\b'))
        ? 'Entertainment'
        : lower.contains(RegExp(r'\b(shop|clothes|shopping)\b'))
        ? 'Shopping'
        : lower.contains(RegExp(r'\b(medicine|doctor|hospital)\b'))
        ? 'Health'
        : lower.contains(RegExp(r'\b(electricity|water|internet|bill)\b'))
        ? 'Utilities'
        : expenseCategories.last;
    final title = normalized
        .replaceFirst(amountMatch.group(0)!, ' ')
        .replaceAll(
          RegExp(
            r'\b(i|spent|spend|paid|pay|for|on|rupees?|rs\.?)\b',
            caseSensitive: false,
          ),
          ' ',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return ParsedVoiceExpense(
      title: title.isEmpty ? category : title,
      amount: amount,
      category: category,
    );
  }
}
