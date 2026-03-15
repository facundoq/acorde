import * as cheerio from 'cheerio';
import { Source } from './Source';
import { SongSearchResult, SongContent } from '../types';
import { crossFetch } from '../fetcher';
import { Platform } from 'react-native';

export class CifraclubSource implements Source {
  name = 'cifraclub';

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
      // 1. Try suggestions API
      const suggestUrl = `https://www.cifraclub.com.br/api/search/suggestions/?q=${encodeURIComponent(query)}`;
      try {
        const suggestHtml = await this.fetchHtml(suggestUrl);
        const data = JSON.parse(suggestHtml);
        if (data && data.songs) {
          data.songs.forEach((song: any) => {
            results.push({
              id: song.url,
              title: song.name,
              artist: song.artist.name,
              source: this.name,
              url: `https://www.cifraclub.com.br${song.url}`,
            });
          });
        }
      } catch (e) {}

      // 2. Fallback to scraping
      if (results.length === 0) {
        const searchUrl = `https://www.cifraclub.com.br/?q=${encodeURIComponent(query)}`;
        const html = await this.fetchHtml(searchUrl);
        
        const songPattern = /("name"|"url")\s*:\s*"([^"]+)"\s*,\s*("name"|"url")\s*:\s*"([^"]+)"/g;
        const matches = Array.from(html.matchAll(songPattern));
        
        for (const match of matches) {
          const [_, p1, v1, p2, v2] = match;
          const name = p1.includes('name') ? v1 : v2;
          const songUrl = p1.includes('url') ? v1 : v2;
          
          if (songUrl.split('/').filter(p => p).length >= 2) {
            results.push({
              id: songUrl,
              title: name,
              artist: songUrl.split('/').filter(p => p)[0] || 'Unknown Artist',
              source: this.name,
              url: `https://www.cifraclub.com.br${songUrl.startsWith('/') ? '' : '/'}${songUrl}`,
            });
          }
        }

        if (results.length === 0) {
          const $ = cheerio.load(html);
          $('a').each((i, el) => {
            const href = $(el).attr('href');
            const text = $(el).text().trim();
            if (href && href.startsWith('/') && href.endsWith('/') && href.split('/').filter(p => p).length === 2) {
              const parts = href.split('/').filter(p => p);
              if (!['letra', 'musico', 'academy', 'mais', 'afinador', 'metronomo'].includes(parts[0])) {
                results.push({
                  id: href,
                  title: text || parts[1].replace(/-/g, ' '),
                  artist: parts[0].replace(/-/g, ' '),
                  source: this.name,
                  url: `https://www.cifraclub.com.br${href}`,
                });
              }
            }
          });
        }
      }
    } catch (error) {
      console.error('CifraclubSource search error:', error);
    }

    return results.filter((v, i, a) => v.id && v.title && v.artist && a.findIndex(t => t.id === v.id) === i).slice(0, 20);
  }

  async getSong(url: string): Promise<SongContent> {
    const targetUrl = url.startsWith('http') ? url : `https://www.cifraclub.com.br${url}`;
    const html = await this.fetchHtml(targetUrl);
    const $ = cheerio.load(html);

    const title = $('h1.t1').text().trim() || $('h1').first().text().trim() || 'Unknown Title';
    const artist = $('h2.t3 a').text().trim() || $('h2.t3').text().trim() || 'Unknown Artist';
    const pre = $('div.cifra-column pre, #ct_cifra pre, .cifra-container pre, pre');
    const content = pre.first().text();
    
    return {
      title,
      artist,
      lyrics: content || 'Content not found',
      chords: content || 'Chords not found', 
      url: targetUrl,
      source: this.name,
    };
  }
}
