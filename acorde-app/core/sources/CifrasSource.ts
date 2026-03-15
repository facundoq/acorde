import * as cheerio from 'cheerio';
import { Source } from './Source';
import { SongSearchResult, SongContent } from '../types';
import { crossFetch } from '../fetcher';
import { Platform } from 'react-native';

export class CifrasSource implements Source {
  name = 'cifras';

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
      const searchUrl = `https://www.cifras.com.br/search?q=${encodeURIComponent(query)}`;
      const html = await this.fetchHtml(searchUrl);
      const $ = cheerio.load(html);

      $('.search-result .item').each((i, el) => {
        const link = $(el).find('a').first();
        const href = link.attr('href');
        const title = link.find('.title').text().trim();
        const artist = link.find('.artist').text().trim();
        
        if (href && title) {
          results.push({
            id: href,
            title,
            artist: artist || 'Unknown Artist',
            source: this.name,
            url: href.startsWith('http') ? href : `https://www.cifras.com.br${href}`,
          });
        }
      });

      if (results.length === 0) {
        const songPattern = /("name"|"url")\s*:\s*"([^"]+)"\s*,\s*("name"|"url")\s*:\s*"([^"]+)"/g;
        const matches = Array.from(html.matchAll(songPattern));
        for (const match of matches) {
          const [_, p1, v1, p2, v2] = match;
          const name = p1.includes('name') ? v1 : v2;
          const songUrl = p1.includes('url') ? v1 : v2;
          if (songUrl.includes('/') && songUrl.length > 5 && !songUrl.includes('search')) {
            results.push({
              id: songUrl,
              title: name,
              artist: songUrl.split('/').filter(p => p)[0] || 'Unknown Artist',
              source: this.name,
              url: songUrl.startsWith('http') ? songUrl : `https://www.cifras.com.br${songUrl.startsWith('/') ? '' : '/'}${songUrl}`,
            });
          }
        }
      }
    } catch (e) {
      console.error('Cifras search error:', e);
    }
    return results.filter((v, i, a) => v.id && v.title && a.findIndex(t => t.id === v.id) === i).slice(0, 15);
  }

  async getSong(url: string): Promise<SongContent> {
    const html = await this.fetchHtml(url);
    const $ = cheerio.load(html);

    const title = $('h1').text().trim() || 'Unknown Title';
    const artist = $('h2').text().trim() || 'Unknown Artist';
    const content = $('.cifra-content').text() || $('pre').text();

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
