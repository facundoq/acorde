import * as cheerio from 'cheerio';
import { Source } from './Source';
import { SongSearchResult, SongContent } from '../types';
import { fetchHtml } from '../fetcher';

export class LaCuerdaSource implements Source {
  name = 'lacuerda';

  async search(query: string): Promise<SongSearchResult[]> {
    const results: SongSearchResult[] = [];
    try {
      const searchUrl = `https://acordes.lacuerda.net/busca.php?exp=${encodeURIComponent(query)}`;
      const html = await fetchHtml(searchUrl);
      const $ = cheerio.load(html);

      $('a').each((i, el) => {
        const href = $(el).attr('href');
        const text = $(el).text().trim();
        
        // LaCuerda search results usually link to /tabs/ or artist subdirectories
        if (href && (href.includes('/tabs/') || href.includes('lacuerda.net/')) && (href.endsWith('.shtml') || href.endsWith('.php'))) {
          const cleanUrl = href.startsWith('//') ? `https:${href}` : (href.startsWith('/') ? `https://acordes.lacuerda.net${href}` : href);
          
          if (text && text.length > 2 && !text.includes('Instrucciones')) {
            // Try to separate Artist - Title if available in text
            let artist = 'LaCuerda';
            let title = text;
            
            if (text.includes(' - ')) {
              const parts = text.split(' - ');
              artist = parts[0].trim();
              title = parts[1].trim();
            }

            results.push({
              id: cleanUrl,
              title: title,
              artist: artist,
              source: this.name,
              url: cleanUrl,
            });
          }
        }
      });
    } catch (e) {
      console.error('LaCuerda search error:', e);
    }
    return results.filter((v, i, a) => a.findIndex(t => t.id === v.id) === i).slice(0, 20);
  }

  async getSong(url: string): Promise<SongContent> {
    const html = await fetchHtml(url);
    const $ = cheerio.load(html);

    // Better selectors for LaCuerda content
    const title = $('h1').first().text().trim() || $('title').text().split('|')[0].trim() || 'Unknown Title';
    const artist = $('h2').first().text().trim() || 'Unknown Artist';
    
    // Content is usually inside a <pre> tag with ID 'cifra' or inside specific divs
    const content = $('#cifra').text() || $('pre').text() || $('#prev').text() || $('.cifra').text();

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
