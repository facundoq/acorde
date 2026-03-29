export const crossFetch = async (url: string, options: any = {}) => {
  return await fetch(url, options);
};

export async function fetchHtml(url: string): Promise<string> {
  const userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36';
  const MAX_RETRIES = 1;

  const tryFetch = async (targetUrl: string, sendHeaders: boolean = true): Promise<string | null> => {
    for (let i = 0; i <= MAX_RETRIES; i++) {
      try {
        const options: any = {};
        if (sendHeaders) {
          options.headers = { 'User-Agent': userAgent };
        }

        const response = await crossFetch(targetUrl, options);
        if (response.ok) return await response.text();
        if (response.status === 403 || response.status === 429) return null; 
      } catch (e) {}
      if (i < MAX_RETRIES) await new Promise(r => setTimeout(r, 300));
    }
    return null;
  };

  const proxies = [
    { url: (u: string) => `https://cors-anywhere.herokuapp.com/${u}`, headers: true },
    { url: (u: string) => `https://corsproxy.io/?${encodeURIComponent(u)}`, headers: false },
    { url: (u: string) => `https://api.allorigins.win/raw?url=${encodeURIComponent(u)}`, headers: false },
    { url: (u: string) => `https://thingproxy.freeboard.io/fetch/${u}`, headers: true },
    { url: (u: string) => `https://api.codetabs.com/v1/proxy?quest=${encodeURIComponent(u)}`, headers: false },
  ];

  for (const proxy of proxies) {
    const result = await tryFetch(proxy.url(url), proxy.headers);
    if (result) return result;
    await new Promise(r => setTimeout(r, 200));
  }

  throw new Error(`Connection error. This site is currently resisting our access. Please try again in a few seconds or use the Android app for direct access.`);
}
