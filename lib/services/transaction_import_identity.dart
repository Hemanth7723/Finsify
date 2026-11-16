String? extractUpiReference(String text) {
  final match = RegExp(
    r'\bUPI\/[A-Z0-9]+\/([A-Z0-9]+)\/',
    caseSensitive: false,
  ).firstMatch(text);
  return match?.group(1)?.toUpperCase();
}
