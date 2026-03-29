import * as SQLite from 'expo-sqlite';

const SETTINGS_KEY = 'acorde_font_size';
const DEFAULT_FONT_SIZE = 14;

// For Native, we use a simple settings table in SQLite
const getDb = async () => {
  return await SQLite.openDatabaseAsync('settings.db');
};

export async function initSettings() {
  const db = await getDb();
  await db.execAsync(`
    CREATE TABLE IF NOT EXISTS settings (
      key TEXT PRIMARY KEY,
      value TEXT
    );
  `);
}

export async function getFontSize(): Promise<number> {
  try {
    const db = await getDb();
    const result = await db.getFirstAsync<{ value: string }>(
      'SELECT value FROM settings WHERE key = ?',
      [SETTINGS_KEY]
    );
    return result ? parseInt(result.value, 10) : DEFAULT_FONT_SIZE;
  } catch (e) {
    return DEFAULT_FONT_SIZE;
  }
}

export async function saveFontSize(size: number): Promise<void> {
  try {
    const db = await getDb();
    await db.runAsync(
      'INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)',
      [SETTINGS_KEY, size.toString()]
    );
  } catch (e) {
    console.error('Failed to save font size setting:', e);
  }
}