// lib/services/fetcher_linux_webview_stub.dart
//
// Stub implementation for non-Linux platforms.
// This file is selected by the conditional import in fetcher.dart when
// dart.library.io is available but Platform.isLinux is false (Android, iOS,
// macOS, Windows) — and also in unit tests running on the Dart VM.

import 'package:flutter/material.dart';
import '../core/logger.dart';

void ensureCefInitialized() {
  // No-op on non-Linux platforms.
}

Future<void> terminateCef() async {
  // No-op on non-Linux platforms.
}

/// Stub widget — should never be instantiated on non-Linux platforms.
class LinuxWebViewWidget extends StatelessWidget {
  final String url;
  final void Function(String html) onDone;
  final void Function(String error) onError;

  const LinuxWebViewWidget({
    super.key,
    required this.url,
    required this.onDone,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    logger.warn('LinuxWebViewWidget stub built — this should not happen');
    return const SizedBox.shrink();
  }
}
