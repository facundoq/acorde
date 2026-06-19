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
    # We want to translate Spanish chords (SOL, LA, SI, etc.) to English notation
    # In LaCuerda, chords are inside <a> tags within t_body, e.g. <a>SOL</a>
    # We can parse the DOM or just do regex translation inside <a>...</a> tags.
    # Let's use a regex to translate the contents of all <A>...</A> or <a>...</a> tags in the raw text
    def translate_tag(match):
        chord_text = match.group(2).strip()
        translated = translate_spanish_chord(chord_text)
        return f"<{match.group(1)}>{translated}</{match.group(3)}>"

    # Temporarily translate <a> tags
    processed_html = re.sub(r'<([aA])[^>]*>([\s\S]*?)</([aA])>', translate_tag, html_content)
    return processed_html

def recrawl_songs():
    if not os.path.exists(default_songs_path):
        print(f"Error: {default_songs_path} does not exist.")
        return

    with open(default_songs_path, 'r', encoding='utf-8') as f:
        songs = json.load(f)

    lacuerda_songs = [s for s in songs if s.get('source') == 'lacuerda']
    print(f"Total songs in database: {len(songs)}")
    print(f"LaCuerda songs to verify: {len(lacuerda_songs)}")

    updated_count = 0
    errors_count = 0

    for idx, s in enumerate(lacuerda_songs):
        title = s.get('title')
        artist = s.get('artist')
        url = s.get('url')
        stored_chords = s.get('chords', '').strip()

        print(f"[{idx+1}/{len(lacuerda_songs)}] Processing: {artist} - {title} ({url})")

        # Sleep to be polite and avoid rate limits
        time.sleep(random.uniform(0.5, 1.2))

        try:
            res = cffi_requests.get(url, impersonate="chrome124", timeout=12)
            if res.status_code != 200:
                print(f"  -> Error: HTTP status {res.status_code}")
                errors_count += 1
                continue

            html_content = res.text
            # Translate chords inside <a> tags before stripping HTML
            html_content = clean_chords_translation(html_content)

            parser = LaCuerdaParser()
            parser.feed(html_content)
            live_chords = "".join(parser.tbody_text).strip()
            live_chords = html.unescape(live_chords)

            if not live_chords:
                print("  -> Warning: Parsed chords empty.")
                errors_count += 1
                continue

            # Compare lengths
            diff = len(live_chords) - len(stored_chords)
            if diff > 50 or (len(stored_chords) < 600 and diff > 10):
                # Update the song in the list
                s['chords'] = live_chords
                s['lyrics'] = live_chords
                updated_count += 1
                print(f"  -> UPDATED! Stored length: {len(stored_chords)} vs Live length: {len(live_chords)} (diff: {diff})")

                # Save incrementally every 10 updates
                if updated_count % 10 == 0:
                    with open(default_songs_path, 'w', encoding='utf-8') as f_out:
                        json.dump(songs, f_out, indent=2, ensure_ascii=False)
                    print("  Saved progress incrementally.")

            else:
                print(f"  -> OK (stored len: {len(stored_chords)}, live len: {len(live_chords)})")

        except Exception as e:
            print(f"  -> Exception: {e}")
            errors_count += 1

    # Final save
    with open(default_songs_path, 'w', encoding='utf-8') as f_out:
        json.dump(songs, f_out, indent=2, ensure_ascii=False)
    print(f"\nRecrawl complete! Updated {updated_count} songs. Errors: {errors_count}")

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
    recrawl_songs()
