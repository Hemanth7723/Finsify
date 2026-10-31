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
  static const Map<String, List<String>> _categoryKeywords = {
    'Food': [
      'food',
      'breakfast',
      'lunch',
      'dinner',
      'snack',
      'coffee',
      'tea',
      'groceries',
      'grocery',
      'restaurant',
      'pizza',
      'burger',
      'milk',
      'fruits',
      'vegetables',
      'cafe',
      'bakery',
      'meal',
      'biryani',
      'shawarma',
      'momos',
      'samosa',
      'fruit',
      'salad',
      'juice',
      'ice cream',
      'donut',
      'sandwich',
      'curry',
      'noodles',
      'mcdonalds',
      'starbucks',
      'zomato',
      'swiggy',
    ],
    'Transport': [
      'transport',
      'uber',
      'ola',
      'cab',
      'taxi',
      'bus',
      'train',
      'metro',
      'flight',
      'airfare',
      'fuel',
      'petrol',
      'diesel',
      'parking',
      'toll',
      'ride',
      'car',
      'auto',
      'rickshaw',
      'tram',
      'bike',
      'scooter',
      'fare',
      'ticket',
      'booking',
      'trip',
    ],
    'Entertainment': [
      'entertainment',
      'movie',
      'movies',
      'cinema',
      'streaming',
      'netflix',
      'spotify',
      'music',
      'game',
      'games',
      'concert',
      'theatre',
      'show',
      'festival',
      'subscription',
      'youtube',
      'prime video',
      'disney',
      'playstation',
      'concert ticket',
      'theater',
    ],
    'Shopping': [
      'shopping',
      'shop',
      'clothes',
      'shirt',
      'pants',
      'jeans',
      'shoes',
      'store',
      'market',
      'purchase',
      'buy',
      'bought',
      'ordered',
      'delivery',
      'amazon',
      'online',
      'mall',
      'retail',
      'cosmetics',
      'groceries',
      'apparel',
      'electronics',
      'gadget',
    ],
    'Health': [
      'health',
      'medicine',
      'medication',
      'doctor',
      'clinic',
      'hospital',
      'pharmacy',
      'insurance',
      'checkup',
      'vitamins',
      'therapy',
      'wellness',
      'supplement',
      'dentist',
      'lab test',
      'diagnostic',
      'eyewear',
    ],
    'Utilities': [
      'utilities',
      'electricity',
      'water',
      'internet',
      'wifi',
      'bill',
      'rent',
      'maintenance',
      'gas',
      'phone',
      'mobile',
      'airtel',
      'jio',
      'wifi bill',
      'electric bill',
      'power bill',
      'utility',
      'apartment rent',
    ],
  };

  static const Map<String, int> _numberWords = {
    'zero': 0,
    'one': 1,
    'two': 2,
    'three': 3,
    'four': 4,
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
    'ten': 10,
    'eleven': 11,
    'twelve': 12,
    'thirteen': 13,
    'fourteen': 14,
    'fifteen': 15,
    'sixteen': 16,
    'seventeen': 17,
    'eighteen': 18,
    'nineteen': 19,
    'twenty': 20,
    'thirty': 30,
    'forty': 40,
    'fifty': 50,
    'sixty': 60,
    'seventy': 70,
    'eighty': 80,
    'ninety': 90,
  };

  ParsedVoiceExpense? parse(String transcript) {
    final source = transcript.trim();
    if (source.isEmpty) return null;

    final normalized = source.replaceAll(',', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    final amount = _extractAmount(normalized);
    if (amount == null || amount <= 0) return null;

    final lower = normalized.toLowerCase();
    final category = _inferCategory(lower) ?? expenseCategories.last;
    final title = _buildTitle(normalized, category);

    return ParsedVoiceExpense(
      title: title.isEmpty ? category : title,
      amount: amount,
      category: category,
    );
  }

  double? _extractAmount(String transcript) {
    final text = transcript.toLowerCase();

    final numericMatch = RegExp(r'([0-9]+(?:\.[0-9]{1,2})?)').firstMatch(text);
    if (numericMatch != null) {
      final numeric = double.tryParse(numericMatch.group(1)!);
      if (numeric != null && numeric > 0) return numeric;
    }

    final wordMatches = RegExp(
      r'(?:zero|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety|hundred|thousand|lakh|crore)(?:\s+(?:and\s+)?(?:zero|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety|hundred|thousand|lakh|crore))*',
      caseSensitive: false,
    ).allMatches(text);

    for (final match in wordMatches) {
      final candidate = _parseNumberText(match.group(0)!);
      if (candidate != null && candidate > 0) {
        return candidate.toDouble();
      }
    }

    return null;
  }

  int? _parseNumberText(String text) {
    final cleaned = text
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
    if (cleaned.isEmpty) return null;

    if (RegExp(r'\d').hasMatch(cleaned)) {
      final numeric = double.tryParse(cleaned.replaceAll(RegExp(r'[^0-9.]'), ''));
      if (numeric != null && numeric > 0) return numeric.round();
    }

    int total = 0;
    int current = 0;
    final tokens = cleaned.replaceAll(' and ', ' ').split(RegExp(r'\s+'));

    for (final token in tokens) {
      if (token.isEmpty) continue;
      if (token == 'hundred') {
        current *= 100;
      } else if (token == 'thousand') {
        total += current * 1000;
        current = 0;
      } else if (token == 'lakh') {
        total += current * 100000;
        current = 0;
      } else if (token == 'crore') {
        total += current * 10000000;
        current = 0;
      } else {
        final value = _numberWords[token];
        if (value != null) {
          current += value;
        }
      }
    }

    total += current;
    return total > 0 ? total : null;
  }

  String? _inferCategory(String lowerCaseText) {
    for (final entry in _categoryKeywords.entries) {
      if (entry.value.any((keyword) => lowerCaseText.contains(keyword))) {
        return entry.key;
      }
    }
    return null;
  }

  String _buildTitle(String transcript, String category) {
    const stopWords = <String>{
      'i', 'me', 'my', 'mine', 'we', 'us', 'our', 'ours', 'you', 'your', 'yours',
      'it', 'its', 'this', 'that', 'these', 'those', 'here', 'there', 'was', 'were',
      'is', 'are', 'am', 'be', 'been', 'being', 'the', 'a', 'an', 'of', 'for', 'on',
      'at', 'to', 'from', 'with', 'using', 'in', 'and', 'or', 'by', 'into', 'out',
      'spent', 'spend', 'paid', 'pay', 'payment', 'purchase', 'purchased', 'buy',
      'bought', 'amount', 'total', 'cost', 'expense', 'entry', 'category',
      'rupees', 'rupee', 'rs', 'inr', 'dollar', 'usd', 'eur', 'euro', 'pound',
      'zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine',
      'ten', 'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen', 'sixteen',
      'seventeen', 'eighteen', 'nineteen', 'twenty', 'thirty', 'forty', 'fifty',
      'sixty', 'seventy', 'eighty', 'ninety', 'hundred', 'thousand', 'lakh', 'crore',
      'just', 'today', 'yesterday', 'now', 'got', 'had', 'have', 'has'
    };

    var cleaned = transcript
        .replaceAll(RegExp(r'rupees?|rs\.?|inr|dollar|usd|eur|euro|pound'), ' ')
        .replaceAll(RegExp(r'\b(?:spent|spend|paid|pay|payment|purchase|purchased|bought|buy|for|on|at|from|to|with|using|amount|total|cost|category|expense|entry)\b', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\b(?:food|transport|entertainment|shopping|health|utilities|miscellaneous)\b', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\b(?:zero|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety|hundred|thousand|lakh|crore)\b', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\b\d+(?:\.\d+)?\b'), ' ')
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final tokens = cleaned
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty && !stopWords.contains(token))
        .toList();

    var title = tokens.join(' ');
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    return title.isEmpty ? category : title;
  }
}
