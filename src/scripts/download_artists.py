import os
import sys
import json
import urllib.parse
import re
import html
import time
import random
import gzip
import shutil
import subprocess
from curl_cffi import requests as cffi_requests

output_file = "/home/facundoq/dev/acorde/assets/default_songs.json"
compressed_file = "/home/facundoq/dev/acorde/src/assets/default_songs.json.gz"

artists = [
    "The Beatles", "The Rolling Stones", "Bob Dylan", "Jimi Hendrix Experience",
    "Led Zeppelin", "Queen", "Pink Floyd", "Elvis Presley", "David Bowie",
    "The Who", "Black Sabbath", "The Doors", "Fleetwood Mac", "The Velvet Underground",
    "Bruce Springsteen", "Metallica", "Nirvana", "U2", "The Clash", "Rush",
    "Van Halen", "The Eagles", "Aerosmith", "Cream", "Santana", "Soundgarden",
    "Alice in Chains", "Stone Temple Pilots", "Smashing Pumpkins", "Pixies",
    "PJ Harvey", "Tori Amos", "Alanis Morissette", "Jane's Addiction", "Screaming Trees",
    "The National", "Sufjan Stevens", "Modest Mouse", "Florence + The Machine",
    "LCD Soundsystem", "Bon Iver", "The Strokes", "Arctic Monkeys", "Radiohead",
    "Interpol", "Sigur Rós", "Max Richter", "Ludovico Einaudi", "M83", "St. Vincent",
    "Portishead", "Massive Attack", "Cocteau Twins", "Nick Cave & The Bad Seeds",
    "Tom Waits", "Mudhoney", "Silverchair", "Temple of the Dog", "L7", "Bush",
    "Garbage", "Live", "Feeder", "Local H", "Failure", "Filter", "Collective Soul",
    "The Shins", "The Black Keys", "Yeah Yeah Yeahs", "Death Cab for Cutie",
    "The Decemberists", "Franz Ferdinand", "Bloc Party", "Phoenix", "Spoon",
    "Fleet Foxes", "Grizzly Bear", "Vampire Weekend", "Foals", "Band of Horses",
    "Alt-J", "Regina Spektor", "Cat Power", "Feist", "Sharon Van Etten",
    "Angel Olsen", "Mitski", "Perfume Genius", "Weyes Blood", "Phoebe Bridgers",
    "Aimee Mann", "Liz Phair", "Jorane", "Explosions in the Sky", "Mogwai",
    "Godspeed You! Black Emperor", "Ólafur Arnalds", "Nils Frahm", "Hania Rani",
    "Dustin O'Halloran", "Balmorhea", "Hammock", "This Will Destroy You",
    "Jónsi", "Eluvium", "Yes", "Genesis", "Jethro Tull", "Emerson, Lake & Palmer",
    "Camel", "Gentle Giant", "Van der Graaf Generator", "Can", "Soft Machine",
    "Eric Clapton", "Mark Knopfler", "JJ Cale", "Steely Dan", "The Allman Brothers Band",
    "Stevie Ray Vaughan", "Rory Gallagher", "Robin Trower", "Free", "The Doobie Brothers",
    "Traffic", "Supertramp", "The Band", "Creedence Clearwater Revival", "Little Feat",
    "Lynyrd Skynyrd", "Wishbone Ash", "Procol Harum", "Moody Blues", "Focus",
    "King Crimson", "Dire Straits"
]

def fetch_page(url):
    """Fetch using curl_cffi (Chrome impersonation)."""
    try:
        res = cffi_requests.get(url, impersonate="chrome124", timeout=15)
        if res.status_code == 200:
            return res.text
    except Exception as e:
        print(f"Fetch error for {url}: {e}")
    return None

def fetch_page_chrome_fallback(url):
    """Fallback using headless Chrome if curl_cffi is blocked."""
    try:
        user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
        cmd = [
            "google-chrome",
            "--headless=new",
            "--disable-gpu",
            "--no-sandbox",
            "--disable-blink-features=AutomationControlled",
            f"--user-agent={user_agent}",
            "--virtual-time-budget=5000",
            "--dump-dom",
            url
        ]
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=20)
        if res.returncode == 0:
            return res.stdout
    except Exception as e:
        print(f"Headless Chrome fallback error: {e}")
    return None

def search_artist_songs(artist):
    encoded = urllib.parse.quote(artist)
    search_url = f"https://www.ultimate-guitar.com/search.php?search_type=title&value={encoded}"
    
    html_content = fetch_page(search_url)
    if not html_content:
        html_content = fetch_page_chrome_fallback(search_url)
        if not html_content:
            return []

    match = re.search(r'data-content="([^"]+)"', html_content)
    if not match:
        # Check if the page is direct artist page or has other formats
        return []

    try:
        decoded_json = html.unescape(match.group(1))
        data = json.loads(decoded_json)
        results = data.get('store', {}).get('page', {}).get('data', {}).get('results', [])
        
        # We filter results to make sure artist name is a close match
        artist_songs = []
        for r in results:
            if not r.get('tab_url') or not r.get('song_name') or not r.get('artist_name'):
                continue
            
            # Match artist name closely
            r_artist = r.get('artist_name', '').lower()
            target_artist = artist.lower()
            if target_artist not in r_artist and r_artist not in target_artist:
                continue
                
            # Filter for Chords or Tab type
            t_name = r.get('type', '')
            if t_name not in ['Chords', 'Tab', 'Ukulele', 'Bass', 'Harmonica', 'Piano']:
                continue
                
            artist_songs.append(r)
            
        # Group by song name and pick best rating/votes version
        song_versions = {}
        for s in artist_songs:
            s_name = s.get('song_name', '').strip().lower()
            votes = s.get('votes') or 0
            rating = s.get('rating') or 0.0
            
            if s_name not in song_versions:
                song_versions[s_name] = s
            else:
                existing = song_versions[s_name]
                existing_votes = existing.get('votes') or 0
                if votes > existing_votes:
                    song_versions[s_name] = s
                    
        sorted_songs = list(song_versions.values())
        # Sort by popularity (votes desc)
        sorted_songs.sort(key=lambda x: (x.get('votes') or 0, x.get('rating') or 0.0), reverse=True)
        return sorted_songs
    except Exception as e:
        print(f"Error parsing search JSON for {artist}: {e}")
        
    return []

def parse_song_detail(html_content, url):
    match = re.search(r'data-content="([^"]+)"', html_content)
    if match:
        try:
            decoded_json = html.unescape(match.group(1))
            data = json.loads(decoded_json)
            tab_data = (
                data.get('store', {}).get('page', {}).get('data', {}).get('tab', {})
                or data.get('store', {}).get('page', {}).get('data', {}).get('tab_view', {}).get('tab', {})
                or {}
            )
            tab_view = data.get('store', {}).get('page', {}).get('data', {}).get('tab_view', {})
            wiki_tab = tab_view.get('wiki_tab', {})
            content = wiki_tab.get('content') or tab_view.get('tab_view', {}).get('wiki_tab', {}).get('content')
            
            if tab_data.get('song_name') or content:
                title = str(tab_data.get('song_name', 'Unknown Title'))
                artist = str(tab_data.get('artist_name', 'Unknown Artist'))
                lyrics = str(content or 'Content not found')
                
                rating = tab_data.get('rating')
                try:
                    rating = float(rating) if rating is not None else None
                except:
                    rating = None
                    
                rating_count = (
                    tab_data.get('votes')
                    or tab_data.get('rating_votes')
                    or tab_data.get('rating_count')
                )
                try:
                    rating_count = int(rating_count) if rating_count is not None else None
                except:
                    rating_count = None
                
                instrument = str(tab_data.get('type_name', 'Chords'))
                source_id = str(tab_data.get('id') or url.split('/')[-1])
                
                return {
                    'source_id': source_id,
                    'title': title,
                    'artist': artist,
                    'lyrics': lyrics,
                    'chords': lyrics,
                    'source': 'ultimateguitar',
                    'url': url,
                    'instrument': instrument,
                    'rating': rating,
                    'rating_count': rating_count,
                }
        except Exception as e:
            print(f"Error parsing JSON-LD detail: {e}")
            
    # Fallback to LD+JSON
    ld_match = re.search(r'<script type="application/ld\+json">([\s\S]*?)</script>', html_content)
    if ld_match:
        try:
            data = json.loads(ld_match.group(1))
            if isinstance(data, list):
                data = data[0]
            title = str(data.get('name', 'Unknown Title'))
            artist = str(data.get('byArtist', {}).get('name', 'Unknown Artist'))
            
            pre_match = re.search(r'<pre[^>]*>([\s\S]*?)</pre>', html_content)
            content_match = re.search(r'class="[a-zA-Z0-9\-_]*js-tab-content[^"]*"[^>]*>([\s\S]*?)</div>', html_content)
            
            lyrics = ""
            if content_match:
                lyrics = re.sub(r'<[^>]+>', '', content_match.group(1))
            elif pre_match:
                lyrics = re.sub(r'<[^>]+>', '', pre_match.group(1))
            
            lyrics = html.unescape(lyrics)
            
            rating = None
            rating_count = None
            agg_rating = data.get('aggregateRating', {})
            if agg_rating:
                try:
                    rating = float(agg_rating.get('ratingValue'))
                except:
                    pass
                try:
                    rating_count = int(agg_rating.get('ratingCount'))
                except:
                    pass
                     
            source_id = url.split('/')[-1]
            return {
                'source_id': source_id,
                'title': title,
                'artist': artist,
                'lyrics': lyrics,
                'chords': lyrics,
                'source': 'ultimateguitar',
                'url': url,
                'instrument': 'Chords',
                'rating': rating,
                'rating_count': rating_count,
            }
        except Exception as e:
            print(f"Error parsing JSON fallback: {e}")
            
    return None

def load_existing_songs():
    if os.path.exists(output_file):
        try:
            with open(output_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception as e:
            print(f"Error reading {output_file}: {e}")
    return []

def compress_output():
    print(f"Compressing {output_file} to {compressed_file}...")
    try:
        with open(output_file, 'rb') as f_in:
            with gzip.open(compressed_file, 'wb') as f_out:
                shutil.copyfileobj(f_in, f_out)
        print("Compression successful!")
    except Exception as e:
        print(f"Compression failed: {e}")

def main():
    existing_songs = load_existing_songs()
    print(f"Loaded {len(existing_songs)} existing songs.")
    
    existing_urls = { s['url'].lower() for s in existing_songs if s.get('url') }
    
    total_added = 0
    
    for artist_idx, artist in enumerate(artists):
        print(f"\n[{artist_idx + 1}/{len(artists)}] Fetching songs for: {artist}")
        
        # Search for songs
        songs = search_artist_songs(artist)
        if not songs:
            print(f"  No songs found for {artist}")
            time.sleep(random.uniform(1.0, 2.5))
            continue
            
        print(f"  Found {len(songs)} unique candidates. Selecting top 8...")
        top_songs = songs[:8]
        
        for s in top_songs:
            tab_url = s.get('tab_url')
            s_title = s.get('song_name')
            s_artist = s.get('artist_name')
            
            if tab_url.lower() in existing_urls:
                # Already exists, skip
                continue
                
            print(f"    Scraping: {s_artist} - {s_title} ({tab_url})")
            
            # Politely sleep
            time.sleep(random.uniform(2.0, 4.0))
            
            html_content = fetch_page(tab_url)
            if not html_content:
                html_content = fetch_page_chrome_fallback(tab_url)
                if not html_content:
                    print(f"      Failed to download tab detail page: {tab_url}")
                    continue
                    
            song_data = parse_song_detail(html_content, tab_url)
            if not song_data:
                print(f"      Failed to parse tab details: {tab_url}")
                continue
                
            # Fill details from search results if missing
            if not song_data.get('rating') and s.get('rating'):
                song_data['rating'] = s.get('rating')
            if not song_data.get('rating_count') and s.get('votes'):
                song_data['rating_count'] = s.get('votes')
                
            existing_songs.append(song_data)
            existing_urls.add(tab_url.lower())
            
            # Save incrementally after every successful fetch
            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump(existing_songs, f, indent=2, ensure_ascii=False)
                
            print(f"      Added successfully! Total songs: {len(existing_songs)}")
            total_added += 1
            
        time.sleep(random.uniform(1.5, 3.0))
        
    print(f"\nScraping complete! Added {total_added} songs. Total collection size: {len(existing_songs)}")
    compress_output()

if __name__ == '__main__':
    main()
