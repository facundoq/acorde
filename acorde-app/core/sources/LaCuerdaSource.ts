import * as cheerio from 'cheerio';
import { Source } from './Source';
import { SongSearchResult, SongContent } from '../types';
import { crossFetch } from '../fetcher';
import { Platform } from 'react-native';

export class LaCuerdaSource implements Source {
  name = 'lacuerda';

  private async fetchHtml(url: string): Promise<string> {
    const isWeb = Platform.OS === 'web';
    const userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36';
    
    if (isWeb) {
      const proxies = [
        (u: string) => `https://corsproxy.io/?${encodeURIComponent(u)}`,
        (u: string) => `https://api.allorigins.win/raw?url=${encodeURIComponent(u)}`,
      ];

      for (const getProxyUrl of proxies) {
        try {
          const proxyUrl = getProxyUrl(url);
          const response = await crossFetch(proxyUrl, { headers: { 'User-Agent': userAgent } });
          if (response.ok) return await response.text();
        } catch (e) {}
      }
      throw new Error(`Web fetch failed for ${url}`);
    }

    const response = await crossFetch(url, {
      method: 'GET',
      headers: { 'User-Agent': userAgent }
    });

    if (!response.ok) throw new Error(`Native fetch failed: ${response.status}`);
    return await response.text();
  }

  async search(query: string): Promise<SongSearchResult[]> {
    const results: SongSearchResult[] = [];
    try {
      const searchUrl = `https://lacuerda.net/busca.php?query=${encodeURIComponent(query)}`;
      const html = await this.fetchHtml(searchUrl);
      const $ = cheerio.load(html);

      $('a').each((i, el) => {
        const href = $(el).attr('href');
        const text = $(el).text().trim();
        
        if (href && (href.includes('/tabs/') || href.includes('lacuerda.net/')) && href.endsWith('.shtml')) {
          const cleanUrl = href.startsWith('//') ? `https:${href}` : (href.startsWith('/') ? `https://lacuerda.net${href}` : href);
          
          if (text && text.length > 3 && !text.includes('Instrucciones')) {
            results.push({
              id: cleanUrl,
              title: text,
              artist: 'LaCuerda Artist',
              source: this.name,
              url: cleanUrl,
            });
          }
        }
      });
    } catch (e) {
      console.error('LaCuerda search error:', e);
    }
    return results.filter((v, i, a) => a.findIndex(t => t.id === v.id) === i).slice(0, 15);
  }

  async getSong(url: string): Promise<SongContent> {
    const html = await this.fetchHtml(url);
    const $ = cheerio.load(html);

    const title = $('h1').first().text().trim() || 'Unknown Title';
    const artist = $('h2').first().text().trim() || 'Unknown Artist';
    
    const content = $('pre').text() || $('#prev').text() || $('.cifra').text() || $('#cifra').text();

    return {
      title,
      artist,
      lyrics: content || 'Content not found',
      chords: content || 'Chords not found',
      url,
      source: this.name,
    };
  }
}
