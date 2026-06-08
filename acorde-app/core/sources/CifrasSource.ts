import * as cheerio from 'cheerio';
import { Source } from './Source';
import { SongSearchResult, SongContent } from '../types';
import { fetchHtml } from '../fetcher';
import { logger } from '../logger';

export class CifrasSource implements Source {
  name = 'cifras';

  async search(query: string): Promise<SongSearchResult[]> {
    const results: SongSearchResult[] = [];
    try {
      const searchUrl = `https://www.cifras.com.br/search?q=${encodeURIComponent(query)}`;
      const html = await fetchHtml(searchUrl);
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
        let match;
        while ((match = songPattern.exec(html)) !== null) {
          const [_, p1, v1, p2, v2] = match;
          const name = String(p1 || '').includes('name') ? v1 : v2;
          const songUrl = String(p1 || '').includes('url') ? v1 : v2;
          if (String(songUrl || '').includes('/') && String(songUrl || '').length > 5 && !String(songUrl || '').includes('search')) {
            results.push({
              id: String(songUrl || ''),
              title: String(name || 'Unknown'),
              artist: String(songUrl || '').split('/').filter(p => p)[0] || 'Unknown Artist',
              source: this.name,
              url: String(songUrl || '').startsWith('http') ? String(songUrl || '') : `https://www.cifras.com.br${String(songUrl || '').startsWith('/') ? '' : '/'}${songUrl}`,
            });
          }
        }
      }
    } catch (e: any) {
      logger.error('Cifras search error:', e.message || e);
    }
    return results.filter((v, i, a) => v.id && v.title && a.findIndex(t => t.id === v.id) === i).slice(0, 15);
  }

  async getSong(url: string): Promise<SongContent> {
    const html = await fetchHtml(url);
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
