import { fetch as nativeFetch } from 'react-native-fetch-api';

export const crossFetch = async (url: string, options: any) => {
  return await nativeFetch(url, options);
};
