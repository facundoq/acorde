const SETTINGS_KEY = 'acorde_font_size';
const DEFAULT_FONT_SIZE = 14;

export async function initSettings() {
  // No initialization needed for localStorage on web
  return;
}

export async function getFontSize(): Promise<number> {
  if (typeof window === 'undefined') return DEFAULT_FONT_SIZE;
  const saved = localStorage.getItem(SETTINGS_KEY);
  return saved ? parseInt(saved, 10) : DEFAULT_FONT_SIZE;
}

export async function saveFontSize(size: number): Promise<void> {
  if (typeof window === 'undefined') return;
  localStorage.setItem(SETTINGS_KEY, size.toString());
}
