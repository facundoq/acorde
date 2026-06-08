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
      // If query is already a LaCuerda artist URL, fetch that directly
      const isArtistUrl = query.includes('lacuerda.net/') && !query.includes('busca.php');
      const searchUrl = isArtistUrl ? query : `https://acordes.lacuerda.net/busca.php?exp=${encodeURIComponent(query)}`;
      
      const html = await fetchHtml(searchUrl);
      const $ = cheerio.load(html);

      // Case 1: Search hits only artists (Artist list)
      if ($('#i_main').length > 0) {
        $('#i_main li a.sb').each((i, el) => {
          const href = $(el).attr('href');
          const name = $(el).text().trim();
          if (href && !href.includes('/Extras/')) {
            const url = href.startsWith('http') ? href : `https://acordes.lacuerda.net${href.startsWith('/') ? '' : '/'}${href}`;
            results.push({
              id: url,
              title: name,
              artist: 'Artist',
              source: this.name,
              url: url,
              type: 'artist'
            });
          }
        });
        if (results.length > 0) return results;
      }

      // Case 2: Search returns a table of songs (Song table)
      if ($('#s_main').length > 0) {
        const scriptText = $('script').text() || '';
        const hdsMatch = scriptText.match(/var hds=\[(.*?)\];/);
        const fnsMatch = scriptText.match(/var fns=\[(.*?)\];/);
        const nmaxMatch = scriptText.match(/var NMAX=(\d+);/);

        if (hdsMatch && fnsMatch && nmaxMatch) {
          const hdsStr = hdsMatch[1] || '';
          const fnsStr = fnsMatch[1] || '';
          const hds = hdsStr.split(',').map(s => s.trim().replace(/^['"]|['"]$/g, ''));
          const fns = fnsStr.split(',').map(s => s.trim().replace(/^['"]|['"]$/g, ''));
          const nmax = parseInt(nmaxMatch[1]);

          $('#s_main tr').each((i, tr) => {
            const artistName = $(tr).find('td').first().text().trim();
            $(tr).find('ul.b_main li').each((j, li) => {
              const songName = $(li).find('a').text().trim();
              const idAttr = $(li).attr('id');
              if (idAttr) {
                const n = parseInt(idAttr.replace('r', ''));
                const index = nmax - n;
                if (index >= 0 && hds[index] && fns[index]) {
                  const url = `https://acordes.lacuerda.net/${hds[index]}/${fns[index]}`;
                  results.push({
                    id: url,
                    title: songName,
                    artist: artistName,
                    source: this.name,
                    url: url,
                    type: 'song'
                  });
                }
              }
            });
          });
        }
        if (results.length > 0) return results;
      }

      // Case 3: Artist page or direct results list
      $('#b_main a, #rList a').each((i, el) => {
        const href = $(el).attr('href');
        // Handle names where 'acordes' or 'tablatura' might be inside <em>
        // Use contents() to ignore <em> and get only text nodes
        const text = $(el).contents().filter((_, node) => node.type === 'text').text().trim();
        
        if (href && !href.includes('javascript:') && !href.includes('/Extras/') && !href.includes('busca.php')) {
          // If we are on an artist page, the links are relative to the artist
          let cleanUrl = href;
          if (!href.startsWith('http') && !href.startsWith('//')) {
            if (isArtistUrl) {
              const baseUrl = searchUrl.endsWith('/') ? searchUrl : `${searchUrl}/`;
              cleanUrl = `${baseUrl}${href.startsWith('/') ? href.substring(1) : href}`;
            } else {
              cleanUrl = `https://acordes.lacuerda.net/${href.startsWith('/') ? href.substring(1) : href}`;
            }
          } else if (href.startsWith('//')) {
            cleanUrl = `https:${href}`;
          }
          
          if (text && text.length > 1 && !['aviso legal', 'privacidad', 'contacto'].includes(text.toLowerCase())) {
            let artist = 'LaCuerda';
            let title = text;
            
            // On artist pages, the H1 is the artist
            if (isArtistUrl) {
              artist = $('h1').first().text().trim() || 'LaCuerda';
            } else if (text.includes(' - ')) {
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
              type: 'song'
            });
          }
        }
      });

      // Fallback
      if (results.length === 0) {
        $('a').each((i, el) => {
          const href = $(el).attr('href');
          const text = $(el).text().trim();
          
          if (href && (href.includes('/tabs/') || (href.split('/').length === 1 && !href.includes('.') && href.length > 3)) && 
              !href.includes('javascript:') && !href.includes('/Extras/') && !href.includes('busca.php') &&
              !['aviso legal', 'privacidad', 'contacto', 'es', 'en', 'pt'].includes(text.toLowerCase())) {
            
            const cleanUrl = href.startsWith('//') ? `https:${href}` : 
                            (href.startsWith('http') ? href : `https://acordes.lacuerda.net/${href.startsWith('/') ? href.substring(1) : href}`);
            
            results.push({
              id: cleanUrl,
              title: text,
              artist: 'LaCuerda',
              source: this.name,
              url: cleanUrl,
              type: 'song'
            });
          }
        });
      }
    } catch (e: any) {
      logger.error('LaCuerda search error:', e.message || e);
    }
    return results.filter((v, i, a) => a.findIndex(t => t.id === v.id) === i).slice(0, 40);
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
