import os
import sys
import csv
import json
import re
import random
import time
import urllib.parse
import html
import subprocess
from curl_cffi import requests as cffi_requests

output_file = "/home/facundoq/dev/acorde/src/assets/default_songs.json"
rock_url = "https://raw.githubusercontent.com/fivethirtyeight/data/master/classic-rock/classic-rock-song-list.csv"
jazz_url = "https://raw.githubusercontent.com/mikeoliphant/JazzStandards/master/JazzStandards.json"

def get_target_songs():
    print("Fetching rock and jazz song lists...")
    # Fetch rock list
    rock_songs = []
    try:
        res = cffi_requests.get(rock_url, impersonate="chrome124", timeout=15)
        reader = csv.DictReader(res.text.strip().split("\n"))
        for row in reader:
            title = row.get("Song Clean", "").strip()
            artist = row.get("ARTIST CLEAN", "").strip()
            play_count = 0
            try:
                play_count = int(row.get("PlayCount", 0))
            except:
                pass
            if title and artist:
                rock_songs.append({"title": title, "artist": artist, "play_count": play_count, "genre": "Rock"})
    except Exception as e:
        print(f"Error fetching rock list: {e}")

    # Sort rock songs by play count popularity
    rock_songs.sort(key=lambda x: x["play_count"], reverse=True)

    # Fetch jazz list
    jazz_songs = []
    try:
        res = cffi_requests.get(jazz_url, impersonate="chrome124", timeout=15)
        data = res.json()
        for item in data:
            title = item.get("Title", "").strip()
            composer = item.get("Composer", "").strip()
            if title:
                # Use Composer as artist if available, else "Jazz Standard"
                artist = composer if composer else "Jazz Standard"
                jazz_songs.append({"title": title, "artist": artist, "genre": "Jazz"})
    except Exception as e:
        print(f"Error fetching jazz list: {e}")

    # Combine lists to get 3000 unique songs
    seen = set()
    combined_songs = []

    # Let's take up to 1300 jazz songs
    for s in jazz_songs[:1300]:
        key = (s["title"].lower(), s["artist"].lower())
        if key not in seen:
            seen.add(key)
            combined_songs.append(s)

    # Let's fill the rest with rock songs to reach 3000
    for s in rock_songs:
        if len(combined_songs) >= 3000:
            break
        key = (s["title"].lower(), s["artist"].lower())
        if key not in seen:
            seen.add(key)
            combined_songs.append(s)

    print(f"Total compiled target songs: {len(combined_songs)}")
    return combined_songs

def fetch_page_chrome(url):
    """Try to fetch the page using headless chrome command line."""
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
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
        if res.returncode == 0 and "js-store" in res.stdout:
            return res.stdout
    except Exception as e:
        print(f"Headless Chrome error: {e}")
    return None

def fetch_page(url):
    """Fetch using curl_cffi directly (impersonating Chrome to bypass Turnstile)."""
    try:
        res = cffi_requests.get(url, impersonate="chrome124", timeout=12)
        if res.status_code == 200:
            return res.text, "curl_cffi"
    except Exception as e:
        print(f"curl_cffi fetch error: {e}")
    return None, None

def search_ug_chords(title, artist):
    query = f"{artist} {title}"
    encoded = urllib.parse.quote(query)
    search_url = f"https://www.ultimate-guitar.com/search.php?search_type=title&value={encoded}"
    
    html_content, source = fetch_page(search_url)
    if not html_content:
        return None

    # Parse search results
    match = re.search(r'data-content="([^"]+)"', html_content)
    if match:
        try:
            decoded_json = html.unescape(match.group(1))
            data = json.loads(decoded_json)
            results = data.get('store', {}).get('page', {}).get('data', {}).get('results', [])
            
            # Filter for Chords types
            chord_results = [r for r in results if r.get('type') == 'Chords']
            if not chord_results:
                # Fallback to any type if Chords not found
                chord_results = [r for r in results if r.get('tab_url')]
            
            if chord_results:
                # Sort by votes desc, then rating desc
                chord_results.sort(key=lambda x: (x.get('votes') or 0, x.get('rating') or 0.0), reverse=True)
                return chord_results[0]
        except Exception as e:
            print(f"Error parsing search JSON for {query}: {e}")
            
    return None

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

def main():
    existing_songs = load_existing_songs()
    print(f"Already have {len(existing_songs)} saved songs.")
    
    # Save a set of existing titles to skip duplicates
    existing_keys = { (s["title"].lower(), s["artist"].lower()) for s in existing_songs }
    
    target_songs = get_target_songs()
    
    songs_to_scrape = [s for s in target_songs if (s["title"].lower(), s["artist"].lower()) not in existing_keys]
    print(f"Pending to scrape: {len(songs_to_scrape)}")
    
    success_count = 0
    
    for idx, s in enumerate(songs_to_scrape):
        title = s["title"]
        artist = s["artist"]
        print(f"\n[{idx+1}/{len(songs_to_scrape)}] Processing: {artist} - {title}")
        
        try:
            # 1. Search song
            search_result = search_ug_chords(title, artist)
            if not search_result:
                print(f"No search results for {artist} - {title}")
                # Short sleep to be polite
                time.sleep(random.uniform(1.0, 2.5))
                continue
                
            tab_url = search_result.get("tab_url")
            if not tab_url:
                print(f"No tab URL found for {artist} - {title}")
                time.sleep(random.uniform(1.0, 2.5))
                continue
                
            print(f"Found best tab URL: {tab_url}")
            
            # Sleep before downloading tab detail
            sleep_time = random.uniform(2.0, 5.0)
            print(f"Sleeping for {sleep_time:.2f}s...")
            time.sleep(sleep_time)
            
            # 2. Download page
            html_content, fetch_method = fetch_page(tab_url)
            if not html_content:
                print(f"Failed to fetch page: {tab_url}")
                continue
                
            # 3. Parse song page
            song_data = parse_song_detail(html_content, tab_url)
            if not song_data:
                print(f"Failed to parse song page: {tab_url}")
                continue
                
            # Add play/votes info if not fetched
            if not song_data.get("rating_count") and search_result.get("votes"):
                song_data["rating_count"] = search_result.get("votes")
            if not song_data.get("rating") and search_result.get("rating"):
                song_data["rating"] = search_result.get("rating")
                
            # Double check chords field
            if not song_data.get("chords"):
                song_data["chords"] = song_data["lyrics"]
                
            # Save incrementally
            existing_songs.append(song_data)
            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump(existing_songs, f, indent=2, ensure_ascii=False)
                
            print(f"Successfully added: {song_data['artist']} - {song_data['title']} (Fetch method: {fetch_method})")
            success_count += 1
            
            # If we successfully retrieved 3000 songs, break
            if len(existing_songs) >= 3041: # 41 original + 3000 new
                print("Reached target database size of 3041 songs!")
                break
                
        except Exception as e:
            print(f"Error processing {artist} - {title}: {e}")
            
        # Sleep after processing
        time.sleep(random.uniform(2.0, 5.0))

    print(f"\nExecution finished! Added {success_count} songs. Total database count is now {len(existing_songs)}.")

if __name__ == "__main__":
    main()
