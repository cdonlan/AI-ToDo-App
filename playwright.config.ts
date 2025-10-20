import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests', // Directory containing test files
  timeout: 30000, // Maximum time one test can run in milliseconds
  retries: 2, // Retry failed tests up to 2 times
  // Run tests in parallel
  fullyParallel: true,
  // Reporter for test results
  reporter: [
    ['html'],
    ['list']
  ],
  use: {
    headless: true, // Run tests in headless mode
    viewport: { width: 1280, height: 720 }, // Default viewport size
    ignoreHTTPSErrors: true, // Ignore HTTPS errors
    video: 'retain-on-failure', // Record video for failed tests
    screenshot: 'only-on-failure', // Take screenshots only on failure
    trace: 'retain-on-failure', // Trace only on failure
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
  ],
});
