import 'dart:async';

import 'package:flutter/services.dart';

import '../../features/quick_links/domain/shared_link_payload.dart';

/// Receives Android ACTION_SEND text/URL shares into SkyTask.
class ShareIntentService {
  ShareIntentService._();
  static final ShareIntentService instance = ShareIntentService._();

  static const _method = MethodChannel('com.skytask.app/share');
  static const _events = EventChannel('com.skytask.app/share_events');

  StreamSubscription<dynamic>? _sub;
  void Function(SharedLinkPayload payload)? _onShare;

  void startListening(void Function(SharedLinkPayload payload) onShare) {
    _onShare = onShare;
    _sub?.cancel();
    _sub = _events.receiveBroadcastStream().listen((event) {
      if (event is! String || event.trim().isEmpty) return;
      _onShare?.call(SharedLinkPayload.parse(event));
    });
  }

  /// Cold-start share (consumed once).
  Future<SharedLinkPayload?> takeInitialSharedLink() async {
    try {
      final raw = await _method.invokeMethod<String>('getInitialSharedText');
      if (raw == null || raw.trim().isEmpty) return null;
      return SharedLinkPayload.parse(raw);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    _onShare = null;
  }
}
