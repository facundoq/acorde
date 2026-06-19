import json
import os
import time
import random
import gzip
import shutil
import html
import re
from curl_cffi import requests as cffi_requests
from html.parser import HTMLParser

default_songs_path = "/home/facundoq/dev/acorde/assets/default_songs.json"
compressed_path = "/home/facundoq/dev/acorde/src/assets/default_songs.json.gz"

class LaCuerdaParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.in_tbody = False
        self.tbody_text = []
        self.div_depth = 0

    def handle_starttag(self, tag, attrs):
        attrs_dict = dict(attrs)
        if self.in_tbody:
            if tag == 'div':
                self.div_depth += 1
        elif tag == 'div' and attrs_dict.get('id') == 't_body':
            self.in_tbody = True
            self.div_depth = 1

    def handle_endtag(self, tag):
        if self.in_tbody:
            if tag == 'div':
                self.div_depth -= 1
                if self.div_depth == 0:
                    self.in_tbody = False

    def handle_data(self, data):
        if self.in_tbody:
            self.tbody_text.append(data)

def translate_spanish_chord(chord):
    if not chord:
        return chord
    note_map = {
        'SOL': 'G',
        'LA': 'A',
        'SI': 'B',
        'DO': 'C',
        'RE': 'D',
        'MI': 'E',
        'FA': 'F',
    }
    for entry_key, entry_val in note_map.items():
        if chord.upper().startswith(entry_key):
            suffix = chord[len(entry_key):]
            return entry_val + suffix
    return chord

def clean_chords_translation(html_content):
    def translate_tag(match):
        chord_text = match.group(2).strip()
        translated = translate_spanish_chord(chord_text)
        return f"<{match.group(1)}>{translated}</{match.group(3)}>"
    processed_html = re.sub(r'<([aA])[^>]*>([\s\S]*?)</([aA])>', translate_tag, html_content)
    return processed_html

def test_url(url):
    try:
        res = cffi_requests.get(url, impersonate="chrome124", timeout=8)
        if res.status_code == 200:
            return res.text
    except Exception as e:
        print(f"    Error testing {url}: {e}")
    return None

def resolve_and_fix_urls():
    if not os.path.exists(default_songs_path):
        print(f"Error: {default_songs_path} does not exist.")
        return

    with open(default_songs_path, 'r', encoding='utf-8') as f:
        songs = json.load(f)

    lacuerda_songs = [s for s in songs if s.get('source') == 'lacuerda']
    print(f"Total songs in database: {len(songs)}")
    print(f"LaCuerda songs to verify: {len(lacuerda_songs)}")

    fixed_count = 0
    errors_count = 0

    for idx, s in enumerate(lacuerda_songs):
        title = s.get('title')
        artist = s.get('artist')
        url = s.get('url')

        # First check if url returns 200
        time.sleep(random.uniform(0.1, 0.4))
        res_text = test_url(url)
        
        if res_text:
            # URL is valid, no need to fix
            continue

        print(f"\n[{idx+1}/{len(lacuerda_songs)}] 404 URL DETECTED: {artist} - {title} ({url})")

        # Parse current URL parts
        match_parts = re.match(r'https?://acordes\.lacuerda\.net/([^/]+)/([^/]+)', url)
        if not match_parts:
            print("  -> Could not parse URL segments.")
            continue

        artist_slug = match_parts.group(1)
        song_slug = match_parts.group(2)

        # Generate candidates for artist slug
        candidates = []
        
        # 1. Hyphens to underscores
        candidates.append(artist_slug.replace('-', '_'))
        
        # 2. Underscores to hyphens
        candidates.append(artist_slug.replace('_', '-'))

        # 3. Strip prefixes
        for prefix in ['los-', 'las-', 'el-', 'la-', 'los_', 'las_', 'el_', 'la_']:
            if artist_slug.lower().startswith(prefix):
                stripped = artist_slug[len(prefix):]
                candidates.append(stripped)
                candidates.append(stripped.replace('-', '_'))
                candidates.append(stripped.replace('_', '-'))

        # Remove duplicates
        candidates = list(set(candidates))
        if artist_slug in candidates:
            candidates.remove(artist_slug)

        resolved_url = None
        resolved_html = None

        for cand in candidates:
            test_candidate_url = f"https://acordes.lacuerda.net/{cand}/{song_slug}"
            print(f"  Trying candidate: {test_candidate_url}")
            time.sleep(random.uniform(0.3, 0.7))
            html_text = test_url(test_candidate_url)
            if html_text:
                resolved_url = test_candidate_url
                resolved_html = html_text
                print(f"  -> SUCCESS! Resolved to: {resolved_url}")
                break

        if resolved_url and resolved_html:
            # Parse chords
            resolved_html = clean_chords_translation(resolved_html)
            parser = LaCuerdaParser()
            parser.feed(resolved_html)
            live_chords = "".join(parser.tbody_text).strip()
            live_chords = html.unescape(live_chords)

            if live_chords:
                s['url'] = resolved_url
                s['chords'] = live_chords
                s['lyrics'] = live_chords
                fixed_count += 1
                print(f"  -> Updated URL and chords (length: {len(live_chords)})")

                # Save incrementally
                if fixed_count % 5 == 0:
                    with open(default_songs_path, 'w', encoding='utf-8') as f_out:
                        json.dump(songs, f_out, indent=2, ensure_ascii=False)
                    print("  Saved progress incrementally.")
            else:
                print("  -> Resolved URL but failed to parse chords.")
                errors_count += 1
        else:
            print("  -> Could not resolve URL.")
            errors_count += 1

    # Final save
    with open(default_songs_path, 'w', encoding='utf-8') as f_out:
        json.dump(songs, f_out, indent=2, ensure_ascii=False)
    print(f"\nURL Resolution complete! Fixed: {fixed_count}, Unresolved: {errors_count}")

    # Compress the updated default_songs.json
    print(f"Compressing {default_songs_path} to {compressed_path}...")
    try:
        with open(default_songs_path, 'rb') as f_in:
            with gzip.open(compressed_path, 'wb') as f_out:
                shutil.copyfileobj(f_in, f_out)
        print("Compression completed successfully!")
    except Exception as e:
        print(f"Compression failed: {e}")

if __name__ == '__main__':
    resolve_and_fix_urls()
