import * as cheerio from 'cheerio';
import { Source } from './Source';
import { SongSearchResult, SongContent } from '../types';
import { fetchHtml } from '../fetcher';
import { logger } from '../logger';

export class CifraclubSource implements Source {
  name = 'cifraclub';

  async search(query: string): Promise<SongSearchResult[]> {
    const results: SongSearchResult[] = [];
    
    try {
      // 1. Try suggestions API
      const suggestUrl = `https://www.cifraclub.com.br/api/search/suggestions/?q=${encodeURIComponent(query)}`;
      try {
        logger.log(`[Cifraclub] Trying suggestions API...`);
        const suggestHtml = await fetchHtml(suggestUrl);
        const data = JSON.parse(suggestHtml);
        if (data && data.songs) {
          logger.log(`[Cifraclub] Found ${data.songs.length} suggestions.`);
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
      } catch (e) {
        logger.warn(`[Cifraclub] Suggestions API failed, falling back to scrape.`);
      }

      // 2. Fallback to scraping
      if (results.length === 0) {
        logger.log(`[Cifraclub] Scraping search page...`);
        const searchUrl = `https://www.cifraclub.com.br/?q=${encodeURIComponent(query)}`;
        const html = await fetchHtml(searchUrl);
        
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
      logger.error('CifraclubSource search error:', error);
    }

    return results.filter((v, i, a) => v.id && v.title && v.artist && a.findIndex(t => t.id === v.id) === i).slice(0, 20);
  }

  async getSong(url: string): Promise<SongContent> {
    const targetUrl = url.startsWith('http') ? url : `https://www.cifraclub.com.br${url}`;
    const html = await fetchHtml(targetUrl);
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
