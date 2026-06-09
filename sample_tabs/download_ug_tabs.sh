#!/bin/bash
DIR="/home/facundoq/dev/acorde/acorde-app/core/tests/samples/ug"
mkdir -p "$DIR"
cd "$DIR"

USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"

# Array of URL and filename pairs
items=(
"https://tabs.ultimate-guitar.com/tab/the-beatles/let-it-be-chords-17444 the-beatles-let-it-be.html"
"https://tabs.ultimate-guitar.com/tab/the-beatles/yesterday-chords-17445 the-beatles-yesterday.html"
"https://tabs.ultimate-guitar.com/tab/the-beatles/hey-jude-chords-1061739 the-beatles-hey-jude.html"
"https://tabs.ultimate-guitar.com/tab/the-beatles/come-together-chords-1052684 the-beatles-come-together.html"
"https://tabs.ultimate-guitar.com/tab/the-beatles/blackbird-tabs-57261 the-beatles-blackbird.html"
"https://tabs.ultimate-guitar.com/tab/the-rolling-stones/paint-it-black-chords-8560 the-rolling-stones-paint-it-black.html"
"https://tabs.ultimate-guitar.com/tab/the-rolling-stones/angie-chords-57221 the-rolling-stones-angie.html"
"https://tabs.ultimate-guitar.com/tab/the-rolling-stones/satisfaction-tabs-1014 the-rolling-stones-satisfaction.html"
"https://tabs.ultimate-guitar.com/tab/the-rolling-stones/wild-horses-chords-17344 the-rolling-stones-wild-horses.html"
"https://tabs.ultimate-guitar.com/tab/queen/bohemian-rhapsody-chords-1054324 queen-bohemian-rhapsody.html"
"https://tabs.ultimate-guitar.com/tab/queen/love-of-my-life-chords-340088 queen-love-of-my-life.html"
"https://tabs.ultimate-guitar.com/tab/queen/dont-stop-me-now-chords-662791 queen-dont-stop-me-now.html"
"https://tabs.ultimate-guitar.com/tab/led-zeppelin/stairway-to-heaven-tabs-9488 led-zeppelin-stairway-to-heaven.html"
"https://tabs.ultimate-guitar.com/tab/led-zeppelin/whole-lotta-love-tabs-345 led-zeppelin-whole-lotta-love.html"
"https://tabs.ultimate-guitar.com/tab/pink-floyd/wish-you-were-here-chords-44555 pink-floyd-wish-you-were-here.html"
"https://tabs.ultimate-guitar.com/tab/pink-floyd/comfortably-numb-chords-80512 pink-floyd-comfortably-numb.html"
"https://tabs.ultimate-guitar.com/tab/oasis/wonderwall-chords-2759 oasis-wonderwall.html"
"https://tabs.ultimate-guitar.com/tab/oasis/dont-look-back-in-anger-chords-60638 oasis-dont-look-back-in-anger.html"
"https://tabs.ultimate-guitar.com/tab/coldplay/yellow-chords-114080 coldplay-yellow.html"
"https://tabs.ultimate-guitar.com/tab/coldplay/the-scientist-chords-180849 coldplay-the-scientist.html"
"https://tabs.ultimate-guitar.com/tab/radiohead/creep-chords-462 radiohead-creep.html"
"https://tabs.ultimate-guitar.com/tab/radiohead/karma-police-chords-103339 radiohead-karma-police.html"
"https://tabs.ultimate-guitar.com/tab/nirvana/smells-like-teen-spirit-chords-807883 nirvana-smells-like-teen-spirit.html"
"https://tabs.ultimate-guitar.com/tab/nirvana/come-as-you-are-chords-1056518 nirvana-come-as-you-are.html"
"https://tabs.ultimate-guitar.com/tab/eagles/hotel-california-chords-46190 eagles-hotel-california.html"
"https://tabs.ultimate-guitar.com/tab/bob-dylan/knockin-on-heavens-door-chords-66222 bob-dylan-knockin-on-heavens-door.html"
"https://tabs.ultimate-guitar.com/tab/neil-young/heart-of-gold-chords-56608 neil-young-heart-of-gold.html"
"https://tabs.ultimate-guitar.com/tab/john-lennon/imagine-chords-9306 john-lennon-imagine.html"
"https://tabs.ultimate-guitar.com/tab/david-bowie/space-oddity-chords-10586 david-bowie-space-oddity.html"
"https://tabs.ultimate-guitar.com/tab/david-bowie/heroes-chords-10588 david-bowie-heroes.html"
"https://tabs.ultimate-guitar.com/tab/u2/one-chords-17541 u2-one.html"
"https://tabs.ultimate-guitar.com/tab/u2/with-or-without-you-chords-17543 u2-with-or-without-you.html"
"https://tabs.ultimate-guitar.com/tab/dire-straits/sultans-of-swing-chords-10526 dire-straits-sultans-of-swing.html"
"https://tabs.ultimate-guitar.com/tab/eric-clapton/wonderful-tonight-chords-10528 eric-clapton-wonderful-tonight.html"
"https://tabs.ultimate-guitar.com/tab/deep-purple/smoke-on-the-water-tabs-10530 deep-purple-smoke-on-the-water.html"
"https://tabs.ultimate-guitar.com/tab/acdc/highway-to-hell-chords-10532 acdc-highway-to-hell.html"
"https://tabs.ultimate-guitar.com/tab/acdc/back-in-black-tabs-10534 acdc-back-in-black.html"
"https://tabs.ultimate-guitar.com/tab/metallica/nothing-else-matters-chords-10536 metallica-nothing-else-matters.html"
"https://tabs.ultimate-guitar.com/tab/metallica/enter-sandman-tabs-10538 metallica-enter-sandman.html"
"https://tabs.ultimate-guitar.com/tab/guns-n-roses/sweet-child-o-mine-chords-10540 guns-n-roses-sweet-child-o-mine.html"
"https://tabs.ultimate-guitar.com/tab/guns-n-roses/knockin-on-heavens-door-chords-10542 guns-n-roses-knockin-on-heavens-door.html"
)

for item in "${items[@]}"; do
    url=$(echo $item | cut -d' ' -f1)
    filename=$(echo $item | cut -d' ' -f2)
    
    echo "Downloading $url to $filename..."
    
    # Try direct download
    status_code=$(curl -s -L -o "$filename" -w "%{http_code}" -A "$USER_AGENT" "$url")
    
    if [ "$status_code" -ne 200 ]; then
        echo "Direct download failed with status $status_code. Trying proxy 1..."
        encoded_url=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$url'))")
        status_code=$(curl -s -L -o "$filename" -w "%{http_code}" -A "$USER_AGENT" "https://api.allorigins.win/raw?url=$encoded_url")
        
        if [ "$status_code" -ne 200 ]; then
            echo "Proxy 1 failed with status $status_code. Trying proxy 2..."
            status_code=$(curl -s -L -o "$filename" -w "%{http_code}" -A "$USER_AGENT" "https://api.codetabs.com/v1/proxy?quest=$url")
            
            if [ "$status_code" -ne 200 ]; then
                echo "Proxy 2 failed with status $status_code."
            fi
        fi
    fi
    
    sleep 3
done

echo "Finished. Total files downloaded: $(ls -1 | wc -l)"
