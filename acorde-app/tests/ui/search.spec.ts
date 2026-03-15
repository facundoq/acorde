import { test, expect } from '@playwright/test';

test.describe('Search Functionality', () => {
  test.beforeEach(async ({ page }) => {
    // Log console messages from the browser
    page.on('console', msg => console.log(`BROWSER CONSOLE [${msg.type()}]: ${msg.text()}`));
    page.on('pageerror', err => console.log(`BROWSER ERROR: ${err.message}`));
    
    // We expect the app to be running on 8080 (static preview)
    await page.goto('http://localhost:8080/search');
  });

  test('should find results for "tempo"', async ({ page }) => {
    const searchInput = page.locator('input[placeholder="Search for song or artist..."]');
    await searchInput.fill('tempo');
    await searchInput.press('Enter');

    // Wait for the results to load
    const results = page.locator('text=Save');
    await expect(results.first()).toBeVisible({ timeout: 15000 });
    
    const count = await results.count();
    expect(count).toBeGreaterThan(0);
  });

  test('should save a song to Tabs', async ({ page }) => {
    const searchInput = page.locator('input[placeholder="Search for song or artist..."]');
    await searchInput.fill('tempo perdido');
    await searchInput.press('Enter');

    // Wait for the first save button and click it
    const firstSaveButton = page.locator('text=Save').first();
    await expect(firstSaveButton).toBeVisible({ timeout: 15000 });
    
    // In many web environments, window.alert needs to be handled
    page.on('dialog', async dialog => {
      expect(dialog.message()).toContain('Saved');
      await dialog.accept();
    });

    await firstSaveButton.click();
  });
});
