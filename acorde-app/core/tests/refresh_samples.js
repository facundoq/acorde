const fs = require('fs');
const path = require('path');
const axios = require('axios');

/**
 * Utility to refresh HTML samples for unit tests.
 * usage: node refresh_samples.js [type: song|search] [provider: ug|lacuerda] [url_or_query] [filename]
 */

const USER_AGENT = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36';

async function fetchWithProxy(url) {
  const proxies = [
    (u) => `https://api.codetabs.com/v1/proxy?quest=${encodeURIComponent(u)}`,
    (u) => `https://api.allorigins.win/raw?url=${encodeURIComponent(u)}`,
    (u) => u // direct as last resort
  ];

  for (const proxy of proxies) {
    try {
      const target = proxy(url);
      console.log(`Fetching: ${target}`);
      const response = await axios.get(target, { 
        headers: { 'User-Agent': USER_AGENT },
        timeout: 10000 
      });
      if (response.data && response.data.length > 1000) {
        return response.data;
      }
    } catch (e) {
      console.warn(`Proxy failed: ${e.message}`);
    }
  }
  throw new Error(`Failed to fetch ${url} with all proxies`);
}

async function refresh() {
  const [type, provider, input, filename] = process.argv.slice(2);
  if (!type || !provider || !input || !filename) {
    console.log('Usage: node refresh_samples.js [song|search] [ug|lacuerda] [url_or_query] [filename]');
    process.exit(1);
  }

  let url = input;
  if (type === 'search') {
    if (provider === 'ug') {
      url = `https://www.ultimate-guitar.com/search.php?search_type=title&value=${encodeURIComponent(input)}`;
    } else {
      url = `https://acordes.lacuerda.net/busca.php?exp=${encodeURIComponent(input)}`;
    }
  }

  try {
    const html = await fetchWithProxy(url);
    const destDir = path.join(__dirname, 'samples', type, provider);
    if (!fs.existsSync(destDir)) fs.mkdirSync(destDir, { recursive: true });
    
    const destPath = path.join(destDir, filename.endsWith('.html') ? filename : `${filename}.html`);
    fs.writeFileSync(destPath, html);
    console.log(`Successfully refreshed ${destPath}`);
  } catch (e) {
    console.error(`Error refreshing sample: ${e.message}`);
    process.exit(1);
  }
}

refresh();
