import { test, expect } from '@playwright/test';

test.describe('Loading Screen', () => {
  test('should load the app and transition from loading screen to main screen', async ({ page }) => {
    // Log console messages from the browser
    page.on('console', msg => console.log(`BROWSER CONSOLE [${msg.type()}]: ${msg.text()}`));
    page.on('pageerror', err => console.log(`BROWSER ERROR: ${err.message}`));

    await page.goto('http://localhost:8080');

    // 1. Check if loading screen is visible
    const loadingText = page.locator('text=Acorde');
    await expect(loadingText).toBeVisible();
    
    const initText = page.locator('text=Initializing your vault...');
    await expect(initText).toBeVisible();

    // 2. Wait for transition to main screen (Tabs title should appear)
    // We give it more time if something is slow
    const searchInput = page.locator('input[placeholder="Search your Tabs..."]');
    await expect(searchInput).toBeVisible({ timeout: 20000 });

    // 3. Confirm loading screen is gone
    await expect(initText).not.toBeVisible();
  });
});
