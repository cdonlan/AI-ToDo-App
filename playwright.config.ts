import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './tests', // Directory containing test files
  timeout: 30000, // Maximum time one test can run in milliseconds
  retries: 2, // Retry failed tests up to 2 times
  use: {
    headless: true, // Run tests in headless mode
    viewport: { width: 1280, height: 720 }, // Default viewport size
    ignoreHTTPSErrors: true, // Ignore HTTPS errors
    video: 'retain-on-failure', // Record video for failed tests
    screenshot: 'only-on-failure', // Take screenshots only on failure
  },
  projects: [
    {
      name: 'Chromium',
      use: { browserName: 'chromium' },
    },
    {
      name: 'Firefox',
      use: { browserName: 'firefox' },
    },
    {
      name: 'WebKit',
      use: { browserName: 'webkit' },
    },
  ],
});
