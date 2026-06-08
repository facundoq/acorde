import { fetchHtml as fetchHtmlWeb } from '../fetcher.web';
import { fetchHtml as fetchHtmlNative } from '../fetcher.native';

// Mock global fetch for web
global.fetch = jest.fn();

// Mock react-native-fetch-api for native
jest.mock('react-native-fetch-api', () => ({
  fetch: jest.fn()
}));

import { fetch as mockNativeFetch } from 'react-native-fetch-api';

describe('Fetcher Unit Tests', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('fetcher.web', () => {
    test('should try proxies until success', async () => {
      const targetUrl = 'https://example.com';
      (global.fetch as jest.Mock)
        .mockResolvedValueOnce({ ok: false, status: 403 }) // Proxy 1 fails
        .mockResolvedValueOnce({ ok: true, text: () => Promise.resolve('<html>Success</html>') }); // Proxy 2 succeeds

      const html = await fetchHtmlWeb(targetUrl);
      expect(html).toBe('<html>Success</html>');
      expect(global.fetch).toHaveBeenCalledTimes(2);
    });

    test('should throw error if all proxies fail', async () => {
      (global.fetch as jest.Mock).mockResolvedValue({ ok: false, status: 403 });
      
      await expect(fetchHtmlWeb('https://example.com')).rejects.toThrow(/Connection error/);
    });
  });

  describe('fetcher.native', () => {
    test('should fetch directly with retries', async () => {
      const targetUrl = 'https://example.com';
      (mockNativeFetch as jest.Mock)
        .mockRejectedValueOnce(new Error('Network fail'))
        .mockResolvedValueOnce({ ok: true, text: () => Promise.resolve('<html>Direct Success</html>') });

      const html = await fetchHtmlNative(targetUrl);
      expect(html).toBe('<html>Direct Success</html>');
      expect(mockNativeFetch).toHaveBeenCalledTimes(2);
    });

    test('should throw error after max retries', async () => {
      (mockNativeFetch as jest.Mock).mockRejectedValue(new Error('Persistent failure'));
      
      await expect(fetchHtmlNative('https://example.com')).rejects.toThrow('Persistent failure');
    });
  });
});
