import { fetch as nativeFetch } from 'react-native-fetch-api';
import { logger } from './logger';

export const crossFetch = async (url: string, options: any = {}) => {
  return await nativeFetch(url, options);
};

export async function fetchHtml(url: string): Promise<string> {
  const userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36';
  const MAX_RETRIES = 2;

  for (let i = 0; i <= MAX_RETRIES; i++) {
    try {
      logger.log(`[Fetcher] Native fetch attempt ${i+1} for: ${url}`);
      const response = await crossFetch(url, { 
        headers: { 'User-Agent': userAgent } 
      });

      if (response.ok) {
        const result = await response.text();
        logger.log(`[Fetcher] Native fetch success! HTML length: ${result.length}`);
        logger.log(`[Fetcher] HTML snippet: ${result.substring(0, 500)}...`);
        return result;
      }
      
      logger.warn(`[Fetcher] Native fetch attempt ${i+1} returned status ${response.status}: ${response.statusText}`);
      if (i === MAX_RETRIES) {
        throw new Error(`HTTP Error ${response.status}: ${response.statusText}`);
      }
    } catch (e: any) {
      logger.warn(`[Fetcher] Native fetch attempt ${i+1} failed:`, e);
      if (i === MAX_RETRIES) throw e;
    }
    if (i < MAX_RETRIES) await new Promise(r => setTimeout(r, 500));
  }

  throw new Error(`Failed to fetch content directly for ${url}.`);
}
