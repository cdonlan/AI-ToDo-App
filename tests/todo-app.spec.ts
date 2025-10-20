import { test, expect } from '@playwright/test';

test.describe('AI-ToDo-App', () => {
  test('should add a new todo item successfully', async ({ page }) => {
    // Navigate to the app
    await page.goto('https://cdonlan.github.io/AI-ToDo-App/');

    // Fill in the Title field
    await page.fill('input[placeholder="Title"]', 'Test Todo');

    // Click the Priority dropdown
    await page.click('text=Priority');

    // Select the "Medium" option
    await page.selectOption('select', { label: 'Medium' });

    // Ensure the Due Date field is visible
    await page.waitForSelector('input[type="date"]', { state: 'visible' });
    await page.fill('input[type="date"]', '2025-09-10');

    // Fill in the Description field
    await page.fill('textarea[placeholder="Description"]', 'This is a test todo item.');

    // Click the Add Todo button
    await page.click('button:has-text("Add Todo")');

    // Verify the new todo item is added to the list
    const todoItem = await page.locator('li:has-text("Test Todo")');
    await expect(todoItem).toBeVisible();
    await expect(todoItem).toContainText('Medium');
    await expect(todoItem).toContainText('2025-09-10');
    await expect(todoItem).toContainText('This is a test todo item.');
  });
});
