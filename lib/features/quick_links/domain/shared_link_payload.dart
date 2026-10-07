/// Parsed payload from an Android share intent (or pasted text).
class SharedLinkPayload {
  const SharedLinkPayload({
    required this.rawText,
    this.url,
    this.titleHint,
  });

  final String rawText;
  final String? url;
  final String? titleHint;

  static final _urlPattern = RegExp(
    r'https?://[^\s<>"\)]+',
    caseSensitive: false,
  );

  /// Extract the first http(s) URL and use remaining text as a title hint.
  static SharedLinkPayload parse(String raw) {
    final text = raw.trim();
    if (text.isEmpty) {
      return const SharedLinkPayload(rawText: '');
    }

    final match = _urlPattern.firstMatch(text);
    if (match == null) {
      // Entire body might be a bare domain or path-less share.
      final maybeUrl = text.contains(' ') ? null : text;
      return SharedLinkPayload(
        rawText: text,
        url: maybeUrl,
        titleHint: null,
      );
    }

    var url = match.group(0)!;
    // Trim common trailing punctuation from shares.
    url = url.replaceFirst(RegExp(r'[.,;:!?)]+$'), '');
    final before = text.substring(0, match.start).trim();
    final after = text.substring(match.end).trim();
    final titleParts = <String>[
      if (before.isNotEmpty) before,
      if (after.isNotEmpty) after,
    ];
    final titleHint = titleParts.isEmpty
        ? null
        : titleParts.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();

    return SharedLinkPayload(
      rawText: text,
      url: url,
      titleHint: (titleHint == null || titleHint.isEmpty) ? null : titleHint,
    );
  }
}
