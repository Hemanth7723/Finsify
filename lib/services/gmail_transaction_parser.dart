import 'package:flutter/foundation.dart';

import 'transaction_import_identity.dart';

/// Parses raw notification text from Gmail bank/UPI transaction messages.
///
/// All logic is pure Dart — no platform dependencies — making this class
/// fully unit-testable without mocking.
///
/// Returns [ParsedTransaction] for confident outgoing-debit notifications.
/// Returns `null` for OTPs, credits, failed/pending, promotional, or
/// ambiguous messages, and for notifications from non-Gmail packages.
class GmailTransactionParser {
  const GmailTransactionParser._();

  static const _gmailPackage = 'com.google.android.gm';

  static const _debitKeywords = <String>[
    'debited',
    'debit',
    'paid',
    'spent',
    'purchase',
    'payment of',
    'transaction of',
    'sent',
    'transferred',
  ];

  static const _skipKeywords = <String>[
    'otp',
    'one time password',
    'credited',
    'refund',
    'failed',
    'declined',
    'pending',
    'statement',
    'balance alert',
    'offer',
    'cashback',
    'congratulation',
    'reward',
    'win',
  ];

  static final _merchantPrepRe = RegExp(
    r'(?:for|at|to|towards|vpa)\s+([a-z0-9\s&.\-]+?)(?:\s+(?:on|ref|avl|bal|using|via|a\/c|card|\.|\,)|$)',
    caseSensitive: false,
  );

  // Matches: Rs.1,500 | ₹2000.50 | INR 500 | 1500 INR | 2000.50 Rs
  static final _amountRe = RegExp(
    r'(?:rs\.?|inr|₹)\s*([0-9]+(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)'
    r'|([0-9]+(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)\s*(?:inr|rs\.?|₹)',
    caseSensitive: false,
  );

  static final _noiseWordsRe = RegExp(
    r"\b(debited|debit|paid|spent|purchase|payment|transaction|"
    r"from|to|at|on|via|using|card|account|a\/c|inr|rs|"
    r"available|balance|avl|bal|your|dear|customer|sir|ma'am|"
    r"upi|neft|imps|rtgs|transfer|bank|savings|current)\b",
    caseSensitive: false,
  );

  static final _junkRe = RegExp(r'[*xX]{3,}\d+');
  static final _nonAlphanumRe = RegExp(r'[^a-zA-Z0-9 ]');
  static final _whitespaceRe = RegExp(r'\s+');

  /// Parses raw text from a bank/UPI transaction message (SMS or notification).
  ///
  /// Returns a record with `title`, `amount`, `category`, and optional
  /// `transactionReference`, or `null` if the text does not look like a debit.
  static ({
    String title,
    double amount,
    String category,
    String? transactionReference,
  })? parseTransactionText(String rawText, {String? defaultTitle}) {
    final body = rawText.toLowerCase();

    // Reject non-transaction or disqualifying messages
    if (_skipKeywords.any(body.contains)) return null;
    // Credit indicator check (disallowing incoming credits while allowing 'credit card')
    if (body.contains('credit') &&
        !body.contains('credit card') &&
        !body.contains('creditcard')) {
      return null;
    }
    if (!_debitKeywords.any(body.contains)) return null;

    final amount = _extractAmount(body);
    if (amount == null || amount <= 0) return null;

    final merchant = _cleanMerchantText(body);
    final category = _mapCategory(merchant, body);
    final resolvedTitle = merchant.isEmpty
        ? (defaultTitle ?? category)
        : _capitalise(merchant);

    return (
      title: resolvedTitle,
      amount: amount,
      category: category,
      transactionReference: extractUpiReference(rawText),
    );
  }

  /// Returns [ParsedTransaction] or `null`.
  ///
  /// [packageName] must equal `com.google.android.gm`; all other packages
  /// are rejected immediately without reading any content.
  static ParsedTransaction? parse({
    required String packageName,
    required String title,
    String? content,
    required DateTime timestamp,
  }) {
    if (packageName != _gmailPackage) return null;

    final rawText = '$title ${content ?? ''}';
    final body = rawText.toLowerCase();

    // Reject non-transaction or disqualifying messages
    if (_skipKeywords.any(body.contains)) return null;
    // Credit indicator check (disallowing incoming credits while allowing 'credit card')
    if (body.contains('credit') &&
        !body.contains('credit card') &&
        !body.contains('creditcard')) {
      return null;
    }
    if (!_debitKeywords.any(body.contains)) return null;

    final amount = _extractAmount(body);
    if (amount == null || amount <= 0) return null;

    final merchant = _extractMerchant(content, title, body);
    final category = _mapCategory(merchant, body);
    final fingerprint = _buildFingerprint(amount, merchant, timestamp);

    return ParsedTransaction(
      title: merchant.isEmpty ? 'Gmail Transaction' : _capitalise(merchant),
      amount: amount,
      category: category,
      timestamp: timestamp,
      fingerprint: fingerprint,
      transactionReference: extractUpiReference(rawText),
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static double? _extractAmount(String body) {
    final normalised = body.replaceAll(',', '');
    final m = _amountRe.firstMatch(normalised);
    if (m == null) return null;
    final raw = m.group(1) ?? m.group(2);
    return raw == null ? null : double.tryParse(raw);
  }

  static String _extractMerchant(String? content, String title, String body) {
    // 1. First attempt: check for explicit prepositional phrases in content/body
    // e.g. "for Swiggy order", "at Amazon Retail", "to Tata Power"
    final targetText = (content != null && content.isNotEmpty) ? content : body;
    final match = _merchantPrepRe.firstMatch(targetText);
    if (match != null) {
      final captured = match.group(1);
      if (captured != null && captured.trim().isNotEmpty) {
        final cleanedMatch = _cleanMerchantText(captured);
        if (cleanedMatch.isNotEmpty) {
          return cleanedMatch;
        }
      }
    }

    // 2. Fallback: clean the whole body and take leading meaningful words
    return _cleanMerchantText(body);
  }

  static String _cleanMerchantText(String raw) {
    final s1 = raw.replaceAll(_amountRe, ' ');
    final s2 = s1.replaceAll(_noiseWordsRe, ' ');
    final s3 = s2.replaceAll(_junkRe, '');
    final s4 = s3.replaceAll(_nonAlphanumRe, ' ');
    final cleaned = s4.replaceAll(_whitespaceRe, ' ').trim();

    final meaningful = cleaned
        .split(' ')
        .where((w) => w.length > 2)
        .take(4)
        .toList();

    return meaningful.join(' ').trim();
  }

  static String _mapCategory(String merchant, String body) {
    final lower = '$merchant $body'.toLowerCase();

    if (_containsAny(lower, [
      'fuel',
      'petrol',
      'diesel',
      'uber',
      'ola',
      'rapido',
      'metro',
      'train',
      'bus',
      'irctc',
      'redbus',
    ])) {
      return 'Transport';
    }

    if (_containsAny(lower, [
      'grocery',
      'restaurant',
      'swiggy',
      'zomato',
      'blinkit',
      'bigbasket',
      'dunzo',
      'zepto',
      'instamart',
      'food',
      'cafe',
      'hotel',
      'eat',
      'dine',
    ])) {
      return 'Food';
    }

    if (_containsAny(lower, [
      'pharmacy',
      'hospital',
      'clinic',
      'medical',
      'health',
      'doctor',
      'medicine',
      'lab',
      'diagnostic',
    ])) {
      return 'Health';
    }

    if (_containsAny(lower, [
      'electricity',
      'utility',
      'broadband',
      'internet',
      'mobile recharge',
      'recharge',
      'gas',
      'water bill',
      'tata power',
      'bses',
      'adani electricity',
    ])) {
      return 'Utilities';
    }

    if (_containsAny(lower, [
      'amazon',
      'flipkart',
      'myntra',
      'meesho',
      'nykaa',
      'ajio',
      'shopping',
      'store',
      'mart',
    ])) {
      return 'Shopping';
    }

    if (_containsAny(lower, [
      'netflix',
      'hotstar',
      'disney',
      'spotify',
      'prime video',
      'youtube',
      'zee5',
      'sonyliv',
      'jiocinema',
      'gaming',
    ])) {
      return 'Entertainment';
    }

    return 'Miscellaneous';
  }

  /// Stable fingerprint rounded to the nearest minute so that
  /// notification re-deliveries or grouped posts produce the same key.
  @visibleForTesting
  static String buildFingerprint(double amount, String merchant, DateTime ts) =>
      _buildFingerprint(amount, merchant, ts);

  static String _buildFingerprint(double amount, String merchant, DateTime ts) {
    final roundedMs = (ts.millisecondsSinceEpoch ~/ 60000) * 60000;
    final raw = '$amount|${merchant.toLowerCase().trim()}|$roundedMs';
    // Polynomial hash — stable, no crypto dependency.
    final hash = raw.codeUnits.fold(
      0,
      (int h, int c) => (h * 31 + c) & 0x7fffffff,
    );
    return hash.toRadixString(16).padLeft(8, '0');
  }

  static bool _containsAny(String text, List<String> keywords) =>
      keywords.any(text.contains);

  static String _capitalise(String s) {
    if (s.isEmpty) return s;
    return s
        .split(' ')
        .map((w) {
          if (w.isEmpty) return w;
          return '${w[0].toUpperCase()}${w.substring(1)}';
        })
        .join(' ');
  }
}

/// Holds the parsed fields from a single Gmail bank/UPI notification.
class ParsedTransaction {
  const ParsedTransaction({
    required this.title,
    required this.amount,
    required this.category,
    required this.timestamp,
    required this.fingerprint,
    required this.transactionReference,
  });

  final String title;
  final double amount;
  final String category;
  final DateTime timestamp;

  /// Stable deduplication key — same value for re-deliveries within a minute.
  final String fingerprint;
  final String? transactionReference;
}
