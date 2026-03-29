import * as cheerio from 'cheerio';
import { Source } from './Source';
import { SongSearchResult, SongContent } from '../types';
import { fetchHtml } from '../fetcher';

export class UltimateGuitarSource implements Source {
  name = 'ultimateguitar';

  async search(query: string): Promise<SongSearchResult[]> {
    const results: SongSearchResult[] = [];
    try {
      // Use '+' instead of '%20' for spaces as requested
      const searchUrl = `https://www.ultimate-guitar.com/search.php?search_type=title&order=&value=${encodeURIComponent(query).replace(/%20/g, '+')}`;
      const html = await fetchHtml(searchUrl);
      
      const $ = cheerio.load(html);
      const jsonStr = $('.js-store').attr('data-content');
      if (jsonStr) {
        try {
          const data = JSON.parse(jsonStr);
          const searchResults = data.store?.page?.data?.results || [];

          searchResults.forEach((res: any) => {
            // Filter out 'Pro' or 'Official' tabs as they are usually paywalled and harder to scrape
            if (res.tab_url && res.type !== 'Official' && res.type !== 'Chords Pro') {
              results.push({
                id: res.tab_url,
                title: res.song_name,
                artist: res.artist_name,
                source: this.name,
                url: res.tab_url,
                instrument: res.type_name || res.type,
                rating: res.rating ? parseFloat(res.rating) : undefined,
              });
            }
          });
        } catch (e) {}
      }

      // Regex fallback if JSON blob fails
      if (results.length === 0) {
        // Updated regex to try and capture more metadata
        const songPattern = /"song_name"\s*:\s*"([^"]+)"\s*,\s*"artist_name"\s*:\s*"([^"]+)"\s*,\s*"tab_url"\s*:\s*"([^"]+)"(?:[^}]*"type_name"\s*:\s*"([^"]+)")?(?:[^}]*"rating"\s*:\s*([\d.]+))?/g;
        const matches = Array.from(html.matchAll(songPattern));
        for (const match of matches) {
          const [_, title, artist, tabUrl, typeName, rating] = match;
          const cleanUrl = tabUrl.replace(/\\/g, '');
          results.push({
            id: cleanUrl,
            title,
            artist,
            source: this.name,
            url: cleanUrl,
            instrument: typeName,
            rating: rating ? parseFloat(rating) : undefined,
          });
        }
      }
    } catch (e) {
      console.error('UltimateGuitar search error:', e);
    }
    return results.slice(0, 20);
  }

  async getSong(url: string): Promise<SongContent> {
    const html = await fetchHtml(url);
    const $ = cheerio.load(html);
    
    const jsonStr = $('.js-store').attr('data-content');
    if (jsonStr) {
      try {
        const data = JSON.parse(jsonStr);
        // Try multiple possible paths for tab data
        const tabData = data.store?.page?.data?.tab || data.store?.page?.data?.tab_view?.tab || {};
        const tabView = data.store?.page?.data?.tab_view || {};
        const content = tabView.wiki_tab?.content || tabView.tab_view?.wiki_tab?.content;
        
        if (tabData.song_name || content) {
          return {
            title: tabData.song_name || 'Unknown Title',
            artist: tabData.artist_name || 'Unknown Artist',
            lyrics: content || 'Content not found',
            chords: content || 'Chords not found',
            url,
            source: this.name,
            instrument: tabData.type_name,
            rating: tabData.rating ? parseFloat(tabData.rating) : undefined,
          };
        }
      } catch (e) {
        console.error('UG detail JSON parse error:', e);
      }
    }

    // Regex fallback for content if JSON paths fail
    const contentMatch = html.match(/"content"\s*:\s*"([^"]+)"/);
    const titleMatch = html.match(/"song_name"\s*:\s*"([^"]+)"/);
    const artistMatch = html.match(/"artist_name"\s*:\s*"([^"]+)"/);

    if (contentMatch) {
      return {
        title: titleMatch ? titleMatch[1] : 'Unknown Title',
        artist: artistMatch ? artistMatch[1] : 'Unknown Artist',
        lyrics: contentMatch[1].replace(/\\r\\n/g, '\n').replace(/\\n/g, '\n').replace(/\\"/g, '"'),
        chords: contentMatch[1].replace(/\\r\\n/g, '\n').replace(/\\n/g, '\n').replace(/\\"/g, '"'),
        url,
        source: this.name,
      };
    }

    console.warn(`UG parsing failed for ${url}. HTML length: ${html.length}`);
    return {
      title: 'Unknown Title',
      artist: 'Unknown Artist',
      lyrics: 'Could not parse content',
      url,
      source: this.name,
    };
  }
}
