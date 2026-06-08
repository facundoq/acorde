import React, { useEffect, useState } from 'react';
import { View } from 'react-native';
import { WebView } from 'react-native-webview';
import { DeviceEventEmitter } from 'react-native';
import { logger } from '../core/logger';

export interface FetchRequest {
  id: string;
  url: string;
}

export function HiddenWebViewFetcher() {
  const [requests, setRequests] = useState<FetchRequest[]>([]);

  useEffect(() => {
    const subscription = DeviceEventEmitter.addListener('FETCH_HTML_REQUEST', (req: FetchRequest) => {
      logger.log(`[HiddenWebViewFetcher] Enqueueing request for ${req.url}`);
      setRequests(prev => [...prev, req]);
    });

    return () => {
      subscription.remove();
    };
  }, []);

  const handleMessage = (id: string, event: any) => {
    const html = event.nativeEvent.data;
    logger.log(`[HiddenWebViewFetcher] Received HTML for request ${id}, length: ${html.length}`);
    DeviceEventEmitter.emit(`FETCH_HTML_RESPONSE_${id}`, { html });
    setRequests(prev => prev.filter(req => req.id !== id));
  };

  const handleError = (id: string, syntheticEvent: any) => {
    const { nativeEvent } = syntheticEvent;
    logger.warn(`[HiddenWebViewFetcher] WebView error for request ${id}:`, nativeEvent);
    DeviceEventEmitter.emit(`FETCH_HTML_RESPONSE_${id}`, { error: new Error('WebView error') });
    setRequests(prev => prev.filter(req => req.id !== id));
  };

  if (requests.length === 0) return null;

  // Wait 1.5s after load to ensure dynamic content and anti-bot checks settle
  const INJECTED_JS = `
    setTimeout(function() {
      window.ReactNativeWebView.postMessage(document.documentElement.outerHTML);
    }, 1500);
    true;
  `;

  return (
    <View style={{ width: 0, height: 0, opacity: 0, overflow: 'hidden' }}>
      {requests.map(req => (
        <WebView
          key={req.id}
          source={{ uri: req.url }}
          injectedJavaScript={INJECTED_JS}
          onMessage={(e) => handleMessage(req.id, e)}
          onError={(e) => handleError(req.id, e)}
          javaScriptEnabled={true}
          domStorageEnabled={true}
          style={{ width: 0, height: 0 }}
        />
      ))}
    </View>
  );
}
