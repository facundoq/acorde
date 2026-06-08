import { fetch as polyfillFetch } from 'react-native-fetch-api';
import { logger } from './logger';
import { DeviceEventEmitter } from 'react-native';

export const crossFetch = async (url: string, options: any = {}) => {
  const fetchFn = polyfillFetch || global.fetch || fetch;
  if (!fetchFn) throw new Error('No fetch implementation found');
  return await fetchFn(url, options);
};

export async function fetchHtml(url: string): Promise<string> {
  const id = Math.random().toString(36).substring(2, 15);
  
  return new Promise((resolve, reject) => {
    const timeout = setTimeout(() => {
      subscription.remove();
      reject(new Error(`Timeout fetching HTML for ${url} via WebView`));
    }, 30000); // 30s timeout

    const subscription = DeviceEventEmitter.addListener(`FETCH_HTML_RESPONSE_${id}`, (response) => {
      clearTimeout(timeout);
      subscription.remove();
      if (response.error) {
        reject(response.error);
      } else {
        resolve(response.html);
      }
    });

    logger.log(`[Fetcher] Requesting WebView fetch for ${url} (id: ${id})`);
    DeviceEventEmitter.emit('FETCH_HTML_REQUEST', { id, url });
  });
}
