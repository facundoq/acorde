import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import '../core/logger.dart';

// Conditional import: on Linux we load the real CEF WebView widget;
// on all other native platforms we load the no-op stub so the file
// compiles without requiring flutter_linux_webview / webview_flutter.
//
// Note: tests run on the host VM with Platform.isLinux == true on Linux CI,
// so the stub is selected via `show LinuxWebViewWidget` when
import 'fetcher_linux_webview.dart'
    if (dart.library.html) 'fetcher_linux_webview_stub.dart'
    show LinuxWebViewWidget, terminateCef;

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/// Fetches the fully-rendered HTML for [url].
///
/// Platform strategy:
///   Web     → plain HTTP (CORS handled by server/proxy)
///   Linux   → flutter_linux_webview (CEF-based) via an invisible overlay
///              WebView; requires [fetcherNavigatorKey] to be wired to the
///              MaterialApp. Falls back to headless Chromium subprocess, then
///              plain HTTP if neither is available.
///   Others  → HeadlessInAppWebView (flutter_inappwebview)
Future<String> fetchHtml(String url) async {
  if (kIsWeb) {
    return _fetchHttp(url);
  }

  if (!kIsWeb && Platform.isLinux) {
    return _fetchOnLinux(url);
  }

  return _fetchWithInAppWebView(url);
}

/// Terminates the Linux WebView plugin (CEF) if it was initialized.
/// Should be called on application exit on Linux desktop.
Future<void> terminateLinuxWebView() async {
  if (!kIsWeb && Platform.isLinux) {
    await terminateCef();
  }
}

// ---------------------------------------------------------------------------
// Linux: three-tier fetch strategy
// ---------------------------------------------------------------------------

/// A [GlobalKey<NavigatorState>] connected to the root [MaterialApp].
/// Wire this in [MyApp]: `navigatorKey: fetcherNavigatorKey`.
///
/// When set, the Linux fetcher can mount an invisible overlay WebView
/// (CEF-backed via flutter_linux_webview) that bypasses Cloudflare and
/// other bot-detection systems, because CEF renders as a real browser.
///
/// If null, the fetcher falls back to headless Chromium → plain HTTP.
final GlobalKey<NavigatorState> fetcherNavigatorKey =
    GlobalKey<NavigatorState>();

Future<String> _fetchOnLinux(String url) async {
  // Tier 1: invisible overlay WebView via flutter_linux_webview (CEF)
  final nav = fetcherNavigatorKey.currentState;
  if (nav != null && nav.overlay != null) {
    try {
      logger.log('fetchHtml: using Linux CEF overlay WebView for $url');
      return await _fetchWithLinuxOverlay(url, nav.overlay!);
    } catch (e) {
      logger.warn(
        'fetchHtml: Linux overlay WebView failed ($e); trying headless Chrome',
      );
    }
  } else {
    logger.warn(
      'fetchHtml: fetcherNavigatorKey not ready; skipping overlay WebView',
    );
  }

  // Tier 2: headless Chromium subprocess (works for non-Cloudflare sites)
  logger.log('fetchHtml: using headless Chromium for $url');
  return await _fetchWithHeadlessChromium(url);
}

// ---------------------------------------------------------------------------
// Linux Tier 1: invisible overlay WebView (CEF via flutter_linux_webview)
// ---------------------------------------------------------------------------

Future<String> _fetchWithLinuxOverlay(
  String url,
  OverlayState overlayState,
) async {
  final completer = Completer<String>();
  late final OverlayEntry entry;
  bool removed = false;
  void removeEntry() {
    if (!removed) {
      removed = true;
      entry.remove();
    }
  }

  entry = OverlayEntry(
    builder: (_) => Positioned(
      // Position far off-screen so the widget is never visible.
      left: -4000,
      top: -4000,
      width: 1,
      height: 1,
      child: LinuxWebViewWidget(
        url: url,
        onDone: (html) {
          if (!completer.isCompleted) completer.complete(html);
          removeEntry();
        },
        onError: (err) {
          if (!completer.isCompleted) {
            completer.completeError(Exception(err));
          }
          removeEntry();
        },
      ),
    ),
  );

  overlayState.insert(entry);

  try {
    return await completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        removeEntry();
        throw TimeoutException('Linux overlay WebView timed out for $url');
      },
    );
  } catch (e) {
    removeEntry();
    rethrow;
  }
}

// ---------------------------------------------------------------------------
// Linux Tier 2: headless Chromium subprocess
// ---------------------------------------------------------------------------

const _chromiumBinaries = [
  'chromium-browser',
  'chromium',
  'google-chrome-stable',
  'google-chrome',
];

Future<String> _fetchWithHeadlessChromium(String url) async {
  for (final binary in _chromiumBinaries) {
    try {
      final result =
          await Process.run(binary, [
            '--headless',
            '--disable-gpu',
            '--no-sandbox',
            '--disable-setuid-sandbox',
            '--disable-dev-shm-usage',
            '--disable-blink-features=AutomationControlled',
            '--dump-dom',
            '--user-agent=Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 '
                '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
            url,
          ], runInShell: false).timeout(
            const Duration(seconds: 30),
            onTimeout: () =>
                throw TimeoutException('headless $binary timed out for $url'),
          );

      final out = result.stdout as String;
      if (result.exitCode == 0 && out.trim().isNotEmpty) {
        logger.log('fetchHtml: headless $binary succeeded for $url');
        return out;
      }

      final err = (result.stderr as String).trim();
      if (err.isNotEmpty) {
        logger.warn('fetchHtml: $binary exited ${result.exitCode}: $err');
      }
    } on ProcessException catch (e) {
      logger.warn('fetchHtml: $binary not available: $e');
    } catch (e) {
      logger.warn('fetchHtml: $binary failed: $e');
    }
  }

  logger.warn(
    'fetchHtml: no headless Chromium found. '
    'Install chromium-browser for improved scraping. Falling back to HTTP.',
  );
  throw Exception('No headless Chromium binary found on PATH');
}

// ---------------------------------------------------------------------------
// Mobile / macOS / non-Linux native: flutter_inappwebview headless WebView
// ---------------------------------------------------------------------------

Future<String> _fetchWithInAppWebView(String url) async {
  // Tier 1: Try overlay WebView if navigator overlay is ready (avoids Cloudflare/Turnstile blocks)
  final nav = fetcherNavigatorKey.currentState;
  if (nav != null && nav.overlay != null) {
    try {
      logger.log('fetchHtml: using mobile overlay WebView for $url');
      return await _fetchWithMobileOverlay(url, nav.overlay!);
    } catch (e) {
      logger.warn(
        'fetchHtml: mobile overlay WebView failed ($e); trying headless InAppWebView',
      );
    }
  } else {
    logger.warn(
      'fetchHtml: fetcherNavigatorKey not ready; skipping mobile overlay WebView',
    );
  }

  // Tier 2: Headless InAppWebView fallback
  return _fetchWithHeadlessInAppWebView(url);
}

Future<String> _fetchWithMobileOverlay(
  String url,
  OverlayState overlayState,
) async {
  final completer = Completer<String>();
  late final OverlayEntry entry;
  bool removed = false;
  void removeEntry() {
    if (!removed) {
      removed = true;
      entry.remove();
    }
  }

  entry = OverlayEntry(
    builder: (_) => Positioned(
      left: -4000,
      top: -4000,
      width: 1024,
      height: 768,
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.01,
          child: MobileWebViewWidget(
            url: url,
            onDone: (html) {
              if (!completer.isCompleted) completer.complete(html);
              removeEntry();
            },
            onError: (err) {
              if (!completer.isCompleted) {
                completer.completeError(Exception(err));
              }
              removeEntry();
            },
          ),
        ),
      ),
    ),
  );

  overlayState.insert(entry);

  try {
    return await completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        removeEntry();
        throw TimeoutException('Mobile overlay WebView timed out for $url');
      },
    );
  } catch (e) {
    removeEntry();
    rethrow;
  }
}

Future<String> _fetchWithHeadlessInAppWebView(String url) async {
  final completer = Completer<String>();
  HeadlessInAppWebView? headlessWebView;

  final userScripts = UnmodifiableListView<UserScript>([
    UserScript(
      source:
          "Object.defineProperty(navigator, 'webdriver', {get: () => undefined});",
      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
    ),
  ]);

  try {
    headlessWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(url)),
      initialUserScripts: userScripts,
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        domStorageEnabled: true,
        useShouldInterceptRequest: !kIsWeb && Platform.isAndroid,
        contentBlockers: (!kIsWeb && (Platform.isIOS || Platform.isMacOS))
            ? [
                // Block known ad/tracking domains to save memory and avoid renderer crashes
                ContentBlocker(
                  trigger: ContentBlockerTrigger(
                    urlFilter:
                        ".*doubleclick\\.net.*|.*googleads.*|.*googlesyndication.*|.*securepubads.*|.*google-analytics.*|.*analytics.*|.*amazon-adsystem.*|.*taboola.*",
                  ),
                  action: ContentBlockerAction(
                    type: ContentBlockerActionType.BLOCK,
                  ),
                ),
                // Block images and media since we only need the HTML DOM text
                ContentBlocker(
                  trigger: ContentBlockerTrigger(
                    urlFilter: ".*",
                    resourceType: [
                      ContentBlockerTriggerResourceType.IMAGE,
                      ContentBlockerTriggerResourceType.MEDIA,
                    ],
                  ),
                  action: ContentBlockerAction(
                    type: ContentBlockerActionType.BLOCK,
                  ),
                ),
              ]
            : null,
      ),
      shouldInterceptRequest: (controller, request) async {
        final urlStr = request.url.toString();
        // Block known ad/tracking domains to save memory & avoid renderer crashes
        if (urlStr.contains('doubleclick.net') ||
            urlStr.contains('googleads') ||
            urlStr.contains('googlesyndication') ||
            urlStr.contains('securepubads') ||
            urlStr.contains('google-analytics') ||
            urlStr.contains('analytics') ||
            urlStr.contains('amazon-adsystem') ||
            urlStr.contains('taboola') ||
            // Block images and media since we only need the HTML DOM text
            urlStr.contains('.png') ||
            urlStr.contains('.jpg') ||
            urlStr.contains('.jpeg') ||
            urlStr.contains('.gif') ||
            urlStr.contains('.webp') ||
            urlStr.contains('.mp4') ||
            urlStr.contains('.mp3')) {
          // Return an empty response to block the request
          return WebResourceResponse(
            contentType: 'text/plain',
            data: Uint8List(0),
          );
        }
        return null;
      },
      onLoadStop: (controller, currentUrl) async {
        try {
          final html = await controller.getHtml();
          if (html != null && html.isNotEmpty) {
            if (!completer.isCompleted) {
              completer.complete(html);
            }
          } else {
            if (!completer.isCompleted) {
              completer.completeError(
                Exception('Empty HTML returned from webview'),
              );
            }
          }
        } catch (e) {
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        }
      },
    );

    await headlessWebView.run();

    return await completer.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        throw TimeoutException('WebView fetch timed out for $url');
      },
    );
  } catch (e, stackTrace) {
    logger.warn('WebView fetch failed: $e\n$stackTrace');
    rethrow;
  } finally {
    if (headlessWebView != null) {
      final webViewToDispose = headlessWebView;
      Future.delayed(const Duration(milliseconds: 200), () {
        try {
          webViewToDispose.dispose();
        } catch (e) {
          logger.warn('Error disposing HeadlessInAppWebView: $e');
        }
      });
    }
  }
}

class MobileWebViewWidget extends StatefulWidget {
  final String url;
  final void Function(String html) onDone;
  final void Function(String error) onError;

  const MobileWebViewWidget({
    super.key,
    required this.url,
    required this.onDone,
    required this.onError,
  });

  @override
  State<MobileWebViewWidget> createState() => _MobileWebViewWidgetState();
}

class _MobileWebViewWidgetState extends State<MobileWebViewWidget> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    final userScripts = UnmodifiableListView<UserScript>([
      UserScript(
        source:
            "Object.defineProperty(navigator, 'webdriver', {get: () => undefined});",
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
      ),
    ]);

    return SizedBox(
      width: 1024,
      height: 768,
      child: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(widget.url)),
        initialUserScripts: userScripts,
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          domStorageEnabled: true,
          useShouldInterceptRequest: !kIsWeb && Platform.isAndroid,
        ),
        shouldInterceptRequest: (controller, request) async {
          final urlStr = request.url.toString();
          // Block known ad/tracking domains to save memory & avoid renderer crashes
          if (urlStr.contains('doubleclick.net') ||
              urlStr.contains('googleads') ||
              urlStr.contains('googlesyndication') ||
              urlStr.contains('securepubads') ||
              urlStr.contains('google-analytics') ||
              urlStr.contains('analytics') ||
              urlStr.contains('amazon-adsystem') ||
              urlStr.contains('taboola') ||
              // Block images and media since we only need the HTML DOM text
              urlStr.contains('.png') ||
              urlStr.contains('.jpg') ||
              urlStr.contains('.jpeg') ||
              urlStr.contains('.gif') ||
              urlStr.contains('.webp') ||
              urlStr.contains('.mp4') ||
              urlStr.contains('.mp3')) {
            return WebResourceResponse(
              contentType: 'text/plain',
              data: Uint8List(0),
            );
          }
          return null;
        },
        onLoadStop: (controller, currentUrl) async {
          if (_done) return;
          try {
            final html = await controller.getHtml();
            if (html != null && html.isNotEmpty) {
              if (!_done) {
                _done = true;
                widget.onDone(html);
              }
            } else {
              if (!_done) {
                _done = true;
                widget.onError('Empty HTML from mobile WebView');
              }
            }
          } catch (e) {
            if (!_done) {
              _done = true;
              widget.onError('Mobile WebView getHtml error: $e');
            }
          }
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Plain HTTP fallback
// ---------------------------------------------------------------------------

Future<String> _fetchHttp(String url) async {
  final response = await http.get(
    Uri.parse(url),
    headers: {
      'User-Agent':
          'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,'
          'image/avif,image/webp,image/apng,*/*;q=0.8,'
          'application/signed-exchange;v=b3;q=0.7',
      'Accept-Language': 'en-US,en;q=0.9',
      'Accept-Encoding': 'gzip, deflate, br',
      'Connection': 'keep-alive',
      'Upgrade-Insecure-Requests': '1',
    },
  );
  if (response.statusCode == 200) {
    return response.body;
  } else {
    throw Exception('HTTP error ${response.statusCode}');
  }
}
