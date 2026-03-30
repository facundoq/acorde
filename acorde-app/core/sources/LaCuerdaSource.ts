import * as cheerio from 'cheerio';
import { Source } from './Source';
import { SongSearchResult, SongContent } from '../types';
import { fetchHtml } from '../fetcher';
import { logger } from '../logger';

export class LaCuerdaSource implements Source {
  name = 'lacuerda';

  async search(query: string): Promise<SongSearchResult[]> {
    const results: SongSearchResult[] = [];
    try {
      const searchUrl = `https://acordes.lacuerda.net/busca.php?exp=${encodeURIComponent(query)}`;
      const html = await fetchHtml(searchUrl);
      const $ = cheerio.load(html);

      // Target specific containers for song results
      // #b_main is the main results list
      // #rList is the side list (populares/historial)
      $('#b_main a, #rList a').each((i, el) => {
        const href = $(el).attr('href');
        const text = $(el).find('em').remove().end().text().trim(); // Remove 'acordes'/'tablatura' text inside <em>
        
        if (href && !href.includes('javascript:') && !href.includes('/Extras/')) {
          const cleanUrl = href.startsWith('//') ? `https:${href}` : 
                          (href.startsWith('http') ? href : `https://acordes.lacuerda.net/${href.startsWith('/') ? href.substring(1) : href}`);
          
          if (text && text.length > 1) {
            // Try to separate Artist - Title if available in text (sometimes happens in search results)
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

      // Fallback if the specific containers didn't work (might be a different page layout)
      if (results.length === 0) {
        $('a').each((i, el) => {
          const href = $(el).attr('href');
          const text = $(el).text().trim();
          
          if (href && (href.includes('/tabs/') || (href.split('/').length === 1 && !href.includes('.') && href.length > 3)) && 
              !href.includes('javascript:') && !href.includes('/Extras/') && !['Aviso Legal', 'Privacidad', 'Contacto'].includes(text)) {
            
            const cleanUrl = href.startsWith('//') ? `https:${href}` : 
                            (href.startsWith('http') ? href : `https://acordes.lacuerda.net/${href.startsWith('/') ? href.substring(1) : href}`);
            
            results.push({
              id: cleanUrl,
              title: text,
              artist: 'LaCuerda',
              source: this.name,
              url: cleanUrl,
            });
          }
        });
      }
    } catch (e: any) {
      logger.error('LaCuerda search error:', e.message || e);
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
