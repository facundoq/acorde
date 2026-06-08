import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import '../core/logger.dart';

Future<String> fetchHtml(String url) async {
  if (kIsWeb) {
    return _fetchHttp(url);
  }

  final completer = Completer<String>();
  HeadlessInAppWebView? headlessWebView;

  try {
    headlessWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(
        url: WebUri(url),
      ),
      initialSettings: InAppWebViewSettings(
        userAgent:
            'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        javaScriptEnabled: true,
        domStorageEnabled: true,
      ),
      onLoadStop: (controller, currentUrl) async {
        try {
          final html = await controller.getHtml();
          if (html != null && html.isNotEmpty) {
            completer.complete(html);
          } else {
            completer.completeError(Exception('Empty HTML returned from webview'));
          }
        } catch (e) {
          completer.completeError(e);
        } finally {
          headlessWebView?.dispose();
        }
      },
      onReceivedError: (controller, request, error) {
        completer.completeError(Exception('WebView error: ${error.description}'));
        headlessWebView?.dispose();
      },
      onReceivedHttpError: (controller, request, errorResponse) {
        completer.completeError(Exception('WebView HTTP error: ${errorResponse.statusCode}'));
        headlessWebView?.dispose();
      },
    );

    await headlessWebView.run();

    // 20 seconds timeout for full page loading and js execution
    return await completer.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        headlessWebView?.dispose();
        throw TimeoutException('WebView fetch timed out for $url');
      },
    );
  } catch (e) {
    logger.warn('WebView fetch failed, falling back to HTTP: $e');
    // If webview initialization fails at runtime, fall back to HTTP
    return _fetchHttp(url);
  }
}

Future<String> _fetchHttp(String url) async {
  final response = await http.get(
    Uri.parse(url),
    headers: {
      'User-Agent':
          'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
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
