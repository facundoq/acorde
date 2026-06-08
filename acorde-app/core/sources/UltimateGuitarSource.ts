import * as cheerio from 'cheerio';
import { Source } from './Source';
import { SongSearchResult, SongContent } from '../types';
import { fetchHtml } from '../fetcher';
import { logger } from '../logger';

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
          const searchResults = data.store?.page?.data?.results;

          if (Array.isArray(searchResults)) {
            searchResults.forEach((res: any) => {
              if (!res) return;
              const type = String(res.type_name || res.type || '').toLowerCase();
              const url = String(res.tab_url || '');
              
              // Strictly exclude 'Official', 'Pro', 'Guitar Pro', 'Video', and 'Power' (Power Tab)
              const isExcludedType = 
                res.is_pro || 
                type.includes('pro') || 
                type.includes('official') || 
                type.includes('power') ||
                type.includes('guitar pro') ||
                type.includes('video');

              // Publicly available chords/tabs must follow this URL pattern
              const isPublicPattern = url.includes('ultimate-guitar.com/tab/');
              
              if (url && !isExcludedType && isPublicPattern) {
                results.push({
                  id: url,
                  title: String(res.song_name || 'Unknown'),
                  artist: String(res.artist_name || 'Unknown'),
                  source: this.name,
                  url: url,
                  instrument: String(res.type_name || res.type || ''),
                  rating: res.rating ? parseFloat(res.rating) : undefined,
                });
              }
            });
          }
        } catch (e) {}
      }

      // Updated regex to try and capture more metadata
      // Looking for "song_name" and "tab_url" specifically
      if (results.length === 0) {
        const songNamePattern = /["']?(?:song_name|name|songName|title)["']?\s*:\s*["']([^"']+)["']/gi;
        const tabUrlPattern = /["']?(?:tab_url|url|tabUrl)["']?\s*:\s*["']([^"']+)["']/gi;
        const artistNamePattern = /["']?(?:artist_name|artist|artistName)["']?\s*:\s*["']([^"']+)["']/gi;
        const typeNamePattern = /["']?(?:type_name|type|typeName)["']?\s*:\s*["']([^"']+)["']/gi;

        const htmlClean = html.replace(/\\"/g, '"');
        
        let match;
        const songNames: string[] = [];
        const tabUrls: string[] = [];
        const artistNames: string[] = [];
        const typeNames: string[] = [];

        const resetAndExec = (regex: RegExp, str: string, target: string[]) => {
          regex.lastIndex = 0;
          let m;
          while ((m = regex.exec(str)) !== null) {
            target.push(m[1]);
          }
        };

        resetAndExec(songNamePattern, htmlClean, songNames);
        resetAndExec(tabUrlPattern, htmlClean, tabUrls);
        resetAndExec(artistNamePattern, htmlClean, artistNames);
        resetAndExec(typeNamePattern, htmlClean, typeNames);

        for (let i = 0; i < Math.min(songNames.length, tabUrls.length); i++) {
          const title = songNames[i];
          const url = tabUrls[i].replace(/\\/g, '');
          const artist = artistNames[i] || 'Unknown';
          const typeName = typeNames[i] || '';
          
          const lowerType = typeName.toLowerCase();
          const isExcludedType = 
            lowerType.includes('pro') || 
            lowerType.includes('official') || 
            lowerType.includes('power') ||
            lowerType.includes('guitar pro') ||
            lowerType.includes('video');

          const isPublicPattern = url.includes('ultimate-guitar.com/tab/');
          
          if (!isExcludedType && isPublicPattern) {
            results.push({
              id: url,
              title: String(title),
              artist: String(artist),
              source: this.name,
              url: url,
              instrument: String(typeName),
            });
          }
        }
      }
    } catch (e: any) {
      logger.error('UltimateGuitar search error:', e.message || e);
    }
    return results.slice(0, 20);
  }

  async getSong(url: string): Promise<SongContent> {
    const html = await fetchHtml(url);
    if (html.includes('Just a moment...') || html.includes('challenge-running')) {
      throw new Error('Ultimate Guitar bot detection active. Please try again later or use the Android app.');
    }
    const $ = cheerio.load(html);
    
    const jsonStr = $('.js-store').attr('data-content');
    if (jsonStr) {
      try {
        const data = JSON.parse(jsonStr);
        // Try multiple possible paths for tab data
        const tabData = data.store?.page?.data?.tab || data.store?.page?.data?.tab_view?.tab || {};
        const tabView = data.store?.page?.data?.tab_view || {};
        const wikiTab = tabView.wiki_tab || {};
        const content = wikiTab.content || tabView.tab_view?.wiki_tab?.content;
        
        if (tabData.song_name || content) {
          return {
            title: String(tabData.song_name || 'Unknown Title'),
            artist: String(tabData.artist_name || 'Unknown Artist'),
            lyrics: String(content || 'Content not found'),
            chords: String(content || 'Chords not found'),
            url,
            source: this.name,
            instrument: String(tabData.type_name || ''),
            rating: tabData.rating ? parseFloat(tabData.rating) : undefined,
          };
        }
      } catch (e: any) {
        logger.error('UG detail JSON parse error:', e.message || e);
      }
    }

    // Regex fallback for content if JSON paths fail
    // Match content, song_name, artist_name globally but prioritize them
    const contentMatch = html.match(/["']?content["']?\s*:\s*["']([^"']+)["']/i);
    const titleMatch = html.match(/["']?(?:song_name|name|songName|title)["']?\s*:\s*["']([^"']+)["']/i);
    const artistMatch = html.match(/["']?(?:artist_name|artist|artistName)["']?\s*:\s*["']([^"']+)["']/i);

    if (contentMatch) {
      const content = contentMatch[1].replace(/\\r\\n/g, '\n').replace(/\\n/g, '\n').replace(/\\"/g, '"');
      return {
        title: titleMatch ? String(titleMatch[1]) : 'Unknown Title',
        artist: artistMatch ? String(artistMatch[1]) : 'Unknown Artist',
        lyrics: content,
        chords: content,
        url,
        source: this.name,
      };
    }

    logger.warn(`UG parsing failed for ${url}. HTML length: ${html.length}`);
    return {
      title: 'Unknown Title',
      artist: 'Unknown Artist',
      lyrics: 'Could not parse content',
      url,
      source: this.name,
    };
  }
}
