// lib/services/fetcher_linux_webview.dart
//
// Linux-specific WebView widget backed by flutter_linux_webview (CEF).
// This file is only compiled/imported on Linux.
//
// Usage: imported via fetcher.dart as part of the _FetchWebView → _LinuxWebViewWidget chain.
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_linux_webview/flutter_linux_webview.dart';
import '../core/logger.dart';

bool _cefInitialized = false;

/// Lazily initializes the CEF (flutter_linux_webview) plugin.
/// Safe to call multiple times — only initializes once.
void ensureCefInitialized() {
  if (_cefInitialized) return;
  _cefInitialized = true;
  LinuxWebViewPlugin.initialize(options: {'no-sandbox': null});
  WebView.platform = LinuxWebView();
  logger.log('CEF (flutter_linux_webview) initialized lazily on first fetch');
}

/// Terminates the CEF (flutter_linux_webview) plugin when the app exits.
Future<void> terminateCef() async {
  if (!_cefInitialized) return;
  _cefInitialized = false;
  await LinuxWebViewPlugin.terminate();
  logger.log('CEF (flutter_linux_webview) terminated');
}

/// An invisible 1×1 px WebView widget (CEF-backed on Linux) that loads [url],
/// waits for the page to finish loading, then calls [onDone] with the HTML.
class LinuxWebViewWidget extends StatefulWidget {
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
  State<LinuxWebViewWidget> createState() => _LinuxWebViewWidgetState();
}

class _LinuxWebViewWidgetState extends State<LinuxWebViewWidget> {
  WebViewController? _controller;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    ensureCefInitialized();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1,
      height: 1,
      child: WebView(
        initialUrl: widget.url,
        javascriptMode: JavascriptMode.unrestricted,
        userAgent:
            'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        onWebViewCreated: (WebViewController controller) {
          _controller = controller;
        },
        onPageFinished: (url) async {
          if (_done) return;
          final controller = _controller;
          if (controller == null) return;
          try {
            final html = await controller.runJavascriptReturningResult(
              'document.documentElement.outerHTML',
            );
            // The result is a JS string literal; strip surrounding quotes.
            final cleaned = html.length >= 2 && html.startsWith('"')
                ? _unescapeJsString(html)
                : html;
            if (!_done && cleaned.isNotEmpty) {
              _done = true;
              widget.onDone(cleaned);
            } else if (!_done) {
              _done = true;
              widget.onError('Empty HTML from Linux WebView');
            }
          } catch (e) {
            if (!_done) {
              _done = true;
              widget.onError('Linux WebView JS error: $e');
            }
          }
        },
        onWebResourceError: (error) {
          if (!_done) {
            _done = true;
            widget.onError(
              'Linux WebView error: ${error.description} (${error.errorCode})',
            );
          }
        },
      ),
    );
  }

  /// Unescape a JSON-encoded JS string returned by runJavascriptReturningResult.
  String _unescapeJsString(String s) {
    // Strip surrounding quotes
    var result = s.substring(1, s.length - 1);
    // Unescape common JSON escape sequences
    result = result
        .replaceAll(r'\"', '"')
        .replaceAll(r'\\', r'\')
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\r', '\r')
        .replaceAll(r'\t', '\t');
    return result;
  }
}
