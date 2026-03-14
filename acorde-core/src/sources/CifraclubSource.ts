import * as cheerio from 'cheerio';
import { Source } from './Source';
import { SongSearchResult, SongContent } from '../types';

export class CifraclubSource implements Source {
  name = 'cifraclub';

  private async fetchHtml(url: string): Promise<string> {
    const isWeb = typeof window !== 'undefined';
    // Use a CORS proxy if in browser, otherwise direct fetch
    const finalUrl = isWeb ? `https://api.allorigins.win/get?url=${encodeURIComponent(url)}` : url;
    
    const response = await fetch(finalUrl, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
      }
    });

    if (!response.ok) {
      if (isWeb) throw new Error(`Fetch via proxy failed with status: ${response.status}`);
      return await (await fetch(url)).text();
    }

    if (isWeb) {
      const data = await response.json();
      return data.contents;
    }
    
    return await response.text();
  }

  async search(query: string): Promise<SongSearchResult[]> {
    const results: SongSearchResult[] = [];
    
    try {
      // 1. Primary: Try the suggestions API
      const suggestUrl = `https://www.cifraclub.com.br/api/search/suggestions/?q=${encodeURIComponent(query)}`;
      console.log(`Searching Cifra Club API: ${suggestUrl}`);
      
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
      } catch (e) {
        // API failed or blocked, continue to scraper
      }

      // 2. Secondary: Scrape the search page
      if (results.length === 0) {
        const searchUrl = `https://www.cifraclub.com.br/?q=${encodeURIComponent(query)}`;
        console.log(`Searching Cifra Club Scraper: ${searchUrl}`);
        const html = await this.fetchHtml(searchUrl);
        const $ = cheerio.load(html);

        // Broad regex for song objects in RSC strings (handling potential escaping)
        const songPattern = /\\"name\\":\\"([^\\"]+)\\",\\"url\\":\\"([^\\"]+)\\",\\"artist\\":\{[^}]*\\"name\\":\\"([^\\"]+)\\"/g;
        let match;
        while ((match = songPattern.exec(html)) !== null) {
          const [_, songName, songUrl, artistName] = match;
          const cleanUrl = songUrl.replace(/\\\\/g, '');
          if (cleanUrl.split('/').filter(p => p).length >= 2) {
            results.push({
              id: cleanUrl,
              title: songName,
              artist: artistName,
              source: this.name,
              url: `https://www.cifraclub.com.br${cleanUrl.startsWith('/') ? '' : '/'}${cleanUrl}`,
            });
          }
        }
        
        // Also try unescaped version
        const songPatternPlain = /"name":"([^"]+)","url":"([^"]+)","artist":\{[^}]*"name":"([^"]+)"/g;
        while ((match = songPatternPlain.exec(html)) !== null) {
          const [_, songName, songUrl, artistName] = match;
          if (songUrl.split('/').filter(p => p).length >= 2) {
            results.push({
              id: songUrl,
              title: songName,
              artist: artistName,
              source: this.name,
              url: `https://www.cifraclub.com.br${songUrl.startsWith('/') ? '' : '/'}${songUrl}`,
            });
          }
        }

        // Link pattern fallback
        $('a').each((i, el) => {
          const href = $(el).attr('href');
          const title = $(el).text().trim();
          if (href && href.startsWith('/') && href.endsWith('/') && href.split('/').filter(p => p).length === 2) {
            const parts = href.split('/').filter(p => p);
            if (!['letra', 'musico', 'academy', 'mais', 'afinador', 'metronomo'].includes(parts[0])) {
              results.push({
                id: href,
                title: title || parts[1].replace(/-/g, ' '),
                artist: parts[0].replace(/-/g, ' '),
                source: this.name,
                url: `https://www.cifraclub.com.br${href}`,
              });
            }
          }
        });
      }

    } catch (error) {
      console.error('CifraclubSource search error:', error);
    }

    const uniqueResults = results.filter((v, i, a) => 
      v.id && v.title && v.artist && 
      a.findIndex(t => t.id === v.id) === i &&
      v.title.length > 1 &&
      !v.title.includes('href=')
    ).slice(0, 20);

    console.log(`Found ${uniqueResults.length} unique results for "${query}"`);
    return uniqueResults;
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