import 'package:flutter_test/flutter_test.dart';
import 'package:skytask/features/quick_links/domain/shared_link_payload.dart';

void main() {
  group('SharedLinkPayload.parse', () {
    test('extracts url and title from shared post text', () {
      final p = SharedLinkPayload.parse(
        'Great article about productivity\nhttps://example.com/post/1',
      );
      expect(p.url, 'https://example.com/post/1');
      expect(p.titleHint, 'Great article about productivity');
    });

    test('handles url-only share', () {
      final p = SharedLinkPayload.parse('https://linkedin.com/posts/abc');
      expect(p.url, 'https://linkedin.com/posts/abc');
      expect(p.titleHint, isNull);
    });

    test('strips trailing punctuation from url', () {
      final p = SharedLinkPayload.parse('See this https://example.com/x).');
      expect(p.url, 'https://example.com/x');
    });
  });
}
