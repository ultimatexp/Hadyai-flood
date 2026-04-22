class ContentFilterResult {
  final bool isAllowed;
  final String? matchedTerm;

  const ContentFilterResult._(this.isAllowed, this.matchedTerm);

  const ContentFilterResult.allowed() : this._(true, null);
  const ContentFilterResult.blocked(String matchedTerm)
      : this._(false, matchedTerm);
}

/// Lightweight client-side content filter.
///
/// This is not meant to be perfect; it exists to proactively reduce obvious
/// objectionable content and spam before it gets posted.
class ContentFilter {
  // Keep this list short and high-signal. Expand as needed.
  static const List<String> _blockedTerms = [
    // English (examples)
    'nude',
    'porn',
    'rape',
    'kill yourself',
    'kys',
    // Thai (examples)
    'ควย',
    'หี',
    'เย็ด',
    'ฆ่าตัวตาย',
  ];

  static ContentFilterResult checkText(String? text) {
    final normalized = (text ?? '').trim().toLowerCase();
    if (normalized.isEmpty) return const ContentFilterResult.allowed();

    for (final term in _blockedTerms) {
      if (normalized.contains(term)) {
        return ContentFilterResult.blocked(term);
      }
    }

    return const ContentFilterResult.allowed();
  }
}

