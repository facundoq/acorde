// This file exists to satisfy TypeScript and tools that don't support platform-specific extensions.
// In actual execution (Expo/React Native), fetcher.web.ts or fetcher.native.ts will be used.

export const crossFetch = async (url: string, options: any = {}): Promise<Response> => {
  return fetch(url, options);
};

export async function fetchHtml(url: string): Promise<string> {
  const response = await crossFetch(url);
  return response.text();
}
